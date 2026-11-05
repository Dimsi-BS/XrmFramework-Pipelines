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
| solutionVersion | false | | Sets the version of the solutions before exporting | ``` solutionVersion: 52.0.1 ```<br/>```Solution version is suffixed by the BuildId of the current build so it needs to be a three parts version number```|
|**solutionsImportOrder**| true | | The import order that must be applied during deployment <br /> (You can reference the same solution multiple times if needed) |  ``` solutionsImportOrder: ```<br/>```- MySecurityRolesSolution ```<br/>```- MyTablesSolution ```<br/>```- MyPluginsSolution ```<br/>```- MyWebresourcesSolution ```<br/>```- MyAppsSolution ```<br/>```- MySecurityRolesSolution ```|
| solutionUseSettingFile | false | [] | List of solutions that use a deployment settings file during import | ``` solutionUseSettingFile: ```<br/>```- MyTablesSolution ```|
| generateSettingsSteps | false | [] | Custom steps used to generate deployment settings files | See [Settings files](#settings-files) |
| solutionSettingsFolderPath | false | | Folder written by `generateSettingsSteps` and published as the `settings` artifact | See [Settings files](#settings-files) |
| **environments** | true | | Sets the list of deployment environments | see [Environments configuration](#environments-configuration) |
| **PowerPlatformSPN**| true | | Name of the service Connection to the development environment | ``` PowerPlatformSPN : MyServiceConnection ```|
| plugins | false | [] | Set the list of plugin projects in the solution | see [Plugins configuration](#plugins-configuration) |
| workflows | false | [] | Set the list of custom workflow activity projects in the solution | see [Workflows configuration](#workflows-configuration) |
| webResources | false | [] | Set the list of Web Resources projects in the solution | see [WebResources configuration](#webresources-configuration) |
| useXrmFrameworkCli | false | false | Deploy plugins and workflows with the XrmFramework CLI instead of the `XrmFrameworkDeployPlugins@1` task | see [Deploying with the XrmFramework CLI](#deploying-with-the-xrmframework-cli) |
| useXrmFrameworkCliForWebresources | false | false | Also route web resources through the CLI. Requires `useXrmFrameworkCli: true` **and** a CLI build where `deploy webresources` reads the project configuration | see [Known limitation](#known-limitation) |
| xrmFrameworkCliVersion | false | | Pins the version of the `xrmframework.cli` dotnet tool. Empty installs the latest | ``` xrmFrameworkCliVersion: 3.1.156 ``` |
| xrmFrameworkCliDotNetVersion | false | 10.0.x | .NET SDK installed on the agent for the CLI. Set to an empty string to skip the install when the agent already has it | ``` xrmFrameworkCliDotNetVersion: '' ``` |
| projectRoot | false | $(Build.SourcesDirectory) | Folder containing the `Config` folder that the CLI reads (`Config/xrmFramework.config` + `Config/connectionStrings.config`) | ``` projectRoot: $(Build.SourcesDirectory)/src ``` |
| azureFunctions | false | [] | Set the list of Azure Functions projects in the solution | see [Azure Functions configuration](#azure-functions-configuration) |
| webApplications | false | [] | Set the list of web applications to build and deploy | see [Web applications configuration](#web-applications-configuration) |
|SolutionFile | true (if using plugin deployment) | | Name of the solution file for your XrmFramework project | ``` SolutionFile: MySolution.sln ```|
|ConfigFolderPath|false| | Path to the folder containing the XrmFramework configuration files | ```ConfigFolderPath`: $(Build.SourcesDirectory)/Config/```|
| extractSolutions | false | true | Indicates if we want the solutions to be extracted to the source control on build | ``` extractSolutions: false``` |
| skipBuildJob | false | true | Indicates if we want build job skipped | ``` skipBuildJob: false``` |
| disableQualityCheck | false | false | Indicates if we want the solutions to be extracted to the source control on build | ``` disableQualityCheck: true``` |
|variableGroup | false | | Name of the variable group used for the Build phase | see [Variable groups](#variable-groups) |
| variableGroups | false | [] | List of additional variable groups used for the Build phase | ``` variableGroups: ```<br/>```- My.Common.VariableGroup ```<br/>```- My.Security.VariableGroup ```|
| installNbgvTool | false | false | Indicates if we want the nbgv tools to be installed by the pipeline (Azure agents have it installed by default) | ``` installNbgvTool: false``` |
| beforeBuildUsersteps | false | [] | Custom steps executed before the build starts | See [Custom pipeline steps](#custom-pipeline-steps) |
| beforeSolutionExportUsersteps | false | [] | Custom steps executed before solutions are exported | See [Custom pipeline steps](#custom-pipeline-steps) |
| timeout | false | 60 | **For paid Azure workers only** Overides the default 60 minutes timeout for a running job  | ``` timeout: 120``` |

### Environments configuration

Here is an example of the ```environments``` parameter value

```yaml

    environments:
      - name: UAT 
        variableGroup: My.UAT.VariableGroup
        variableGroups:
          - My.UAT.Shared.VariableGroup

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
| variableGroups | false | [] | Additional variable groups to link for this environment |

### Settings files

Solutions listed in `solutionUseSettingFile` are imported with a deployment settings file. Use `generateSettingsSteps` to create those files during the export job, and `solutionSettingsFolderPath` to tell the template which folder to publish as the `settings` artifact.

The custom steps must write one file per solution, laid out as `<solutionSettingsFolderPath>/<solution>/settings.json`, because the deployment stage reads them back from `$(Pipeline.Workspace)/settings/<solution>/settings.json`.

```yaml
solutionUseSettingFile:
  - MyTablesSolution

solutionSettingsFolderPath: $(Build.SourcesDirectory)/settings

generateSettingsSteps:
  - pwsh: ./scripts/generate-settings.ps1
```

Leaving `solutionSettingsFolderPath` empty skips the whole settings mechanism: `generateSettingsSteps` is not executed, the `settings` artifact is not published, and solutions are imported without a settings file.

### Custom pipeline steps

Use the step-list parameters to run custom Azure DevOps steps at specific points in the build pipeline.

```yaml
beforeBuildUsersteps:
  - script: npm install

beforeSolutionExportUsersteps:
  - pwsh: ./scripts/prepare-export.ps1
```

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
| **solution** | true (task mode) | Unique name of the solution where the plugin will be deployed. Ignored in CLI mode, where the target solution comes from `xrmFramework.config` |
| **projectPath**| true | Path to the csproj file |
| **deployProjectPath**| true (task mode) | Path to the XrmFramework Deploy project for this plugin. Unused in CLI mode |
| configProjectName | false | Project `name` as declared in `xrmFramework.config`. Defaults to `name`. CLI mode only |
| dllPath | false | Explicit path to the built assembly. Defaults to `<projectPath>/bin/$(buildConfiguration)/<targetFramework>/<name>.dll`. CLI mode only |
| targetFramework | false | Target framework folder used to locate the assembly. Defaults to `net462`. CLI mode only |

### WebResources configuration

When you specify a ```webResources``` parameter the template will deploy (and register) automatically the latest version of the webresources on to the development environment before exporting the solutions.

Here is an example of the ```webResources``` parameter value

```yaml

    webResources:
      - name: MyProject.WebResources
        solution: MyTablesSolution
        projectPath: '$(Build.SourcesDirectory)/MyProject.WebResources'
        deployProjectPath: '$(Build.SourcesDirectory)/Utils/Deploy.MyProject.WebResources'
        runNpmInstall: true
        deploySourcePath: '$(Build.SourcesDirectory)/MyProject.WebResources/dist'
```

The webResource object contains the following properties

| Name | Mandatory | Description |
|--|--|--|
| **name** | true | Name of the csproj file for this webresources project |
| **solution** | true (task mode) | Unique name of the solution where the web resources will be deployed. Ignored in CLI mode, where the target solution comes from `xrmFramework.config` |
| **projectPath**| true | Path to the csproj file |
| **deployProjectPath**| true (task mode) | Path to the XrmFramework Deploy project for this web resource project. Unused in CLI mode |
| configProjectName | false | Project `name` as declared in `xrmFramework.config`. Defaults to `name`. CLI mode only |
| runNpmInstall| false | When set to ``true``, ``npm install`` is run in ``projectPath`` before the solution is built (the folder must contain a ``package.json``) |
| deploySourcePath| false | When set overrides the place where the resources are searched to be deployed |

### Deploying with the XrmFramework CLI

By default the template registers plugins and web resources through the `XrmFrameworkDeployPlugins@1` and `XrmFrameworkDeployWebresources@1` tasks of the DevOps extension, which drive the scaffolded `Utils/Deploy.*` console projects.

Setting `useXrmFrameworkCli: true` replaces those tasks with the [`xrmframework` CLI](https://www.nuget.org/packages/XrmFramework.Cli) installed as a dotnet tool on the agent:

| Component | Switched by | Command run by the template |
|--|--|--|
| Plugins and Custom APIs | `useXrmFrameworkCli` | `xrmframework deploy plugins --dll <dll> --project <name> --project-root <root> --noprompt` |
| Custom workflow activities | `useXrmFrameworkCli` | `xrmframework deploy plugins --dll <dll> --project <name> --project-root <root> --noprompt` |
| Web resources | `useXrmFrameworkCliForWebresources` | `xrmframework deploy webresources --project <name> --path <dir> --project-root <root> --noprompt` |

Web resources are behind a second switch because `deploy webresources` is still broken in the published CLI — see [Known limitation](#known-limitation). With `useXrmFrameworkCli: true` alone, plugins and workflows go through the CLI while web resources keep using the DevOps task.

Plugins, Custom APIs and custom workflow activities all live in the same net462/net48 assembly, so they share a single command. It instantiates every class, reads what `AddSteps()` declares and reconciles the Dataverse registration records with it — a class removed from the source has its steps deregistered automatically.

```yaml
extends:
  template: xrmFramework.yml@xrmFramework
  parameters:
    useXrmFrameworkCli: true
    # useXrmFrameworkCliForWebresources: true   # see Known limitation below
    ConfigFolderPath: $(Build.SourcesDirectory)/Config
    projectRoot: $(Build.SourcesDirectory)

    plugins:
      - name: MyProject.Plugins
        configProjectName: Plugins
        projectPath: '$(Build.SourcesDirectory)/MyProject.Plugins'

    workflows:
      - name: MyProject.Workflows
        configProjectName: Workflows
        projectPath: '$(Build.SourcesDirectory)/MyProject.Workflows'

    webResources:
      - name: MyProject.WebResources
        configProjectName: WebResources
        projectPath: '$(Build.SourcesDirectory)/MyProject.WebResources'
        runNpmInstall: true
        deploySourcePath: '$(Build.SourcesDirectory)/MyProject.WebResources/dist'
```

#### What the CLI reads

The CLI takes its target environment and its target solutions from the project's own configuration rather than from task inputs:

- `--project-root` must point at the folder **containing** a `Config` folder. With the default `ConfigFolderPath: $(Build.SourcesDirectory)/Config`, the default `projectRoot: $(Build.SourcesDirectory)` is already correct.
- `Config/xrmFramework.config` supplies `selectedConnection` and, for each `<add name="..." targetSolution="..." />` entry, the solution the component is deployed into.
- `Config/connectionStrings.config` supplies the connection string. The `XrmFrameworkConnectionStringsCreation@1` task still generates it from the `PowerPlatformSPN` service connection, so that step is unchanged.

As a consequence, in CLI mode the `solution` property of a plugin / workflow / webResource entry is **not** used — the target solution comes from `xrmFramework.config`. Use `configProjectName` when the project `name` in the pipeline differs from the `name` attribute declared in `xrmFramework.config`.

#### Agent requirements

- The CLI targets .NET 10, so the template installs that SDK with `UseDotNet@2`. Set `xrmFrameworkCliDotNetVersion: ''` to skip the install on a self-hosted agent that already has it.
- The plugin inventory now runs on .NET, so deployment no longer needs .NET Framework or Mono on the agent.
- Building a net462/net48 plugin project still requires a Windows agent (or the .NET Framework reference assemblies), exactly as before.

#### Known limitation

`xrmframework deploy webresources` is broken up to and including CLI **3.1.156**: `WebResourceHelper.SyncWebResources` resolves the connection string through `ConfigurationManager.ConnectionStrings` instead of the project configuration loaded by `ConfigHelper.UseProjectConfig`, so the command reads the CLI's own `XrmFramework.Cli.dll.config` and fails with:

```
Error: Unable to open configSource file 'connectionStrings.config'.
(.../xrmframework.cli/3.1.156/tools/net10.0/any/XrmFramework.Cli.dll.config line 12)
```

`xrmframework deploy plugins` is not affected — it resolves its connection through `ConfigHelper.GetSelectedConnectionString()`.

That is why `useXrmFrameworkCliForWebresources` defaults to `false`: leave it off and web resources keep going through `XrmFrameworkDeployWebresources@1`, which works. Flip it to `true` once a CLI version carrying the fix is published.

### Workflows configuration

When you specify a ```workflows``` parameter the template will deploy automatically the latest version of your custom workflow activities on to the development environment before exporting the solutions.

```yaml

    workflows:
      - name: MyProject.Workflows
        solution: MyWorkflowsSolution
        configProjectName: Workflows
        projectPath: '$(Build.SourcesDirectory)/MyProject.Workflows'
        deployProjectPath: '$(Build.SourcesDirectory)/Utils/Deploy.MyProject.Workflows'
```

The workflow object contains the same properties as a plugin entry (see [Plugins configuration](#plugins-configuration)). Custom workflow activities cannot be deployed as a NuGet plugin package, so they always use assembly deployment.

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

### Web applications configuration

When you specify a `webApplications` parameter the template builds and deploys the web application package to the matching environment.

```yaml
    webApplications:
      - name: My.WebApp
        projectPath: '$(Build.SourcesDirectory)/My.WebApp'
        azureSubscription: 'My Azure Subscription'
        appType: webApp
        appName: 'MY-WEB-APP-DEV'
        environments:
          - name: UAT
            appName: 'MY-WEB-APP-UAT'
```

The web application object supports `name`, `projectPath`, `azureSubscription`, `appType`, `appName`, and environment-specific overrides for `azureSubscription`, `appType`, `appName`, `resourceGroupName`, and `slotName`.


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
