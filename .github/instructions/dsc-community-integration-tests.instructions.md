---
description: Guidelines for implementing integration tests.
applyTo: "tests/[iI]ntegration/**/*.[Tt]ests.ps1"
---

# Integration Tests Guidelines

## Requirements
- Location (MOF resources): `tests/Integration/DSC_<ResourceName>*.Tests.ps1` (plus a companion `.config.ps1`)
- Location (class resources): `tests/Integration/Classes/<ClassName>*.Tests.ps1`
- No mocking - real environment only
- Cover all scenarios and code paths
- Use `Get-ComputerName` for computer names in CI
- Avoid `ExpectedMessage` for `Should -Throw` assertions
- Only run integration tests in CI unless explicitly instructed.
- Call commands with `-Force` parameter where applicable (avoids prompting).
- Use `-ErrorAction 'Stop'` on commands so failures surface immediately

## Required Setup Block

```powershell
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies have been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies have not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks noop" first.'
    }
}

BeforeAll {
    $script:moduleName = '{MyModuleName}'

    Import-Module -Name $script:moduleName -ErrorAction 'Stop'
}
```

## DSC Resource Test Variables

Define these variables in **both** `BeforeDiscovery` (for discovery-phase use) and `BeforeAll`
(for runtime use):

```powershell
$script:dscModuleName   = 'ComputerManagementDsc'
$script:dscResourceName = 'DSC_{ResourceName}'   # for MOF resources
$script:skipIntegrationTests = $false
```

## Required Test Environment Setup (MOF Resources)

```powershell
BeforeAll {
    $script:dscModuleName   = 'ComputerManagementDsc'
    $script:dscResourceName = 'DSC_{ResourceName}'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName  $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType   'Mof' `
        -TestType       'Integration'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')
}

AfterAll {
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
```

## Config File Pattern

- Name the companion config file `{DSC_ResourceName}.config.ps1` (or `.Config.ps1`)
- Dot-source it in the `Describe BeforeAll`:

  ```powershell
  $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
  . $configFile -Verbose -ErrorAction Stop
  ```

## Configuration Naming Convention

Configuration functions must follow the pattern `DSC_{ResourceName}_{Purpose}_Config`:

```powershell
Configuration DSC_TimeZone_SetTimeZone_Config { ... }
Configuration DSC_SmbShare_CreateShare1_Config { ... }
Configuration DSC_SmbShare_Cleanup_Config { ... }
```

## Prerequisites and Cleanup Configurations

When a test requires external state (users, folders, shares, registry keys), define:

- A `_Prerequisites_Config` configuration at the start of the test suite
- A `_Cleanup_Config` configuration at the end of the test suite

## Standard Test Sequence

Each configuration `Context` block must contain these `It` tests in order:

1. `'Should compile the MOF without throwing'` — compile with `$TestDrive` as output:

   ```powershell
   & $configName -OutputPath $TestDrive -ConfigurationData $configData
   ```

2. `'Should apply the MOF without throwing'` — reset LCM then start configuration:

   ```powershell
   Reset-DscLcm
   Start-DscConfiguration -Path $TestDrive -ComputerName 'localhost' -Wait -Verbose -Force -ErrorAction Stop
   ```

3. `'Should be able to call Get-DscConfiguration without throwing'`:

   ```powershell
   Get-DscConfiguration -Verbose -ErrorAction Stop
   ```

4. `'Should have set the resource and all the parameters should match'` — property assertions

5. *(optional)* `'Should return $true when Test-DscConfiguration is run'`:

   ```powershell
   Test-DscConfiguration -Verbose | Should -BeTrue
   ```

## Key Rules

- Always call `Reset-DscLcm` immediately before `Start-DscConfiguration`
- Use `$TestDrive` as the `-OutputPath` when compiling MOF configurations
- Use `'localhost'` as `ComputerName` in `Start-DscConfiguration`
