# Starter pipeline
# Start with a minimal pipeline that you can customize to build and deploy your code.
# Add steps that build, run tests, deploy, and more:
# https://aka.ms/yaml

name: $(BuildDefinitionName)-$(Date:yyyyMMdd).$(Rev:.r)

trigger:
- $(Build.SourceBranchName)

pool:
  vmImage: 'vs2017-win2016'

steps:
- script: md tools
  displayName: 'Create tools directory'

- powershell: |
    Invoke-WebRequest `
      -Uri https://dist.nuget.org/win-x86-commandline/latest/nuget.exe `
      -OutFile tools\\nuget.exe
  displayName: 'Download nuget.exe'

- powershell: |
    tools\\nuget.exe install Microsoft.CrmSdk.CoreTools -O tools
    md "tools\\CoreTools"
    $coreToolsFolder = Get-ChildItem tools | Where-Object {$_.Name -match 'Microsoft.CrmSdk.CoreTools.'}
    move "tools\\$coreToolsFolder\\content\\bin\\coretools\\*.*" "tools\\CoreTools"
    Remove-Item "tools\\$coreToolsFolder" -Force -Recurse
  displayName: 'Install CoreTools'

- powershell: |
    $files = @(Get-ChildItem $(Build.Repository.LocalPath)\Nitrogen\Backups\Solutions\Raw\*.zip)
    foreach ($file in $files) 
    {
        Start-Process tools/CoreTools/SolutionPackager.exe `
        -ArgumentList `
          "/action: Extract", `
          "/zipfile: $file", `
          "/folder: $(Build.Repository.LocalPath)\Nitrogen\Backups\Solutions\Extracted", `
          "/allowDelete:No" `
        -Wait `
        -NoNewWindow
    }
  displayName: 'Solution Packager: pack solution'

#- powershell: |
#    Start-Process tools/CoreTools/SolutionPackager.exe `
#    -ArgumentList `
#      "/action: Extract", `
#      "/zipfile: $(Build.Repository.LocalPath)\Nitrogen\Backups\Solutions\Raw\LenovoNitrogenConfiguration_1_0_0_0.zip", `
#      "/folder: $(Build.Repository.LocalPath)\Nitrogen\Backups\Solutions\Extracted", `
#      "/allowDelete:No" `
#    -Wait `
#    -NoNewWindow
#  env:
#    SolutionPath: $(solution.path)
#    SolutionName: $(solution.name)
#  displayName: 'Solution Packager: pack solution'

- script: if exist tools rd /s /q tools
  displayName: 'Delete tools folder exists'

- powershell: |
    git config --global user.email "virajan@microsoft.com"
    git config --global user.name "Vikas Rajan"
    git checkout $(Build.SourceBranchName)
    git add -A
    git status
    git commit -m "Solution Extraction Automation"
    git -c http.extraheader="AUTHORIZATION: bearer $(System.AccessToken)" push
  displayName: 'Commit changes'
