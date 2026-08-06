---
description: Guidelines for writing and maintaining unit tests using Pester.
applyTo: "tests/[Uu]nit/**/*.[Tt]ests.ps1"
---

# Unit Tests Guidelines

- Test with localized strings: Use `InModuleScope -ScriptBlock { $script:localizedData.Key }`
- Mock files: Use `$TestDrive` variable (path to the test drive)
- All public commands require parameter set validation tests
- After modifying classes, always run tests in new session (for changes to take effect)

## Test Setup Requirements

Use this exact setup block before `Describe`:

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

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')
}
```

## Required Test Templates

### Parameter Set Validation
Single parameter set:
```powershell
It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
    @{
        ExpectedParameterSetName = '{ParameterSetName}' # e.g. __AllParameterSets
        ExpectedParameters = '[-Parameter1] <Type> [-Parameter2] <Type> [<CommonParameters>]'
    }
) {
    $result = (Get-Command -Name 'CommandName').ParameterSets |
        Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
        Select-Object -Property @(
            @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
            @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
        )
    $result.ParameterSetName | Should -Be $ExpectedParameterSetName
    $result.ParameterListAsString | Should -Be $ExpectedParameters
}
```

Multiple parameter sets: Use same pattern with multiple hashtables in `-ForEach` array.

### Parameter Properties
```powershell
It 'Should have ParameterName as a mandatory parameter' {
    $parameterInfo = (Get-Command -Name 'CommandName').Parameters['ParameterName']
    $parameterInfo.Attributes.Mandatory | Should -BeTrue
}
```

## DSC Resource Unit Test Setup

### MOF Resource `BeforeAll` / `AfterAll`

```powershell
BeforeAll {
    $script:dscModuleName   = 'ComputerManagementDsc'
    $script:dscResourceName = 'DSC_{ResourceName}'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName   $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType    'Mof' `
        -TestType        'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot `
        -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName']          = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName']        = $script:dscResourceName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force
    Get-Module -Name 'CommonTestHelper'       -All | Remove-Module -Force
}
```

### Class Resource `BeforeAll` / `AfterAll`

```powershell
BeforeAll {
    $script:dscModuleName = 'ComputerManagementDsc'

    Import-Module -Name $script:dscModuleName

    Import-Module -Name (Join-Path -Path $PSScriptRoot `
        -ChildPath '..\..\TestHelpers\CommonTestHelper.psm1')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName']          = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName']        = $script:dscModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
    Get-Module -Name 'CommonTestHelper'    -All | Remove-Module -Force
}
```

## Describe Block Naming, Tags, and `InModuleScope`

- Use `Set-StrictMode -Version 1.0` as the **first line inside every `InModuleScope`
  scriptblock**
- MOF resource `Describe` blocks: `'DSC_{ResourceName}\{FunctionName}'` with a tag:

  ```powershell
  Describe 'DSC_TimeZone\Get-TargetResource' -Tag 'Get' { ... }
  Describe 'DSC_TimeZone\Set-TargetResource' -Tag 'Set' { ... }
  Describe 'DSC_TimeZone\Test-TargetResource' -Tag 'Test' { ... }
  ```

- Class resource `Describe` blocks: `'{ClassName}\{MethodName}()'` with a tag:

  ```powershell
  Describe 'PSResourceRepository\GetCurrentState()' -Tag 'GetCurrentState' { ... }
  Describe 'PSResourceRepository\Modify()'          -Tag 'Modify' { ... }
  Describe 'PSResourceRepository\AssertProperties()' -Tag 'AssertProperties' { ... }
  ```

- Standard tags: `Get`, `Set`, `Test`, `Modify`, `GetCurrentState`, `AssertProperties`,
  `Private`

## Mock Assertions

Use `Should -Invoke` (Pester v5) for all mock call-count assertions:

```powershell
Should -Invoke -CommandName Set-TimeZoneId -Exactly -Times 1 -Scope It
Should -Invoke -CommandName Get-TimeZoneId -Exactly -Times 0 -Scope It
```

## `ParameterFilter` with Catch-All

When mocking the same command for different parameter values, add a final catch-all mock
(no filter) that throws to detect unexpected calls:

```powershell
Mock -CommandName Get-RegistryPropertyValue `
    -ParameterFilter { $Name -eq 'ConsentPromptBehaviorAdmin' } `
    -MockWith { return 2 }

Mock -CommandName Get-RegistryPropertyValue `
    -MockWith { throw 'Called with unexpected parameter values.' }
```

## Cross-Module Mocking

To mock a function from a module other than the one set in `$PSDefaultParameterValues`,
pass `-ModuleName` explicitly:

```powershell
Mock -ModuleName 'ComputerManagementDsc.Common' -CommandName 'Get-TimeZoneId' -MockWith {
    return 'Pacific Standard Time'
}
```

## Class Resource Method Mocking

Class methods cannot be mocked with `Mock`. Use `Add-Member -MemberType ScriptMethod`:

```powershell
BeforeAll {
    InModuleScope -ScriptBlock {
        Set-StrictMode -Version 1.0

        $script:mockInstance = [PSResourceRepository] @{ Name = 'PSGallery' } |
            Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                return [System.Collections.Hashtable] @{ Name = 'PSGallery'; Ensure = 'Present' }
            } -PassThru |
            Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                return
            } -PassThru
    }
}
```

## Script-Scoped Call Counter (Class Methods)

Since `Should -Invoke` cannot track class method calls, use a `$script:` counter:

```powershell
BeforeAll {
    InModuleScope -ScriptBlock {
        Set-StrictMode -Version 1.0

        $script:mockInstance = [PSResourceRepository] @{ Name = 'Test' } |
            Add-Member -Force -MemberType 'ScriptMethod' -Name 'Modify' -Value {
                $script:mockMethodModifyCallCount += 1
            } -PassThru
    }
}

BeforeEach {
    InModuleScope -ScriptBlock {
        Set-StrictMode -Version 1.0
        $script:mockMethodModifyCallCount = 0
    }
}

It 'Should call Modify() exactly once' {
    InModuleScope -ScriptBlock {
        Set-StrictMode -Version 1.0
        $script:mockInstance.Set()
        $script:mockMethodModifyCallCount | Should -Be 1
    }
}
```

## `InModuleScope -Parameters $_` for Data-Driven Tests

When using `-TestCases` or `-ForEach`, pass the test case parameters into `InModuleScope`:

```powershell
It 'Should set the correct value for <NotificationLevel>' -TestCases $testCases {
    InModuleScope -Parameters $_ -ScriptBlock {
        Set-StrictMode -Version 1.0
        { Set-UserAccountControlToNotificationLevel -NotificationLevel $NotificationLevel } |
            Should -Not -Throw
    }
}
```

## `BeforeDiscovery` Inside `Describe` for Test Cases

Define test case arrays inside `BeforeDiscovery` within the `Describe` block so they are
available during the discovery phase:

```powershell
Describe 'MyResource\Set-TargetResource' -Tag 'Set' {
    BeforeDiscovery {
        $testCases = @(
            @{ NotificationLevel = 'AlwaysNotify';   ConsentPromptBehaviorAdmin = 2 }
            @{ NotificationLevel = 'NotifyChanges';  ConsentPromptBehaviorAdmin = 5 }
        )
    }

    Context 'When notification level is <NotificationLevel>' -ForEach $testCases {
        It 'Should apply the correct registry value' {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0
                # ...
            }
        }
    }
}
```
