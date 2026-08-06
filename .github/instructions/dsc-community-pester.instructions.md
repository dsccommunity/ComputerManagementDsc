---
description: Guidelines for writing and maintaining tests using Pester.
applyTo: "**/*.[Tt]ests.ps1"
---

# Tests Guidelines

## Core Requirements
- All public commands, private functions and classes must have unit tests
- All public commands and class-based resources must have integration tests
- Use Pester v5 syntax only
- Test code only inside `Describe` blocks
- Assertions only in `It` blocks
- Never test verbose messages, debug messages or parameter binding behavior
- Pass all mandatory parameters to avoid prompts

## Requirements
- Inside `It` blocks, assign unused return objects to `$null` (unless part of pipeline)
- Tested entity must be called from within the `It` blocks
- Keep results and assertions in same `It` block
- Avoid try-catch-finally for cleanup, use `AfterAll` or `AfterEach`
- Avoid unnecessary remove/recreate cycles

## Naming
- One `Describe` block per file matching the tested entity name
- `Context` descriptions start with 'When'
- `It` descriptions start with 'Should', must not contain 'when'
- Mock variables prefix: 'mock'

## Structure & Scope
- Public commands: Never use `InModuleScope` (unless retrieving localized strings or creating an object using an internal class)
- Private functions/class resources: Always use `InModuleScope`
- Each class method = separate `Context` block
- Each scenario = separate `Context` block
- Use nested `Context` blocks for complex scenarios
- Mocking in `BeforeAll` (`BeforeEach` only when required)
- Setup/teardown in `BeforeAll`,`BeforeEach`/`AfterAll`,`AfterEach` close to usage
- Spacing between blocks, arrange, act, and assert for readability

## Syntax Rules
- PascalCase: `Describe`, `Context`, `It`, `Should`, `BeforeAll`, `BeforeEach`, `AfterAll`, `AfterEach`
- Use `-BeTrue`/`-BeFalse` never `-Be $true`/`-Be $false`/`-Contain $true`/`-Contain $false`
- Never use `Assert-MockCalled`, use `Should -Invoke` instead
- Never add an empty `-MockWith` block
- Omit `-MockWith` when returning `$null`
- Set `$PSDefaultParameterValues` for `Mock:ModuleName`, `Should:ModuleName`, `InModuleScope:ModuleName`
- Omit `-ModuleName` parameter on Pester commands
- Never use `Mock` inside `InModuleScope`-block
- Never use `param()`-block inside `-MockWith` scriptblocks, parameters are auto-bound
- In `InModuleScope` tests, add `Set-StrictMode -Version 1.0` immediately before invoking the tested function
- Use `Should -Invoke -Exactly -Times <n> -Scope It` for call-count assertions
  - Assert <n> calls inside the `It` block; do not assert call counts across an entire `Describe` or `Context`

## File Organization
- MOF resources: `tests/Unit/DSC_{ResourceName}.Tests.ps1`
- Class resources: `tests/Unit/Classes/{ClassName}.Tests.ps1`
- Common module tests: `tests/Unit/ComputerManagementDsc.Common.Tests.ps1`

## Data-Driven Tests (Test Cases)
- Define `-ForEach` variables in separate `BeforeDiscovery` (close to usage)
- `-ForEach` allowed on `Context` and `It` blocks
- Never add `param()` inside Pester blocks when using `-ForEach`
- Access test case properties directly: `$PropertyName`

## Best Practices
- Cover all scenarios and code paths
- Use `BeforeEach` and `AfterEach` sparingly
- Use `$PSDefaultParameterValues` only for Pester commands (`Describe`, `Context`, `It`, `Mock`, `Should`, `InModuleScope`)

## File Boilerplate

Every test file must begin with:

```powershell
# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()
```

## Describe Block Naming and Tags

- MOF resources: `'DSC_{ResourceName}\{FunctionName}'` with a tag matching the function:

  ```powershell
  Describe 'DSC_TimeZone\Get-TargetResource' -Tag 'Get' { ... }
  Describe 'DSC_TimeZone\Set-TargetResource' -Tag 'Set' { ... }
  Describe 'DSC_TimeZone\Test-TargetResource' -Tag 'Test' { ... }
  ```

