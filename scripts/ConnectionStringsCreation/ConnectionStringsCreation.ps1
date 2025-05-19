[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    $authenticationType,
    [Parameter(Mandatory = $true)]
    $PowerPlatformSPN,
    [Parameter(Mandatory = $false)]
    $XrmFrameworkConfigPath,
    [Parameter(Mandatory = $false)]
    $ConnectionStringsConfigPath    
)

. "$PSScriptRoot\PowerAppsAdminUtilities.ps1"
Install-Module -Name VstsTaskSdk -RequiredVersion 0.11.0 -Scope CurrentUser
Import-VstsTaskSdk

# Get inputs for the task
$connectedServiceName = Get-VstsInput -Name $authenticationType -Require

$endpoint = Get-VstsEndpoint -Name $PowerPlatformSPN -Require

$connectionString = Get-ConnectionString -Endpoint $endpoint -AuthenticationType $authenticationType

[xml]$xmlElm = Get-Content -Path $xrmFrameworkConfigPath
$selectedConnection = $xmlElm.xrmFramework.selectedConnection

Write-Verbose "Selected connection string : $($selectedConnection)"
Write-Verbose "Creating file on path $($connectionStringsConfigPath)"

$connectionStringsFileContent = '<connectionStrings><add name="' + $selectedConnection + '" connectionString="' + $connectionString + '" /></connectionStrings>'

Write-Verbose "Connection Strings file to be created : $($connectionStringsFileContent)"

$connectionStringsFileContent | Out-File -FilePath $connectionStringsConfigPath