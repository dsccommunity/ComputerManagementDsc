<#
    .SYNOPSIS
        Unit test for DSC_PowerPlan DSC resource.

    .NOTES
#>

# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
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
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
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
    $script:dscResourceName = 'DSC_PowerPlan'

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

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force
}

Describe 'DSC_PowerPlan\Get-TargetResource' -Tag 'Get' {
    BeforeDiscovery {
        $testCases = @(
            # Power plan as name specified
            @{
                Type = 'Name'
                Name = 'High performance'
            },

            # Power plan as Guid specified
            @{
                Type = 'Guid'
                Name = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
            }
        )
    }

    Context 'When the system is in the desired present state' {
        BeforeEach {
            Mock -CommandName Get-PowerPlan -MockWith {
                return @{
                    FriendlyName = 'High performance'
                    Guid         = [System.Guid]'8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
                }
            } -Verifiable

            Mock -CommandName Get-ActivePowerPlan -MockWith {
                return [System.Guid]'8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
            } -Verifiable
        }

        It 'Should return the same values as passed as parameters (power plan specified as <Type>)' -TestCases $testCases {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource -Name $Name -IsSingleInstance 'Yes'
                $result.IsSingleInstance | Should -Be 'Yes'
                $result.Name | Should -Be $Name
                $result.IsActive | Should -BeTrue
            }

            Should -InvokeVerifiable
        }
    }

    Context 'When the system is not in the desired present state' {
        BeforeEach {
            Mock -CommandName Get-PowerPlan -MockWith {
                return @{
                    FriendlyName = 'High performance'
                    Guid         = [System.Guid]'8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
                }
            } -Verifiable

            Mock -CommandName Get-ActivePowerPlan -MockWith {
                return [System.Guid]'381b4222-f694-41f0-9685-ff5bb260df2e'
            } -Verifiable
        }

        It 'Should return an inactive plan (power plan specified as <Type>)' -TestCases $testCases {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource -Name $Name -IsSingleInstance 'Yes'
                $result.IsSingleInstance | Should -Be 'Yes'
                $result.Name | Should -Be $Name
                $result.IsActive | Should -BeFalse
            }

            Should -InvokeVerifiable
        }
    }

    Context 'When the preferred plan does not exist' {
        BeforeEach {
            Mock -CommandName Get-PowerPlan -Verifiable
        }

        It 'Should throw the expected error (power plan specified as <Type>)' -TestCases $testCases {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.PowerPlanNotFound -f $Name)

                { Get-TargetResource -Name $Name -IsSingleInstance 'Yes' } | Should -Throw $errorRecord
            }

            Should -InvokeVerifiable
        }

    }
}

Describe 'DSC_PowerPlan\Set-TargetReource' -Tag 'Set' {
    BeforeDiscovery {
        $testCases = @(
            # Power plan as name specified
            @{
                Type = 'Name'
                Name = 'High performance'
            },

            # Power plan as Guid specified
            @{
                Type = 'Guid'
                Name = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
            }
        )
    }

    BeforeEach {
        Mock -CommandName Get-PowerPlan -MockWith {
            return @{
                FriendlyName = 'High performance'
                Guid         = [System.Guid]'8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
            }
        } -Verifiable

        Mock -CommandName Set-ActivePowerPlan -Verifiable
    }

    Context 'When the system is not in the desired present state' {
        It 'Should call Get-PowerPlan once (power plan specified as <Type>)' -TestCases $testCases {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource -Name $Name -IsSingleInstance 'Yes'
            }

            Should -Invoke -CommandName Get-PowerPlan -Exactly -Times 1 -Scope It
        }

        It 'Should call Set-ActivePowerPlan once (power plan specified as <Type>)' -TestCases $testCases {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource -Name $Name -IsSingleInstance 'Yes'
            }

            Should -Invoke -CommandName Set-ActivePowerPlan -ParameterFilter {
                $PowerPlanGuid -eq '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the preferred plan does not exist' {
        BeforeEach {
            Mock -CommandName Get-PowerPlan
        }

        It 'Should throw the expected error (power plan specified as <Type>)' -TestCases $testCases {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.PowerPlanNotFound -f $Name)

                { Set-TargetResource -Name $Name -IsSingleInstance 'Yes' } | Should -Throw -ExpectedMessage $errorRecord
            }

            Should -Invoke -CommandName Get-PowerPlan -Exactly -Times 1 -Scope It
        }
    }

}

Describe 'DSC_PowerPlan\Test-TargetResource' -Tag 'Test' {
    BeforeDiscovery {
        $testCases = @(
            # Power plan as name specified
            @{
                Type = 'Name'
                Name = 'High performance'
            },

            # Power plan as Guid specified
            @{
                Type = 'Guid'
                Name = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
            }
        )
    }

    Context 'When the system is in the desired present state' {
        BeforeEach {
            Mock -CommandName Get-PowerPlan -MockWith {
                return @{
                    FriendlyName = 'High performance'
                    Guid         = [System.Guid]'8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
                }
            } -Verifiable

            Mock -CommandName Get-ActivePowerPlan -MockWith {
                return [System.Guid]'8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
            } -Verifiable
        }


        It 'Should return the the state as present ($true) (power plan specified as <Type>)' -TestCases $testCases {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource -Name $Name -IsSingleInstance 'Yes'  | Should -BeTrue
            }

            Should -InvokeVerifiable
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeEach {
            Mock -CommandName Get-PowerPlan -MockWith {
                return @{
                    FriendlyName = 'High performance'
                    Guid         = [System.Guid]'8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
                }
            } -Verifiable

            Mock -CommandName Get-ActivePowerPlan -MockWith {
                return [System.Guid]'381b4222-f694-41f0-9685-ff5bb260df2e'
            } -Verifiable
        }

        It 'Should return the the state as absent ($false) (power plan specified as <Type>)' -TestCases $testCases {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource -Name $Name -IsSingleInstance 'Yes'  | Should -BeFalse
            }

            Should -InvokeVerifiable
        }
    }

}
