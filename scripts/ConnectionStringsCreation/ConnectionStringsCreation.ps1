[CmdletBinding()]
param()

. "$PSScriptRoot\PowerAppsAdminUtilities.ps1"
Import-Module VstsTaskSdk

Trace-VstsEnteringInvocation $MyInvocation

# Get inputs for the task
$authenticationType = Get-VstsInput -Name authenticationType -Require
$connectedServiceName = Get-VstsInput -Name $authenticationType -Require

$xrmFrameworkConfigPath = Get-VstsInput -Name XrmFrameworkConfigPath -Require
$connectionStringsConfigPath = Get-VstsInput -Name ConnectionStringsConfigPath -Require

$endpoint = Get-Endpoint -Name $connectedServiceName -Require

$connectionString = Get-ConnectionString -Endpoint $endpoint -AuthenticationType $authenticationType

[xml]$xmlElm = Get-Content -Path $xrmFrameworkConfigPath
$selectedConnection = $xmlElm.xrmFramework.selectedConnection

Write-Verbose "Selected connection string : $($selectedConnection)"
Write-Verbose "Creating file on path $($connectionStringsConfigPath)"

$connectionStringsFileContent = '<connectionStrings><add name="' + $selectedConnection + '" connectionString="' + $connectionString + '" /></connectionStrings>'

Write-Verbose "Connection Strings file to be created : $($connectionStringsFileContent)"

$connectionStringsFileContent | Out-File -FilePath $connectionStringsConfigPath