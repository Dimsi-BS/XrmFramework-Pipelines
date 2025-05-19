[CmdletBinding()]
param()

. "$PSScriptRoot\PowerAppsAdminUtilities.ps1"

Trace-VstsEnteringInvocation $MyInvocation

# Get inputs for the task
$authenticationType = Get-VstsInput -Name authenticationType -Require
$connectedServiceName = Get-VstsInput -Name $authenticationType -Require

$endpoint = Get-VstsEndpoint -Name $connectedServiceName -Require

$environment = Get-VstsInput -Name Environment -Require
$buildConfiguration = Get-VstsInput -Name Configuration -Require

$pluginProjectPath = Get-VstsInput -Name PluginProjectPath -Require
$deployProjectPath = Get-VstsInput -Name DeployProjectPath -Require

$solutionName = Get-VstsInput -Name SolutionName -Require


$env


if ($deployProjectPath -ne '') {
    $deployProjectPath = Join-Path $deployProjectPath bin
    $deployProjectPath = Join-Path $deployProjectPath $buildConfiguration

    $exeFile = Get-ChildItem -Path $deployProjectPath -Filter "*.exe" -Recurse

    Write-Host "##[command]$($exeFile.FullName) -NoPrompt -Debug"
    . $exeFile.FullName -NoPrompt -Debug

    if (-not $?) {
        throw (Get-VstsLocString -Key XrmFramework_DeploymentFailed)
    }
} else {
# TODO Gérer le déploiement directement depuis la tâche

}
