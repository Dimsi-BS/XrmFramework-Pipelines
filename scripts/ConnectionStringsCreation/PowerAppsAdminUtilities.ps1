

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
        $AuthenticationType)

    $Environment = getEnvironmentUrl;

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


function getEnvironmentUrl {

    $_a;
    $explicitEnvInputParamName = 'Environment';
    $variableName = $null;
    # try reading the optional, but explicit task input parameter "Environment"
    $endpointUrl = Get-VstsInput -Name $explicitEnvInputParamName -Require
    if ($endpointUrl) {
        Write-Verbose "Discovered environment url from explicit input parameter '$explicitEnvInputParamName': $endpointUrl";

        $varReferenceCandidate, $isRefExpr = IsolateVariableReference -VariableValue $endpointUrl
        if ($isRefExpr) {
            $variableName = $varReferenceCandidate;
            Write-Verbose "Discovered Azure DevOps variable expression that needs resolving: $endpointUrl -> $variableName";
            $endpointUrl = $null;
        }
        else {
            $endpointUrl = $varReferenceCandidate;
        }
    }
    # try finding the environment url that should be used for the calling task in this order:
    # - check for pipeline/task variables (typically set by e.g. createEnv task)
    if (!$endpointUrl) {
        $envParams = GetPipelineOutputVariable -varName $variableName;
        $endpointUrl = $envParams.value;
        $taskName = $envParams.taskName;
        if ($endpointUrl) {
            if ($taskName) {
                Write-Verbose "Discovered environment url as task output variable ($taskName - $variableName): $endpointUrl";
            }
            else {
                Write-Verbose "Discovered environment url as pipeline/task variable ($variableName) : $endpointUrl"
            }
        }
    }
    # - try named OS environment variable:
    if (!$endpointUrl) {
        $endpointUrl = [Environment]::GetEnvironmentVariable($variableName);
        if ($endpointUrl) {
            Write-Verbose "Discovered environment url as OS environment variable ($variableName): $endpointUrl";
        }
    }
    # - finally, fall back to use the env url that is part of the Azure DevOps service connection (i.e. called endpoint in the SDK here)
    if (!$endpointUrl) {
        $endpointUrl = RetrieveEndpointUrl
        Write-Verbose "Falling back to url from service connection, using: $endpointUrl";
    }

    return $endpointUrl;
}

function RetrieveEndpointUrl {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $defaultAuthType
    )

    $endpointName = Get-VstsInput -Name $authenticationType;
    if (!$endpointName) {
        throw (New-Object System.Exception((Get-VstsLocString -Key PowerAppsAdmin_EndpointNotFound -ArgumentList $endpointName, $authenticationType)))
    }
    $url = (Get-VstsEndpoint -Name $endpointName).Url;
    if (!$url) {
        throw (New-Object System.Exception((Get-VstsLocString -Key PowerAppsAdmin_EndpointUrlNotFound -ArgumentList $endpointName)))
    }
    return $url;
}

function GetPipelineOutputVariable {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $varName
    )

    $e_1, $_a;
    $envParams = @{
        "value"= $null
        "taskName" = $null
    };
    $value = GetPipelineVariable -varName $varName
    if ($value) {
        #Prioritise pipeline variable
        $envParams.value = $value;
    }
    return $envParams;
}

function GetPipelineVariable {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $varName
    )

    $value;
    if ($true) {
        # NOTE: tl.getTaskVariable is only supported on newer agents >= 2.115.0, but our task.json still allow for agents 1.9.x
        $value = Get-VstsTaskVariable -Name $varName;
        Write-Verbose "Get-VstsTaskVariable -Name $varName = $value"
    }
    # try looking for plain pipeline variable:
    if (!$value) {
        $value = [Environment]::GetEnvironmentVariable($varName);
        Write-Verbose "[Environment]::GetEnvironmentVariable($varName) = $value"
    }

    if ($value -eq " ") {
        $value = $null
    }
    return $value;
}

function IsolateVariableReference {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $VariableValue
    )

    $extractVarNameRegex = "\$\((\S+)\)";

    $matchInfo = $VariableValue | Select-String -Pattern $extractVarNameRegex

    $isRefExpression = $null -ne $matchInfo;
    $result = If($isRefExpression) { $matchInfo.Matches.Groups[1].Value} else { $VariableValue};

    Write-Verbose "IsolateVarRef: $VariableValue -> $result (isRefExpression=$isRefExpression)"

    return $result, $isRefExpression;
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

    Write-Verbose "Get-AdminPowerAppEnvironment = $(Get-AdminPowerAppEnvironment | Format-Table | Out-String)"

    Write-Verbose "Get-AdminPowerAppEnvironment = $(Get-AdminPowerAppEnvironment | Where-Object { (-not [string]::IsNullOrWhiteSpace($_.Internal.properties.linkedEnvironmentMetadata.instanceUrl))} | Select-Object {$_.Internal.properties.linkedEnvironmentMetadata.instanceUrl} | Format-Table | Out-String)"

    Write-Verbose "Url = $($Url)"


    $environment = Get-AdminPowerAppEnvironment | Where-Object { (-not [string]::IsNullOrWhiteSpace($_.Internal.properties.linkedEnvironmentMetadata.instanceUrl)) -and ($_.Internal.properties.linkedEnvironmentMetadata.instanceUrl.TrimEnd("/") -ieq $Url.TrimEnd("/")) }

    Write-Verbose "Environment = $($environment | Format-Table | Out-String)"

    if ($environment) {
        return $environment.EnvironmentName;
    }

    throw (New-Object System.Exception((Get-VstsLocString -Key PowerAppsAdmin_EnvironmentNotFound)))
}