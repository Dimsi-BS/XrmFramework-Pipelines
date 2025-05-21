# XrmFramework-Pipelines

This project is containing the XrmFramework pipeline templates that are used to deploy XrmFramework projects.

## Quick start

Install the XrmFramework DevOps Tasks DevOps Extension available [https://marketplace.visualstudio.com/items?itemName=Dimsi.XrmFramework-DevOpsTasks](Here)

Reference the XrmFramework Template

```yaml
resources:
  repositories:
    - repository: xrmFramework
      type: github
      endpoint: github
      name: Dimsi-BS/XrmFramework-Pipelines
      ref: refs/tags/1.0.0

```

```yaml

extends:
  template: xrmFramework.yml@xrmFramework
  parameters:
```


## Template parameters

Here is the list of all possible template parameters.

|Parameter | Mandatory | Default value|Description | Usage|
|---|---|---|---|---|
| **solutions** | true | | List of solutions of your project | ``` solutions: ```<br/>```- MyTablesSolution ```<br/>```- MyPluginsSolution ```<br/>```- MyWebresourcesSolution ```<br/>```- MyAppsSolution ```<br/>```- MySecurityRolesSolution ```|
|**solutionsImportOrder**| true | | The import order that must be applied during deployment <br /> (You can reference the same solution multiple times if needed) |  ``` solutionsImportOrder: ```<br/>```- MySecurityRolesSolution ```<br/>```- MyTablesSolution ```<br/>```- MyPluginsSolution ```<br/>```- MyWebresourcesSolution ```<br/>```- MyAppsSolution ```<br/>```- MySecurityRolesSolution ```|
| **environments** | true | | Sets the list of deployment environments | see [Environments configuration](#environments-configuration) |
| **PowerPlatformSPN**| true | | Name of the service Connection to the development environment | ``` PowerPlatformSPN : MyServiceConnection ```|
| plugins | false | [] | Set the list of plugin projects in the solution | see [Plugins configuration](#plugins-configuration) |
| webResources | false | [] | Set the list of Web Resources projects in the solution | see [WebResources configuration](#webresources-configuration) |
| azureFunctions | false | [] | Set the list of Azure Functions projects in the solution | see [Azure Functions configuration](#azure-functions-configuration) |
|SolutionFile | true (if using plugin deployment) | | Name of the solution file for your XrmFramework project | ``` SolutionFile: MySolution.sln ```|
|ConfigFolderPath|false| | Path to the folder containing the XrmFramework configuration files | ```ConfigFolderPath`: $(Build.SourcesDirectory)/Config/```|
| extractSolutions | false | true | Indicates if we want the solutions to be extracted to the source control on build | ``` extractSolutions: false``` |
| skipBuildJob | false | true | Indicates if we want build job skipped | ``` skipBuildJob: false``` |
| disableQualityCheck | false | false | Indicates if we want the solutions to be extracted to the source control on build | ``` disableQualityCheck: true``` |
|variableGroup | false | | Name of the variable group used for the Build phase | see [Variable groups](#variable-groups) |
| installNbgvTool | false | false | Indicates if we want the nbgv tools to be installed by the pipeline (Azure agents have it installed by default) | ``` installNbgvTool: false``` |
| timeout | false | 60 | **For paid Azure workers only** Overides the default 60 minutes timeout for a running job  | ``` timeout: 120``` |

### Environments configuration

Here is an example of the ```environments``` parameter value

```yaml

    environments:
      - name: UAT 
        variableGroup: My.UAT.VariableGroup

      - name: PRODUCTION 
        variableGroup: My.Production.VariableGroup
        PowerPlatformSPN: Specific_SPN_For_Production
        pool: Specific_Pool_For_Production
        setAdminModeOnDeploy: true
        backupEnvironmentOnDeploy : false
```

The environment object contains the following properties

| Name | Mandatory | Default value | Description |
|--|--|--|--|
| **name** | true | | Name of the environment as configured in Pipelines > Environments Azure DevOps project |
| **variableGroup** | true | | Name of the variable group that will be applied for this environment (see [Variable groups](#variable-groups))|
| PowerPlatformSPN| false | The global PowerPlatformSPN | Name of the service Connection for this environment |
| pool| false | The global pool | Name of the agent pool used for this environment |
| setAdminModeOnDeploy| false | true | Specifies if the AdminMode is enabled before deploying to an environment |
| backupEnvironmentOnDeploy | false | true | Indicates if the backup will be skipped while deployment |
| retentionDays        | false | | Specifies a custom retention time for the stage                                                                |

### Plugins configuration

When you specify a ```plugins``` parameter the template will deploy (and register) automatically the latest version of plugins on to the development environment before exporting the solutions.

Here is an example of the ```plugins``` parameter value

```yaml

    plugins:
      - name: MyProject.Plugins
        solution: MyPluginsSolution
        projectPath: '$(Build.SourcesDirectory)/MyProject.Plugins'
        deployProjectPath: '$(Build.SourcesDirectory)/Utils/Deploy.MyProject.Plugins'
```

The plugin object contains the following properties

| Name | Mandatory | Description |
|--|--|--|
| **name** | true | Name of the csproj file for this plugin project |
| **solution** | true | Unique name of the solution where the plugin will be deployed |
| **projectPath**| true | Path to the csproj file |
| **deployProjectPath**| true | Path to the XrmFramework Deploy project for this plugin |

### WebResources configuration

When you specify a ```webResources``` parameter the template will deploy (and register) automatically the latest version of the webresources on to the development environment before exporting the solutions.

Here is an example of the ```webResources``` parameter value

```yaml

    webResources:
      - name: MyProject.WebResources
        solution: MyTablesSolution
        projectPath: '$(Build.SourcesDirectory)/MyProject.WebResources'
        deployProjectPath: '$(Build.SourcesDirectory)/Utils/Deploy.MyProject.WebResources'
```

The webResource object contains the following properties

| Name | Mandatory | Description |
|--|--|--|
| **name** | true | Name of the csproj file for this webresources project |
| **solution** | true | Unique name of the solution where the web resources will be deployed |
| **projectPath**| true | Path to the csproj file |
| **deployProjectPath**| true | Path to the XrmFramework Deploy project for this web resource project |

### Azure Functions configuration

When you specify a ```azureFunctions``` parameter the template will build and deploy automatically the latest version of Azure Functions project.

Here is an example of the ```azureFunctions``` parameter value

```yaml

    azureFunctions:
      - name: Twin.Audit.AF
        projectPath: '$(Build.SourcesDirectory)/AzureFunctions/Twin.Audit.AF'
        azureSubscription: 'SPN-TWIN-UAT'
        appName: 'AP-TWIN-AUDIT-DEV'
        environments:
          - name: UAT
            azureSubscription:
            appName: 
            resourceGroupName:
            slotName:
          - name: PROD
```


### Variable groups

Azure DevOps variable groups can be configured in the pipeline file to pilot some settings of the build / deployment stages

List of variables that can be set

| Name | Description|
|--|--|
| BuildTools.EnvironmentUrl | Url of the Dataverse environment (ex: https://myorg.crm.dynamics.com) |
| SolutionsToIgnore | List (separated by colon ,) of solution unique names we want to ignore in the deployment stage |
| SolutionsToUpgrade | List (separated by colon ,) of solution unique names we want to install using an upgrade pattern |

### Prerequisites

If you want the Backup and Admin mode behaviors to work you will need to add the Application Id as a PowerPlatform Admin with the Powershell command :

```pwsh
New-PowerAppManagementApp -ApplicationId $appId
```
