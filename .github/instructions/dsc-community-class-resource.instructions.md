---
description: Guidelines for implementing Desired State Configuration (DSC) class-based resources.
applyTo: "source/[cC]lasses/**/*.ps1"
version: 1.0.0
---

# DSC Class-Based Resource Guidelines

**Applies to:** Classes with `[DscResource(...)]` decoration only.

## Requirements

- File: `source/Classes/<N>.<ClassName>.ps1`
- Decoration: `[DscResource(RunAsCredential = 'Optional')]` (use `'Mandatory'` if required)
- Inherit `ResourceBase` (DscResource.Base)
- `$this.localizedData` auto-populated by `ResourceBase` from localization file
- Value-type properties: use `[Nullable[{FullTypeName}]]` (e.g. `[Nullable[System.Int32]]`)

## Required Constructor

```powershell
MyResourceName () : base ($PSScriptRoot)
{
    # Property names where state cannot be enforced, e.g. IsSingleInstance, Force
    $this.ExcludeDscProperties = @()
}
```

## Required Method Pattern

```powershell
[MyResourceName] Get()
{
    # Call base implementation to get current state
    $currentState = ([ResourceBase] $this).Get()

    # If needed, post-processing on current state that cannot be handled by GetCurrentState()

    return $currentState
}

[System.Boolean] Test()
{
    # Call base implementation to test current state
    $inDesiredState = ([ResourceBase] $this).Test()

    # If needed, post-processing on test result that cannot be handled by base Test()

    return $inDesiredState
}

[void] Set()
{
    # Call base implementation to set desired state
    ([ResourceBase] $this).Set()

    # If needed, additional state changes that cannot be handled by Modify()
}

hidden [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $properties)
{
    # Always return current state as hashtable; $properties contains key properties
}

hidden [void] Modify([System.Collections.Hashtable] $properties)
{
    # Always set desired state; $properties contains those that must change state
}
```

## Optional Method Pattern

```powershell
hidden [void] AssertProperties([System.Collections.Hashtable] $properties)
{
    # Validate user-provided properties; $properties contains user-assigned values
}

hidden [void] NormalizeProperties([System.Collections.Hashtable] $properties)
{
    # Normalize user-provided properties; $properties contains user-assigned values
}
```

## Required Comment-based Help

Add to `.DESCRIPTION` section:

- `## Requirements`: List minimum requirements
- `## Known issues`: Critical issues + pattern:
  `All issues are not listed here, see [all open issues](https://github.com/dsccommunity/ComputerManagementDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+{ResourceName}).`

## Error Handling for Classes

- Use `try/catch` blocks to handle exceptions
- Do not use `throw` for terminating errors; use `New-*Exception` commands:
  - [`New-InvalidDataException`](https://github.com/dsccommunity/DscResource.Common/wiki/New%E2%80%91InvalidDataException)
  - [`New-ArgumentException`](https://github.com/dsccommunity/DscResource.Common/wiki/New%E2%80%91ArgumentException)
  - [`New-InvalidOperationException`](https://github.com/dsccommunity/DscResource.Common/wiki/New%E2%80%91InvalidOperationException)
  - [`New-ObjectNotFoundException`](https://github.com/dsccommunity/DscResource.Common/wiki/New%E2%80%91ObjectNotFoundException)
  - [`New-InvalidResultException`](https://github.com/dsccommunity/DscResource.Common/wiki/New%E2%80%91InvalidResultException)
  - [`New-NotImplementedException`](https://github.com/dsccommunity/DscResource.Common/wiki/New%E2%80%91NotImplementedException)

## Property Attributes

- `[DscProperty(Key)]` — key (identity) properties; always mark at least one per resource
- `[DscProperty(Mandatory)]` — required (non-key) properties
- `[DscProperty()]` — optional properties
- `[DscProperty(NotConfigurable)]` — read-only / computed properties not configurable by the
  user (e.g. `Reasons`)
- `[ValidateSet('Value1', 'Value2')]` — restrict allowed values on string properties
- For Enum-typed properties, set a default value:

  ```powershell
  [DscProperty()]
  [Ensure]
  $Ensure = [Ensure]::Present
  ```

## Machine Configuration Compliance (`Reasons`)

Resources that support Azure Policy / Machine Configuration compliance auditing must include
a `Reasons` property using the `CMReason` helper class:

```powershell
[DscProperty(NotConfigurable)]
[CMReason[]]
$Reasons
```

## Class-Level Comment-Based Help

Place a comment block **above** the `[DscResource()]` decoration with:

- `.SYNOPSIS` — one-line description of the resource
- `.PARAMETER` — one entry per DSC property (name + description)
- `.EXAMPLE` — at least one `Invoke-DscResource` usage example

```powershell
<#
    .SYNOPSIS
        A resource to manage...

    .PARAMETER Ensure
        Specifies whether the resource should be Present or Absent.

    .PARAMETER Name
        Specifies the name.

    .EXAMPLE
        Invoke-DscResource -Name 'MyResource' -ModuleName 'MyModule' -Method 'Get' -Property @{
            Name   = 'Value'
            Ensure = 'Present'
        }
#>
[DscResource()]
class MyResource : ResourceBase
```

## Localized Data in Class Resources

- Strings are loaded automatically by `ResourceBase` when passing `$PSScriptRoot` to the
  base constructor: `MyResource () : base ($PSScriptRoot)`
- Access localized strings via `$this.localizedData.KeyName` (not `$script:localizedData`)

  ```powershell
  Write-Verbose -Message ($this.localizedData.GetTargetResourceMessage -f $this.Name)
  ```
