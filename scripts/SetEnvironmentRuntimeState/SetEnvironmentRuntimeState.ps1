[CmdletBinding()]
param()

. "$PSScriptRoot\PowerAppsAdminUtilities.ps1"

Trace-VstsEnteringInvocation $MyInvocation

# Get inputs for the task
$authenticationType = Get-VstsInput -Name authenticationType -Require
$connectedServiceName = Get-VstsInput -Name $authenticationType -Require
$environment = Get-VstsInput -Name Environment -Require
$runtimeState = Get-VstsInput -Name runtimeState -Require

$endpoint = Get-VstsEndpoint -Name $connectedServiceName -Require

Initialize-PowerAppsAdminModule -Endpoint $endpoint -AuthenticationType $authenticationType

$environmentId = GetEnvironment($environment)

Write-Host "##[command]Set-AdminPowerAppEnvironmentRuntimeState -EnvironmentName $($environmentId) -RuntimeState $($runtimeState) -TimeoutInMinutes 10 -WaitUntilFinished $true"
Set-AdminPowerAppEnvironmentRuntimeState -EnvironmentName $environmentId -RuntimeState $runtimeState -TimeoutInMinutes 10 -WaitUntilFinished $true
