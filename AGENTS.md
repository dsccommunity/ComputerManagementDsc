# ComputerManagementDsc — AI Agent Guide

## Repository Overview

**ComputerManagementDsc** is a PowerShell Desired State Configuration (DSC) resource module
for managing Windows computer and operating system settings.

- **Target platform:** Windows Server 2012 R2 and later; Windows 8.1 and later
- **DSC engines:** DSC v2 (WMF 5.0, MOF-based) and DSC v3 (PowerShell classes)
- **Organization:** [DSC Community](https://dsccommunity.org/)

## Resource Types

This repository contains two types of DSC resources:

| Type | Location | Pattern |
|------|----------|---------|
| MOF-based | `source/DSCResources/DSC_<ResourceName>/` | WMF 5.0 compatible, function-based |
| Class-based | `source/Classes/<N>.<ClassName>.ps1` | PowerShell class, inherits `ResourceBase` |

### MOF-based Resource Structure

```
source/DSCResources/DSC_<ResourceName>/
    DSC_<ResourceName>.psm1              # Resource implementation
    DSC_<ResourceName>.schema.mof        # MOF schema definition
    en-US/
        DSC_<ResourceName>.strings.psd1  # Localized strings
```

Required functions: `Get-TargetResource`, `Test-TargetResource`, `Set-TargetResource`

### Class-based Resource Structure

```
source/Classes/<N>.<ClassName>.ps1         # N = dependency group number
source/en-US/<ClassName>.strings.psd1      # Localized strings
```

Class resources inherit `ResourceBase` from `DscResource.Base`. Implement `GetCurrentState()`
and `Modify()`. Optionally implement `AssertProperties()` and `NormalizeProperties()`.

## Build & Test Workflow

### One-time setup (once per `pwsh` session)

```powershell
./build.ps1 -Tasks noop
```

### Build before running tests

```powershell
./build.ps1 -Tasks build
```

### Run all unit tests

```powershell
Invoke-Pester -Path 'tests/Unit' -Output Detailed
```

### Run a specific MOF resource unit test

```powershell
Invoke-Pester -Path 'tests/Unit/DSC_<ResourceName>.Tests.ps1' -Output Detailed
```

### Run class resource unit tests

```powershell
Invoke-Pester -Path 'tests/Unit/Classes/<ClassName>.Tests.ps1' -Output Detailed
```

> **NEVER run integration tests locally.** Integration tests require a full Windows
> environment configured as a DSC node and run only in CI. They may change system state.

## Key Conventions

- **Localized strings:** All `Write-Verbose`, `Write-Error`, and exception messages must use
  `$script:localizedData` keys. Load strings with `Get-LocalizedData` at the top of each
  `.psm1`.
- **DscResource.Common:** Check
  [`DscResource.Common`](https://github.com/dsccommunity/DscResource.Common/wiki) before
  writing new helper functions. Use `New-InvalidOperationException`, `New-ArgumentException`,
  and similar helpers instead of `throw`.
- **CHANGELOG.md:** Every code change must add an entry to the `Unreleased` section.
- **New resources:** Prefer class-based resources; use MOF-based only when required.

## External Resources

- [DSC Community Guidelines](https://dsccommunity.org/guidelines/)
- [DSC Community Blog](https://dsccommunity.org/blog/)
- [DscResource.Common wiki](https://github.com/dsccommunity/DscResource.Common/wiki)
- [DscResource.Base](https://github.com/dsccommunity/DscResource.Base)
- [DscResource.Test](https://github.com/dsccommunity/DscResource.Test)

## Detailed Guidance

See `.github/instructions/` for detailed style guidelines on PowerShell, Pester, unit tests,
integration tests, MOF resources, class-based resources, localization, markdown, and changelog.
