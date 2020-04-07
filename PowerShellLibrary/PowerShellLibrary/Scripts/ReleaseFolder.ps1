# Starter pipeline
# Start with a minimal pipeline that you can customize to build and deploy your code.
# Add steps that build, run tests, deploy, and more:
# https://aka.ms/yaml

parameters:
  - name: releasefolder
    displayName: Release Folder
    type: string

trigger: none

name: ${{parameters.releasefolder}}-$(date:yyyyMMdd)$(rev:.r)

stages:
- stage: Build
  jobs:
  - job: PackContents
    displayName: Release Folder
    pool:
      vmImage: 'ubuntu-latest'

    steps:
    - task: PowerShell@2
      displayName: Validate Release Folder
      inputs:
        targetType: 'inline'
        script: |
          if ( -not (Test-Path -Path '$(Build.SourcesDirectory)/Nitrogen/Releases/${{parameters.releasefolder}}/Deployment' -PathType Container))
          {
            Write-Host "The specified release folder (/Nitrogen/Releases/${{parameters.releasefolder}}/Deployment) is not a directory. Please verify"
            exit 1
          }
          else 
          {
            Write-Host "The specified release folder (/Nitrogen/Releases/${{parameters.releasefolder}}/Deployment) is valid. Proceeding with the deployment."
          }
    - task: CopyFiles@2
      displayName: Copy Automation Utility Files
      inputs:
        SourceFolder: '$(Build.SourcesDirectory)/Nitrogen/Deployment Automation'
        Contents: '**'
        TargetFolder: '$(Build.ArtifactStagingDirectory)'
    - task: CopyFiles@2
      displayName: Copy Deploymnet Files
      inputs:
        SourceFolder: '$(Build.SourcesDirectory)/Nitrogen/Releases/${{parameters.releasefolder}}/Deployment'
        Contents: '**'
        TargetFolder: '$(Build.ArtifactStagingDirectory)'
    - task: PublishBuildArtifacts@1
      inputs:
        pathtoPublish: '$(Build.ArtifactStagingDirectory)'
        artifactName: drop

      

