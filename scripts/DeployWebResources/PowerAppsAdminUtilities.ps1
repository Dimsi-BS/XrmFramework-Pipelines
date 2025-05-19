

function Initialize-PowerAppsAdminModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Endpoint,
        [Parameter(Mandatory = $true)]
        $AuthenticationType,
        [string] $version)

    Trace-VstsEnteringInvocation $MyInvocation
    try {
        Write-Verbose "Env:PSModulePath: '$env:PSMODULEPATH'"
        Import-PowerAppsAdminModule -version $version

        Write-Verbose "Initializing PowerAppsAdmin Module."
        Initialize-PowerAppsAdminConnection -Endpoint $Endpoint -AuthenticationType $AuthenticationType
    }
    finally {
        Trace-VstsLeavingInvocation $MyInvocation
    }
}

function Get-ConnectionString {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Endpoint,
        [Parameter(Mandatory = $true)]
        $Environment,
        [Parameter(Mandatory = $true)]
        $AuthenticationType)


    if ($AuthenticationType -eq 'PowerPlatformSPN') {
        return "AuthType=ClientSecret; Url=$($Environment); AppId=$($Endpoint.Auth.Parameters.applicationId); ClientSecret=$($Endpoint.Auth.Parameters.clientSecret);"
    }
    elseif ($AuthenticationType -eq 'PowerPlatformEnvironment') {
        return "AuthType=OAuth; Url=$($Environment); Username=$($Endpoint.Auth.Parameters.username); Password=$($Endpoint.Auth.Parameters.password); AppId=51f81489-12ee-4a9e-aaae-a2591f45987d; RedirectUri=app://58145B91-0C36-4500-8554-080854F2AC97;"
    }
    else {
        throw (Get-VstsLocString -Key PowerAppsAdmin_UnsupportedAuthenticationType -ArgumentList $Endpoint.Auth.Parameters.authenticationType)
    } 
}

function Import-PowerAppsAdminModule {
    [CmdletBinding()]
    param([string] $version)

    Trace-VstsEnteringInvocation $MyInvocation
    try {
        # We are only looking for Microsoft.PowerApps.Administration.PowerShell module because all the command required for initialize the PowerApps Admin session is in Microsoft.PowerApps.Administration.PowerShell module.
        $moduleName = "Microsoft.PowerApps.Administration.PowerShell"
        # Attempt to resolve the module.
        Write-Verbose "Attempting to find the module '$moduleName' from the module path."
        
        $module = GetModule -moduleName $moduleName
      
        if (!$module) {
            Write-Verbose "No module found with name: $moduleName"
            Write-Host "##[command]Install-Module -Name $($moduleName) -Scope CurrentUser -SkipPublisherCheck -Force -Confirm:$false -AllowClobber"
            Install-Module -Name $moduleName -Scope CurrentUser -SkipPublisherCheck -Force -Confirm:$false -AllowClobber;
        
            $module = GetModule -moduleName $moduleName

            if (!$module) {
                Write-Verbose "No module found with name: $moduleName"
                throw (New-Object System.Exception((Get-VstsLocString -Key PowerAppsAdmin_ModuleNotFound -ArgumentList $moduleName)))
            }    
        }

        # Import the module.
        Write-Host "##[command]Import-Module -Name $($module.Path) -Global"
        $module = Import-Module -Name $module.Path -Global -PassThru -Force
        Write-Verbose "Imported module version: $($module.Version)"
    }
    finally {
        Trace-VstsLeavingInvocation $MyInvocation
    }
}

function GetModule {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $moduleName
    )

    if ($version -eq "") {
        $module = Get-Module -Name $moduleName -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
    }
    else {
        $modules = Get-Module -Name $moduleName -ListAvailable
        foreach ($moduleVal in $modules) {
            # $moduleVal.Path will have value like C:\Program Files\WindowsPowerShell\Modules\Microsoft.PowerApps.Administration.PowerShell\1.2.1\Microsoft.PowerApps.Administration.PowerShell.psd1
            $adminModulePath = Split-Path (Split-Path (Split-Path $moduleVal.Path -Parent) -Parent) -Parent
            $adminModulePath = $adminModulePath + "\PowerAppsAdmin\*"
            $adminModuleVersion = split-path -path $adminModulePath -Leaf -Resolve
            if ($adminModuleVersion -eq $version) {
                $module = $moduleVal
                break
            }   
        }
    }

    return $module
}

function Initialize-PowerAppsAdminConnection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Endpoint,
        [Parameter(Mandatory = $true)]
        $AuthenticationType)

    if ($AuthenticationType -eq 'PowerPlatformSPN') {
        try {
            Write-Host "##[command]Add-PowerAppsAccount -TenantID $($Endpoint.Auth.Parameters.tenantId) -ApplicationId $($Endpoint.Auth.Parameters.applicationId) -ClientSecret $($Endpoint.Auth.Parameters.clientSecret)"
            $null = Add-PowerAppsAccount `
                -TenantID $Endpoint.Auth.Parameters.tenantId `
                -ApplicationId $Endpoint.Auth.Parameters.applicationId `
                -ClientSecret $Endpoint.Auth.Parameters.clientSecret `
                -WarningAction SilentlyContinue

        } 
        catch {
            # Provide an additional, custom, credentials-related error message.
            Write-VstsTaskError -Message $_.Exception.Message
            Assert-TlsError -exception $_.Exception
            throw (New-Object System.Exception((Get-VstsLocString -Key PowerAppsAdmin_ServicePrincipalError), $_.Exception))
        }

    }
    elseif ($AuthenticationType -eq 'PowerPlatformEnvironment') {
        try {
            Write-Host "##[command]Add-PowerAppsAccount -Username $($Endpoint.Auth.Parameters.username) -Password *****"
            
            $securePassword = ConvertTo-SecureString -String $Endpoint.Auth.Parameters.password -AsPlainText -Force;

            $null = Add-PowerAppsAccount `
                -Username $Endpoint.Auth.Parameters.username `
                -Password $securePassword `
                -WarningAction SilentlyContinue
        }
        catch {
            # Provide an additional, custom, credentials-related error message.
            Write-VstsTaskError -Message $_.Exception.Message
            throw (New-Object System.Exception((Get-VstsLocString -Key PowerAppsAdmin_UsernamePasswordError), $_.Exception))
        }
    }
    else {
        throw (Get-VstsLocString -Key PowerAppsAdmin_UnsupportedAuthenticationType -ArgumentList $Endpoint.Auth.Parameters.authenticationType)
    } 
}

function GetEnvironment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Url
    )

    $environment = Get-AdminPowerAppEnvironment | Where-Object { (-not [string]::IsNullOrWhiteSpace($_.Internal.properties.linkedEnvironmentMetadata.instanceUrl)) -and ($_.Internal.properties.linkedEnvironmentMetadata.instanceUrl.TrimEnd("/") -ieq $Url.TrimEnd("/")) }

    Write-Verbose "Environment = $($environment | Format-Table | Out-String)"

    if ($environment) {
        return $environment.EnvironmentName;
    }

    throw (New-Object System.Exception((Get-VstsLocString -Key PowerAppsAdmin_EnvironmentNotFound)))
}