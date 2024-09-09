<#
    .SYNOPSIS
        Unit test for DSC_PowershellExecutionPolicy DSC resource.

    .NOTES
#>

# Suppressing this rule because script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSscriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
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
    $script:dscResourceName = 'DSC_PowershellExecutionPolicy'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSscriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force
}

Describe 'DSC_PowershellExecutionPolicy\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $script:invalidPolicyThrowMessage = "Cannot validate argument on parameter 'ExecutionPolicy'. The argument `"badParam`" does not belong to the set `"Bypass,Restricted,AllSigned,RemoteSigned,Unrestricted`" specified by the ValidateSet attribute. Supply an argument that is in the set and then try the command again."
            $script:invalidPolicyExecutionPolicyScopeThrowMessage = "Cannot validate argument on parameter 'ExecutionPolicyScope'. The argument `"badParam`" does not belong to the set `"CurrentUser,LocalMachine,MachinePolicy,Process,UserPolicy`" specified by the ValidateSet attribute. Supply an argument that is in the set and then try the command again."
        }
    }

    Context 'When passed an invalid execution policy' {
        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Get-TargetResource -ExecutionPolicy 'badParam' -Scope 'LocalMachine' } |
                    Should -Throw -ExpectedMessage $script:invalidPolicyThrowMessage
            }
        }
    }

    Context 'When passed a valid execution policy' {
        BeforeAll {
            Mock -CommandName Get-ExecutionPolicy -MockWith { 'Unrestricted' }
        }

        It 'Should return the correct execution policy' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource -ExecutionPolicy $(Get-ExecutionPolicy) -ExecutionPolicyScope 'LocalMachine'
                $result.ExecutionPolicy | Should -Be $(Get-ExecutionPolicy)
            }
        }
    }

    Context 'When passed an invalid execution policy ExecutionPolicyScope' {
        It 'Should throws an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Get-TargetResource -ExecutionPolicy $(Get-ExecutionPolicy) -ExecutionPolicyScope 'badParam' } |
                    Should -Throw -ExpectedMessage $script:invalidPolicyExecutionPolicyScopeThrowMessage
            }
        }
    }

    Context 'When passed a valid execution policy ExecutionPolicyScope' {
        It 'Should return the correct execution policy' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource -ExecutionPolicy $(Get-ExecutionPolicy -Scope  'LocalMachine') -ExecutionPolicyScope  'LocalMachine'
                $result.ExecutionPolicy | Should -Be $(Get-ExecutionPolicy -Scope 'LocalMachine')
                $result.ExecutionPolicyScope | Should -Be 'LocalMachine'
            }
        }
    }
}

Describe 'DSC_PowershellExecutionPolicy\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $script:invalidPolicyThrowMessage = "Cannot validate argument on parameter 'ExecutionPolicy'. The argument `"badParam`" does not belong to the set `"Bypass,Restricted,AllSigned,RemoteSigned,Unrestricted`" specified by the ValidateSet attribute. Supply an argument that is in the set and then try the command again."
            $script:invalidPolicyExecutionPolicyScopeThrowMessage = "Cannot validate argument on parameter 'ExecutionPolicyScope'. The argument `"badParam`" does not belong to the set `"CurrentUser,LocalMachine,MachinePolicy,Process,UserPolicy`" specified by the ValidateSet attribute. Supply an argument that is in the set and then try the command again."
        }
    }

    Context 'When passed an invalid execution policy' {
        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Test-TargetResource -ExecutionPolicy 'badParam' -Scope 'LocalMachine' } |
                    Should -Throw $script:invalidPolicyThrowMessage
            }
        }
    }

    Context 'When current policy matches desired policy' {
        BeforeAll {
            Mock Get-ExecutionPolicy { 'Unrestricted' }
        }

        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource -ExecutionPolicy $(Get-ExecutionPolicy) -ExecutionPolicyScope 'LocalMachine' | Should -BeTrue
            }
        }
    }

    Context 'When current policy does not match desired policy' {
        BeforeAll {
            Mock -CommandName Get-ExecutionPolicy -MockWith { 'Restricted' }
        }

        It 'Should return $false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource -ExecutionPolicy 'Bypass' -ExecutionPolicyScope 'LocalMachine' | Should -BeFalse
            }
        }
    }

    Context 'When passed an invalid execution policy Scope' {
        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Test-TargetResource -ExecutionPolicy 'badParam' } | Should -Throw $script:invalidPolicyThrowMessage
            }
        }
    }

    Context 'When current policy matches desired policy with correct Scope' {
        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource -ExecutionPolicy $(Get-ExecutionPolicy)  -ExecutionPolicyScope 'LocalMachine' | Should -BeTrue
            }
        }
    }

    Context 'When current policy does not match desired policy with correct ExecutionPolicyScope' {
        BeforeAll {
            Mock -CommandName Get-ExecutionPolicy -MockWith { 'Restricted' }
        }

        It 'Should return $false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource -ExecutionPolicy 'Bypass' -ExecutionPolicyScope 'LocalMachine' | Should -BeFalse
            }
        }
    }
}

Describe 'DSC_PowershellExecutionPolicy\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $script:invalidPolicyThrowMessage = "Cannot validate argument on parameter 'ExecutionPolicy'. The argument `"badParam`" does not belong to the set `"Bypass,Restricted,AllSigned,RemoteSigned,Unrestricted`" specified by the ValidateSet attribute. Supply an argument that is in the set and then try the command again."
            $script:invalidScopeThrowMessage = "Cannot validate argument on parameter 'ExecutionPolicy'. The argument `"LocalMachine`" does not belong to the set `"Bypass,Restricted,AllSigned,RemoteSigned,Unrestricted`" specified by the ValidateSet attribute. Supply an argument that is in the set and then try the command again."
        }
    }

    Context 'When passed an invalid execution policy' {
        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource -ExecutionPolicy 'badParam' -Scope 'LocalMachine' } | Should -Throw $script:invalidPolicyThrowMessage
            }
        }
    }

    Context 'When passed an invalid scope level' {
        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource -ExecutionPolicy 'LocalMachine' -ExecutionPolicyScope 'badParam' } | Should -Throw $script:invalidScopeThrowMessage
            }
        }
    }

    Context 'When Set-ExecutionPolicy throws ExecutionPolicyOverride' {
        BeforeAll {
            Mock -CommandName Set-ExecutionPolicy -MockWith { throw 'ExecutionPolicyOverride,Microsoft.PowerShell.Commands.SetExecutionPolicyCommand' }
        }

        It 'Catches execution policy scope warning exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Set-TargetResource -ExecutionPolicy 'Bypass' -ExecutionPolicyScope 'LocalMachine'
                $result | Should -Be $null
            }
        }
    }

    Context 'When setting Set-ExecutionPolicy throws an error' {
        BeforeAll {
            Mock -CommandName Set-ExecutionPolicy -MockWith { throw 'Throw me!' }
        }

        It 'Should throw a non-caught exceptions' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource -ExecutionPolicy 'Bypass' -ExecutionPolicyScope 'LocalMachine' } | Should -Throw 'Throw me!'
            }
        }
    }

    Context 'When execution policy is set in specified Scope' {
        BeforeAll {
            Mock -CommandName Set-ExecutionPolicy
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource -ExecutionPolicy 'Bypass' -ExecutionPolicyScope 'LocalMachine'
            }

            Should -Invoke -CommandName Set-ExecutionPolicy -Exactly 1 -Scope It
        }
    }
}
