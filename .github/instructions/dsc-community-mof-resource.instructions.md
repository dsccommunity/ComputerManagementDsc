---
description: Guidelines for implementing MOF DSC resources.
applyTo: "source/DSCResources/**/*.psm1"
version: 1.0.0
---

# MOF-based Desired State Configuration (DSC) Resources Guidelines

## Required Functions

- Define: `Get-TargetResource`, `Set-TargetResource`, `Test-TargetResource`
- Export using `*-TargetResource` pattern

## Function Return Types

- `Get-TargetResource`: Must return hashtable with all resource properties
- `Test-TargetResource`: Must return boolean (`$true`/`$false`)
- `Set-TargetResource`: Must not return anything (void)

## Parameter Guidelines

- `Get-TargetResource`: Only include parameters needed to retrieve actual current state values
- `Get-TargetResource`: Remove non-mandatory parameters that are never used
- `Set-TargetResource` and `Test-TargetResource`: Must have identical parameters
- `Set-TargetResource` and `Test-TargetResource`: Unused mandatory parameters: Add
  "Not used in `<function_name>`" to help comment

## Required Elements

- Each function must include `Write-Verbose` at least once
  - `Get-TargetResource`: Use verbose message starting with "Getting the current state of..."
  - `Set-TargetResource`: Use verbose message starting with "Setting the desired state of..."
  - `Test-TargetResource`: Use verbose message starting with
    "Determining the current state of..."
- Use localized strings for all messages (`Write-Verbose`, `Write-Error`, etc.)
- Import localized strings using `Get-LocalizedData` at module top

## Error Handling for MOF-based Resources

- Use `try/catch` blocks to handle exceptions
- Do not use `throw` for terminating errors; use `New-*Exception` commands:
  - [`New-InvalidDataException`](https://github.com/dsccommunity/DscResource.Common/wiki/New%E2%80%91InvalidDataException)
  - [`New-ArgumentException`](https://github.com/dsccommunity/DscResource.Common/wiki/New%E2%80%91ArgumentException)
  - [`New-InvalidOperationException`](https://github.com/dsccommunity/DscResource.Common/wiki/New%E2%80%91InvalidOperationException)
  - [`New-ObjectNotFoundException`](https://github.com/dsccommunity/DscResource.Common/wiki/New%E2%80%91ObjectNotFoundException)
  - [`New-InvalidResultException`](https://github.com/dsccommunity/DscResource.Common/wiki/New%E2%80%91InvalidResultException)
  - [`New-NotImplementedException`](https://github.com/dsccommunity/DscResource.Common/wiki/New%E2%80%91NotImplementedException)

# MOF Resource Localization

## File Structure

- Create `en-US` folder in each resource directory
- Name strings file: `DSC_<ResourceName>.strings.psd1`
- Use names returned from `Get-UICulture` for additional language folder names

## String File Format

- In `.strings.psd1` files, use underscores as word separators in localized string key
  names (for multi-word keys)

## Function Requirements

- All three functions must include `[CmdletBinding()]`
- `Get-TargetResource` must declare `[OutputType([System.Collections.Hashtable])]`
- `Test-TargetResource` must declare `[OutputType([System.Boolean])]`
- `Set-TargetResource` omits `[OutputType()]`

## Module Import Boilerplate

At the top of every `.psm1`, import the required helper modules before loading localized data:

```powershell
$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) `
    -ChildPath 'Modules'

Import-Module -Name (Join-Path -Path $modulePath `
    -ChildPath (Join-Path -Path 'ComputerManagementDsc.Common' `
        -ChildPath 'ComputerManagementDsc.Common.psm1'))

Import-Module -Name (Join-Path -Path $modulePath -ChildPath 'DscResource.Common')

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'
```

## Script-Scoped Module Variables

Define constants and shared lookup tables at module scope using `$script:` prefix:

```powershell
$script:registryKey = 'HKLM:\SOFTWARE\...'
$script:parameterNames = @('Param1', 'Param2')
```

## Reboot Signalling (`$global:DSCMachineStatus`)

When a resource must signal that a reboot is required, use the pattern below. Include a
`SuppressRestart` parameter to allow callers to suppress the reboot signal.
Suppress the PSScriptAnalyzer warning at module top:

```powershell
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '',
    Justification = 'DSC requires $global:DSCMachineStatus to signal a reboot.')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '',
    Justification = 'Script Analyzer does not understand Pester syntax.')]
param ()

# ...inside Set-TargetResource:
if (-not $SuppressRestart)
{
    $global:DSCMachineStatus = 1
}
```

## Private Helper Functions

Resource-specific helper functions may be defined in the `.psm1` file below the three
required functions. Extract logic to `ComputerManagementDsc.Common` only when it is
needed by multiple resources.

## Preferred Comparison Helper

Use `Test-DscParameterState` from `DscResource.Common` as the preferred mechanism for
comparing current vs. desired state in `Test-TargetResource`.

## Mutual Exclusivity Validation

Use `Assert-BoundParameter` from `DscResource.Common` to validate mutually exclusive
parameter combinations in `Set-TargetResource` and `Test-TargetResource`.

## Schema (.schema.mof) Structure

Every MOF resource requires a `.schema.mof` file in the same directory:

- Declare `ClassVersion` and `FriendlyName` in the class qualifier line
- Inherit from `OMI_BaseResource`
- Qualifier types:
  - `[Key]` — key (identity) property
  - `[Required]` — mandatory input property
  - `[Write]` — optional input property
  - `[Read]` — output-only / computed property

```mof
[ClassVersion("1.0.0"), FriendlyName("TimeZone")]
class DSC_TimeZone : OMI_BaseResource
{
    [Key, Description("Specifies the resource is a single instance.")] String IsSingleInstance;
    [Required, Description("The desired time zone.")] String TimeZone;
};
```
