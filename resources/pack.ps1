cd 'C:\Program Files (x86)\UiPath\Studio'
START UiRobot.exe -ArgumentList @("pack", "$env:WORKSPACE\project.json", "--output", "$env:JENKINS_HOME\jobs\$env:JOB_NAME\builds\$env:BUILD_NUMBER") 