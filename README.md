# XrmFramework-Pipelines

This project is containing the XrmFramework pipeline templates that are used to deploy XrmFramework projects.

## Usage

Reference the XrmFramework Template

```yaml
resources:
  repositories:
    - repository: xrmFramework
        type: github
        endpoint: github
        name: cgoconseils/XrmFramework-Pipelines
        ref: refs/tags/1.0.0

```

```yaml

extends:
  template: xrmFramework.yml@xrmFramework
  parameters:
```