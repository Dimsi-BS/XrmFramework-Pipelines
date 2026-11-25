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
| plugins | false | [] | Set the list of plugin, Custom API and custom workflow activity projects in the solution | see [Plugins configuration](#plugins-configuration) |
| webResources | false | [] | Set the list of Web Resources projects in the solution | see [WebResources configuration](#webresources-configuration) |
| useXrmFrameworkCli | false | false | Deploy through the XrmFramework CLI: adds the `XrmFrameworkCliInstall@1` task and drops `XrmFrameworkConnectionStringsCreation@1`, so no connection string is written onto the agent | see [Deploying with the XrmFramework CLI](#deploying-with-the-xrmframework-cli) |
| xrmFrameworkCliVersion | false | | Pins the version of the `XrmFramework.Cli` dotnet tool. Empty installs the latest stable | ``` xrmFrameworkCliVersion: 3.1.166 ``` |
| xrmFrameworkCliDotNetVersion | false | 10.0.x | .NET SDK installed on the agent for the CLI. Set to an empty string to skip the install when the agent already has it | ``` xrmFrameworkCliDotNetVersion: '' ``` |
| projectRoot | false | $(Build.SourcesDirectory) | Folder containing the `Config` folder that the CLI reads (`Config/xrmFramework.config`) | ``` projectRoot: $(Build.SourcesDirectory)/src ``` |
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

Plugins, Custom APIs and custom workflow activities all live in the same net462/net48 assembly and are deployed by the same step, so they all go in this one list — there is no separate `workflows` parameter.

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
| dllPath | false | Explicit path to the built assembly. Left empty, the deployment finds it under `<projectPath>/bin/$(buildConfiguration)`, whichever target framework folder it sits in. CLI mode only |

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

By default the template deploys exactly as it always has: `XrmFrameworkConnectionStringsCreation@1` writes a `Config/connectionStrings.config` from the `PowerPlatformSPN` service connection, and the `XrmFrameworkDeployPlugins@1` / `XrmFrameworkDeployWebresources@1` tasks run the scaffolded `Utils/Deploy.*` console projects, which read that file.

Setting `useXrmFrameworkCli: true` switches to the [`xrmframework` CLI](https://www.nuget.org/packages/XrmFramework.Cli). Two things change in the build job:

- the `XrmFrameworkCliInstall@1` task is added — it installs the CLI as a dotnet tool and prepends it to `PATH`;
- `XrmFrameworkConnectionStringsCreation@1` is **removed**.

The deployment tasks stay the same. They look for the CLI on `PATH` and, finding it, deploy through it instead of through the `Deploy.*` executable — the template just passes them the extra inputs that route needs (`Project`, `ProjectRoot`, `DllPath`).

| | Default | `useXrmFrameworkCli: true` |
|--|--|--|
| Connection string on the agent | `Config/connectionStrings.config`, written by a task | none |
| Deployment engine | `Utils/Deploy.*` console projects | `xrmframework deploy plugins` / `deploy webresources` |
| `Utils/Deploy.*` projects needed | yes | no |
| Workload Identity federation | not supported | supported, no secret anywhere |
| Agent | .NET Framework / Mono for the deploy consoles | .NET 10 |

Both `plugins` and `webResources` go through the CLI in this mode — it is all or nothing, since the deployment tasks take their CLI route as soon as the CLI is on `PATH`.

```yaml
extends:
  template: xrmFramework.yml@xrmFramework
  parameters:
    useXrmFrameworkCli: true
    ConfigFolderPath: $(Build.SourcesDirectory)/Config
    projectRoot: $(Build.SourcesDirectory)

    # Plugins, Custom APIs and custom workflow activities all go in this one list
    plugins:
      - name: MyProject.Plugins
        configProjectName: Plugins
        projectPath: '$(Build.SourcesDirectory)/MyProject.Plugins'
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

#### How it authenticates

This is the point of the mode. A service connection is handed to a job only when a task in that job declares it as an input, so only a task can obtain an OIDC token for it — which is why the deployment stays inside `XrmFrameworkDeployPlugins@1` rather than becoming a plain `pwsh` step calling the CLI.

The task reads the `PowerPlatformSPN` service connection and hands the result to the CLI through the environment, never the command line:

| Service connection | What the task passes | What you have to store |
|--|--|--|
| Workload Identity federation | `--auth wif` + the OIDC token it already fetched | nothing |
| Service Principal + client secret | `--auth clientsecret` + the secret | the secret, in the service connection |
| Neither | `--auth connectionstring` | a `Config/connectionStrings.config` — which this mode no longer writes, so re-enable the task |

A federated service connection is the reason to turn this mode on: nothing is written to disk, and there is no secret to rotate.

#### What the CLI reads

The CLI takes its target solutions from the project's own configuration rather than from task inputs:

- `--project-root` must point at the folder **containing** a `Config` folder. With the default `ConfigFolderPath: $(Build.SourcesDirectory)/Config`, the default `projectRoot: $(Build.SourcesDirectory)` is already correct.
- `Config/xrmFramework.config` supplies, for each `<add name="..." targetSolution="..." />` entry, the solution the component is deployed into.
- the target environment comes from the service connection, not from the configuration.

As a consequence, in CLI mode the `solution` property of a plugin / webResource entry is **not** used — the target solution comes from `xrmFramework.config`. Use `configProjectName` when the project `name` in the pipeline differs from the `name` attribute declared in `xrmFramework.config`.

#### Requirements

- The **XrmFramework DevOps Tasks** extension has to be recent enough to ship the CLI installer task (`XrmFrameworkCliInstall`) and the deployment tasks that look for the CLI on `PATH` — `XrmFrameworkDeployPlugins` 1.2.0 and `XrmFrameworkDeployWebresources` 1.1.2. An older extension has no installer task and the pipeline fails to compile.
- The CLI targets .NET 10, so the template installs that SDK with `UseDotNet@2`. Set `xrmFrameworkCliDotNetVersion: ''` to skip the install on a self-hosted agent that already has it.
- Deployment itself runs on .NET, so it no longer needs .NET Framework or Mono on the agent.
- Building a net462/net48 plugin project still requires a Windows agent (or the .NET Framework reference assemblies), exactly as before.
- The deployment tasks pass `--auth` and `--environment`, so the CLI has to be **3.1.166 or later**. That is the latest stable release, which an empty `xrmFrameworkCliVersion` installs, so there is nothing to set.

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
