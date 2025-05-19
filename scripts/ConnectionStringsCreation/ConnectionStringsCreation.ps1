[CmdletBinding()]
param()

. "$PSScriptRoot\PowerAppsAdminUtilities.ps1"
Import-Module "$PSScriptRoot\ps_modules\VstsTaskSdk\VstsTaskSdk.psm1"

Trace-EnteringInvocation $MyInvocation

# Get inputs for the task
$authenticationType = Get-Input -Name authenticationType -Require
$connectedServiceName = Get-Input -Name $authenticationType -Require

$xrmFrameworkConfigPath = Get-Input -Name XrmFrameworkConfigPath -Require
$connectionStringsConfigPath = Get-Input -Name ConnectionStringsConfigPath -Require

$endpoint = Get-Endpoint -Name $connectedServiceName -Require

$connectionString = Get-ConnectionString -Endpoint $endpoint -AuthenticationType $authenticationType

[xml]$xmlElm = Get-Content -Path $xrmFrameworkConfigPath
$selectedConnection = $xmlElm.xrmFramework.selectedConnection

Write-Verbose "Selected connection string : $($selectedConnection)"
Write-Verbose "Creating file on path $($connectionStringsConfigPath)"

$connectionStringsFileContent = '<connectionStrings><add name="' + $selectedConnection + '" connectionString="' + $connectionString + '" /></connectionStrings>'

Write-Verbose "Connection Strings file to be created : $($connectionStringsFileContent)"

$connectionStringsFileContent | Out-File -FilePath $connectionStringsConfigPath