---
description: Guidelines for implementing localization.
applyTo: "source/**/*.{ps1,psm1}"
version: 1.0.0
---

# Localization Guidelines

## Requirements

- Localize all `Write-Debug`, `Write-Verbose`, `Write-Error`, `Write-Warning`, and
  `$PSCmdlet.ThrowTerminatingError()` messages; never use hardcoded strings
- Assume `$script:localizedData` is available

## String Files

- MOF-based resources:
  `source/DSCResources/DSC_<ResourceName>/en-US/DSC_<ResourceName>.strings.psd1`
- Class-based resources: `source/en-US/<ClassName>.strings.psd1`
- Module-level strings: `source/en-US/<ModuleName>.strings.psd1`

## Key Naming Patterns

- Format: `Verb_FunctionName_Action` (underscore separators),
  e.g. `Get_TimeZone_GettingCurrentState`

## String Format

```powershell
ConvertFrom-StringData @'
    KeyName = Message with {0} placeholder. (PREFIX0001)
'@
```

## String IDs

- Format: `(PREFIX####)`
- PREFIX: First letter of each word in class or function name
  (e.g. `Get-TargetResource` for `DSC_TimeZone` → `GTR`, `PSResourceRepository` → `PRR`)
- Number: Sequential from 0001

## Usage

```powershell
Write-Verbose -Message ($script:localizedData.KeyName -f $value1)
```

## Loading Mechanism by Resource Type

### MOF-based resources

At module scope, after importing `DscResource.Common`:

```powershell
$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'
```

Access strings as `$script:localizedData.KeyName`.

### Class-based resources

Pass `$PSScriptRoot` to the `ResourceBase` base constructor in the class constructor:

```powershell
MyResourceName () : base ($PSScriptRoot)
{
    ...
}
```

The `ResourceBase` class loads the strings automatically.
Access strings as `$this.localizedData.KeyName` — **not** `$script:localizedData`:

```powershell
Write-Verbose -Message ($this.localizedData.GetTargetResourceMessage -f $this.Name)
```

## Error Messages

Pass localized error strings to `DscResource.Common` exception helpers rather than calling
`$PSCmdlet.ThrowTerminatingError()` directly:

```powershell
$errorMessage = $script:localizedData.SomeErrorKey -f $value
New-InvalidOperationException -Message $errorMessage
New-ArgumentException -ArgumentName 'ParameterName' -Message $errorMessage
```

## String File Header

Optionally include `# culture="en-US"` as the first line of a `.strings.psd1` file:

```powershell
# culture="en-US"
ConvertFrom-StringData -StringData @'
    KeyName = Message text. (PREFIX0001)
'@
```
