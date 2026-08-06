# Requirements

- ComputerManagementDsc-specific guidelines and requirements override general project
  guidelines and requirements.

## Module Identity

**ComputerManagementDsc** is a DSC Community PowerShell module providing Desired State
Configuration resources for Windows computer and OS settings.

## Terminology

- **Command**: Public command
- **Function**: Private function
- **Resource**: DSC class-based resource

## Core Requirements

- Instructions take precedence over existing code patterns.
- Always update the `Unreleased` section of `CHANGELOG.md` for every code change.
- Localize all user-visible strings using `$script:localizedData` keys; never use
  hardcoded string literals in `Write-Verbose`, `Write-Error`, or exception messages.
- Check [`DscResource.Common`](https://github.com/dsccommunity/DscResource.Common/wiki)
  before creating private helper functions.
- Use `New-InvalidOperationException`, `New-ArgumentException`, and similar helpers from
  `DscResource.Common` instead of `throw`.
- Separate reusable logic into private functions.
- Add unit tests for all commands, functions, and resources.
- Add integration tests for all public commands and resources.

## Resource Types

This repository contains two types of DSC resources:

- **MOF-based resources** (`source/DSCResources/DSC_<ResourceName>/`) — implement
  `Get-TargetResource`, `Test-TargetResource`, and `Set-TargetResource`
- **Class-based resources** (`source/Classes/<N>.<ClassName>.ps1`) — inherit `ResourceBase`
  from `DscResource.Base`; implement `GetCurrentState()` and `Modify()`
- Prefer class-based resources; use MOF-based only when required
  (e.g. WMF 4.0 support).

## File Organization

- Class-based resources: `source/Classes/<DependencyGroupNumber>.<ClassName>.ps1`
- MOF-based resources: `source/DSCResources/DSC_<ResourceName>/DSC_<ResourceName>.psm1`
- Resource enums: `source/Enum/<DependencyGroupNumber>.<EnumName>.ps1`
- Unit tests (MOF): `tests/Unit/DSC_<ResourceName>.Tests.ps1`
- Unit tests (class): `tests/Unit/Classes/<ClassName>.Tests.ps1`
- Integration tests: `tests/Integration/*.Tests.ps1` (class resources in `tests/Integration/Classes/`)
## Naming Conventions

- MOF-based resources: `DSC_<ResourceName>` prefix on all files and all exported
  functions (e.g. `DSC_TimeZone.psm1`; `Get-TargetResource` is exported via
  `*-TargetResource`).
- Class-based resources: PascalCase class name; file prefix
  `<DependencyGroupNumber>.<ClassName>.ps1` where the number is the dependency
  group (e.g. `020.PSResourceRepository.ps1`).

## Build & Test Workflow

- Never use VS Code tasks; always use PowerShell scripts via terminal from the
  repository root.
- Setup build and test environment (once per `pwsh` session):
  `./build.ps1 -Tasks noop`
- Build project before running tests: `./build.ps1 -Tasks build`
- Run all unit tests: `Invoke-Pester -Path 'tests/Unit' -Output Detailed`
- Run a specific MOF resource unit test:
  `Invoke-Pester -Path 'tests/Unit/DSC_<ResourceName>.Tests.ps1' -Output Detailed`
- Run a specific class resource unit test:
  `Invoke-Pester -Path 'tests/Unit/Classes/<ClassName>.Tests.ps1' -Output Detailed`
- Never run integration tests locally.
- Run unit tests in a new `pwsh` session after changing class-based resources.

## Instruction Files

Read the following instruction files before working on the corresponding areas:

- `.github/instructions/dsc-community-powershell.instructions.md` — PowerShell style
- `.github/instructions/dsc-community-pester.instructions.md` — Pester test style
- `.github/instructions/dsc-community-unit-tests.instructions.md` — unit test setup and patterns
- `.github/instructions/dsc-community-integration-tests.instructions.md` — integration test patterns
- `.github/instructions/dsc-community-mof-resource.instructions.md` — MOF resource implementation
- `.github/instructions/dsc-community-class-resource.instructions.md` — class-based resource implementation
- `.github/instructions/dsc-community-localization.instructions.md` — localized string conventions
- `.github/instructions/dsc-community-changelog.instructions.md` — changelog format
- `.github/instructions/dsc-community-markdown.instructions.md` — markdown style

## Key External References

- [DSC Community Guidelines](https://dsccommunity.org/guidelines/)
- [DSC Community Blog](https://dsccommunity.org/blog/)
- [DscResource.Common](https://github.com/dsccommunity/DscResource.Common)
- [DscResource.Base](https://github.com/dsccommunity/DscResource.Base)
- [DscResource.Test](https://github.com/dsccommunity/DscResource.Test)
