# tests/ — AI Agent Guide

## Test Framework

Use [Pester](https://pester.dev/) v5. Pester 4 syntax is forbidden.

### Pester 4 → 5 Key Changes

| Pester 4 | Pester 5 |
|----------|----------|
| `Assert-MockCalled` | `Should -Invoke` |
| `Should -Be $true` | `Should -BeTrue` |
| `Should -Be $false` | `Should -BeFalse` |
| Script-level test case variables | `BeforeDiscovery` block |
| `-ModuleName` on each call | `$PSDefaultParameterValues` with `Mock:ModuleName` etc. |

All Pester keywords (`Describe`, `Context`, `It`, `BeforeAll`, `AfterAll`, `BeforeEach`,
`AfterEach`) use PascalCase.

## Test Locations

| Type | Location |
|------|----------|
| MOF resource unit tests | `tests/Unit/DSC_<ResourceName>.Tests.ps1` |
| Class resource unit tests | `tests/Unit/Classes/<ClassName>.Tests.ps1` |
| Integration tests | `tests/Integration/` (MOF: one `.config.ps1` + one `*.Tests.ps1`; class-based: `tests/Integration/Classes/`) |
## Required Setup Block

### MOF Resource Unit Test

```powershell
# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies have been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
                # Redirect all streams to $null
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies have not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'ComputerManagementDsc'
    $script:dscResourceName = 'DSC_<ResourceName>'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force
}
```

### Class-based Resource Unit Test

```powershell
# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    # Same DscResource.Test bootstrap as MOF unit tests above
}

BeforeAll {
    $script:dscModuleName = 'ComputerManagementDsc'

    Import-Module -Name $script:dscModuleName

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\..\TestHelpers\CommonTestHelper.psm1')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force
}
```

### Integration Test

```powershell
# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    # Same DscResource.Test bootstrap as unit tests above

    $script:dscModuleName = 'ComputerManagementDsc'
    $script:dscResourceName = 'DSC_<ResourceName>'

    $script:skipIntegrationTests = $false
}

BeforeAll {
    $script:dscModuleName = 'ComputerManagementDsc'
    $script:dscResourceName = 'DSC_<ResourceName>'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Integration'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')
}

AfterAll {
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
```

## Running Tests

```powershell
# All unit tests (new pwsh session recommended after class-based resource changes)
Invoke-Pester -Path 'tests/Unit' -Output Detailed

# Specific MOF resource unit test
Invoke-Pester -Path 'tests/Unit/DSC_<ResourceName>.Tests.ps1' -Output Detailed

# Specific class resource unit test
Invoke-Pester -Path 'tests/Unit/Classes/<ClassName>.Tests.ps1' -Output Detailed
```

> **NEVER run integration tests locally.** Integration tests run only in CI and may change
> system state.
