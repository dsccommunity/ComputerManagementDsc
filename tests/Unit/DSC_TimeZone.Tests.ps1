<#
    .SYNOPSIS
        Unit test for DSC_TimeZone DSC resource.

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
    $script:dscResourceName = 'DSC_TimeZone'

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

Describe 'DSC_TimeZone MOF single instance schema' {
    It 'Should have mandatory IsSingleInstance parameter and one other parameter' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $timeZoneResource = Get-DscResource -Name TimeZone

            $timeZoneResource.Properties.Where{
                $_.Name -eq 'IsSingleInstance'
            }.IsMandatory | Should -BeTrue

            $timeZoneResource.Properties.Where{
                $_.Name -eq 'IsSingleInstance'
            }.Values[0] | Should -Be 'Yes'
        }
    }
}

Describe 'DSC_TimeZone\Get-TargetResource' -Tag 'Get' {
    Context 'When the system is in the desired state' {
        BeforeAll {
            Mock -CommandName Get-TimeZoneId -MockWith { 'Pacific Standard Time' }
        }

        It 'Should return hashtable with Value that matches ''Pacific Standard Time''' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getTargetParams = @{
                    TimeZone         = 'Pacific Standard Time'
                    IsSingleInstance = 'Yes'
                }

                $timeZone = Get-TargetResource @getTargetParams

                $timeZone.TimeZone | Should -Be 'Pacific Standard Time'
            }
        }
    }
}

Describe 'DSC_TimeZone\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        Mock -CommandName Set-TimeZoneId

        Mock -CommandName Get-TimeZoneId -MockWith {
            'Eastern Standard Time'
        }
    }

    Context 'When the system is not in the desired state' {
        It 'Should Call Set-TimeZoneId' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    TimeZone         = 'Pacific Standard Time'
                    IsSingleInstance = 'Yes'
                }

                Set-TargetResource @setTargetResourceParameters
            }

            Should -Invoke -CommandName Set-TimeZoneId -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the system is in the desired state' {
        It 'Should not call Set-TimeZoneId' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    TimeZone         = 'Eastern Standard Time'
                    IsSingleInstance = 'Yes'
                }

                Set-TargetResource @setTargetResourceParameters
            }

            Should -Invoke -CommandName Set-TimeZoneId -Exactly -Times 0 -Scope It
        }
    }
}

Describe 'DSC_TimeZone\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        Mock -ModuleName ComputerManagementDsc.Common -CommandName Get-TimeZoneId -MockWith {
            'Pacific Standard Time'
        }
    }

    Context 'When the system is in the desired state' {
        It 'Should return true when Test is passed Time Zone thats already set' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = @{
                    TimeZone         = 'Pacific Standard Time'
                    IsSingleInstance = 'Yes'
                }

                Test-TargetResource @testTargetResourceParameters | Should -BeTrue
            }
        }
    }

    Context 'When the system is not in the desired state' {

        It 'Should return false when Test is passed Time Zone that is not set' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = @{
                    TimeZone         = 'Eastern Standard Time'
                    IsSingleInstance = 'Yes'
                }

                Test-TargetResource @testTargetResourceParameters | Should -BeFalse
            }
        }
    }
}
