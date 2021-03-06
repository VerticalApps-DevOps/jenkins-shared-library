$project = Get-Content -Raw -Path $env:WORKSPACE\project.json | ConvertFrom-Json
& "C:\Program Files (x86)\UiPath\Studio\UiRobot.exe" -pack "$env:WORKSPACE\project.json" --output "$env:JENKINS_HOME\jobs\$env:JOB_NAME\builds\$env:BUILD_NUMBER" -v $project.projectVersion

$auth = @{
   tenancyName = $env:tenancy
   usernameOrEmailAddress = $env:user
   password = $env:pwd
}

Write-Output "Beginning UIPath Orchestrator Authentication"
$authjson = $auth | ConvertTo-Json
$authkey = Invoke-RestMethod -SkipCertificateCheck "$env:url/api/Account/Authenticate" -Method Post -Body $authjson -ContentType 'application/json'
$authjson = $authkey | ConvertTo-Json
$token = $authjson | ConvertFrom-Json
Set-Variable -Name "ts" -Value $token.result

$tokenstring = ConvertTo-SecureString $ts -AsPlainText -Force

Write-Output "Beginning UIPath Orchestrator publish"
 
$Directory = "$env:JENKINS_HOME\jobs\$env:JOB_NAME\builds\$env:BUILD_NUMBER\"
$Package = $project.name + "." + $project.projectVersion + ".nupkg"
$FilePath = $Directory + $Package
$FieldName = $Package.Replace(".nupkg","")
$ContentType = 'multipart/form-data'

$FileStream = [System.IO.FileStream]::new($filePath, [System.IO.FileMode]::Open)
$FileHeader = [System.Net.Http.Headers.ContentDispositionHeaderValue]::new('form-data')
$FileHeader.Name = $FieldName
$FileHeader.FileName = Split-Path -leaf $FilePath
$FileContent = [System.Net.Http.StreamContent]::new($FileStream)
$FileContent.Headers.ContentDisposition = $FileHeader
$FileContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse($ContentType)

$MultipartContent = [System.Net.Http.MultipartFormDataContent]::new()
$MultipartContent.Add($FileContent)

Invoke-RestMethod -SkipCertificateCheck -Body $MultipartContent "$env:url/odata/Processes/UiPath.Server.Configuration.OData.UploadPackage" -Method Post -Authentication Bearer -Token ($tokenstring)
Write-Output "The package has been successfully published to Orchestrator and nexus"

Write-Output "Beginning Process Creation"

$release = @{
   Name = $project.name
   EnvironmentId = $env:environmentId
   ProcessKey = $project.name
   ProcessVersion = $project.projectVersion
}

Invoke-RestMethod -SkipCertificateCheck -Body $release "$env:url/odata/Releases" -Method Post -Authentication Bearer -Token ($tokenstring)

Write-Output "Process Successfully Created"