- Class-based resources: `'{ClassName}\{MethodName}()'` with a matching tag:

  ```powershell
  Describe 'PSResourceRepository\GetCurrentState()' -Tag 'GetCurrentState' { ... }
  Describe 'PSResourceRepository\Modify()' -Tag 'Modify' { ... }
  Describe 'PSResourceRepository\AssertProperties()' -Tag 'AssertProperties' { ... }
  ```

- Standard tags: `Get`, `Set`, `Test`, `Modify`, `GetCurrentState`, `AssertProperties`,
  `Private`

## File Organization — DSC Resources

- MOF resource unit tests: `tests/Unit/DSC_{ResourceName}.Tests.ps1`
- Integration tests: `tests/Integration/DSC_{ResourceName}.Integration.Tests.ps1`
  (note `_Integration` suffix on the `Describe` block name as well)

## Class Resource Method Mocking

Class methods cannot be mocked with `Mock`. Use `Add-Member -MemberType ScriptMethod`:

```powershell
$mockInstance = [MyResource] @{ Name = 'Test' } |
    Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
        return [System.Collections.Hashtable] @{ Name = 'Test'; Ensure = 'Present' }
    } -PassThru |
    Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
        return
    } -PassThru
```

Methods commonly stubbed: `GetCurrentState`, `AssertProperties`, `Compare`, `Modify`.

## Script-Scoped Call Counter (Class Methods)

Since `Should -Invoke` cannot track class method calls, use a `$script:` counter:

```powershell
BeforeAll {
    InModuleScope -ScriptBlock {
        $script:mockInstance = [MyResource] @{ Name = 'Test' } |
            Add-Member -Force -MemberType 'ScriptMethod' -Name 'Modify' -Value {
                $script:mockMethodModifyCallCount += 1
            } -PassThru
    }
}

BeforeEach {
    InModuleScope -ScriptBlock {
        $script:mockMethodModifyCallCount = 0
    }
}

It 'Should call Modify() exactly once' {
    InModuleScope -ScriptBlock {
        $script:mockInstance.Set()
        $script:mockMethodModifyCallCount | Should -Be 1
    }
}
```

## `InModuleScope -Parameters $_` for Data-Driven Tests

When using `-TestCases` or `-ForEach`, pass parameters into `InModuleScope` with
`-Parameters $_`:

```powershell
It 'Should set the correct value for <Property>' -TestCases $testCases {
    InModuleScope -Parameters $_ -ScriptBlock {
        Set-StrictMode -Version 1.0
        { Set-TargetResource -Property $Property } | Should -Not -Throw
    }
}
```

## Cross-Module Mocking

To mock a function from a different module (e.g., a helper module), pass `-ModuleName`
explicitly on `Mock` even when `$PSDefaultParameterValues` is set:

```powershell
Mock -ModuleName 'ComputerManagementDsc.Common' -CommandName 'Get-TimeZoneId' -MockWith {
    return 'Pacific Standard Time'
}
```

## `ParameterFilter` with Catch-All

When mocking the same command for different parameter combinations, add a final catch-all
mock (no filter) that throws to detect unexpected calls:

```powershell
Mock -CommandName Get-RegistryPropertyValue `
    -ParameterFilter { $Name -eq 'FilterAdministratorToken' } `
    -MockWith { return 1 }

Mock -CommandName Get-RegistryPropertyValue `
    -MockWith { throw 'Called with unexpected parameter values.' }
```

## `BeforeDiscovery` Inside `Describe` for Test Cases

Define test case arrays in a `BeforeDiscovery` block inside the `Describe` block so they
are available during the discovery phase:

```powershell
Describe 'MyResource\Set()' -Tag 'Set' {
    BeforeDiscovery {
        $testCases = @(
            @{ Value = 'A'; Expected = 1 }
            @{ Value = 'B'; Expected = 2 }
        )
    }

    Context 'When value is <Value>' -ForEach $testCases {
        It 'Should return <Expected>' {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0
                # ...
            }
        }
    }
}
```
