<#
    .SYNOPSIS
        Unit test for DSC_SystemLocale DSC resource.

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
    $script:dscResourceName = 'DSC_SystemLocale'

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

Describe 'DSC_SystemLocale\Get-TargetResource' -Tag 'Get' {
    Context 'When the system is in the desired state' {
        BeforeAll {
            Mock -CommandName Get-WinSystemLocale -MockWith {
                @{
                    LCID        = '1033'
                    Name        = 'en-US'
                    DisplayName = 'English (United States)'
                }
            }
        }
        It 'Should return hashtable with Value that matches ''en-US''' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getTargetParams = @{
                    SystemLocale     = 'en-US'
                    IsSingleInstance = 'Yes'
                }

                $systemLocale = Get-TargetResource @getTargetParams

                $systemLocale.SystemLocale | Should -Be 'en-US'
            }
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            Mock -CommandName Get-WinSystemLocale -MockWith {
                @{
                    LCID        = '1033'
                    Name        = 'en-AU'
                    DisplayName = 'English (United States)'
                }
            }
        }
        It 'Should return hashtable with Value that matches ''en-AU''' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getTargetParams = @{
                    SystemLocale     = 'en-US'
                    IsSingleInstance = 'Yes'
                }

                $systemLocale = Get-TargetResource @getTargetParams

                $systemLocale.SystemLocale | Should -Be 'en-AU'
            }
        }
    }
}

Describe 'DSC_SystemLocale\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        Mock -CommandName Get-WinSystemLocale -MockWith {
            @{
                LCID        = '1033'
                Name        = 'en-US'
                DisplayName = 'English (United States)'
            }
        }

        Mock -CommandName Set-WinSystemLocale
    }

    Context 'When the system is in the desired state' {
        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetParams = @{
                    SystemLocale     = 'en-US'
                    IsSingleInstance = 'Yes'
                }

                { Set-TargetResource @setTargetParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Set-WinSystemLocale -Exactly -Times 0 -Scope It
        }
    }

    Context 'When System Locale is not in the desired state' {
        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetParams = @{
                    SystemLocale     = 'en-AU'
                    IsSingleInstance = 'Yes'
                }

                { Set-TargetResource @setTargetParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName Set-WinSystemLocale -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'DSC_SystemLocale\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        Mock -CommandName Get-WinSystemLocale -MockWith {
            @{
                LCID        = '1033'
                Name        = 'en-US'
                DisplayName = 'English (United States)'
            }
        }
    }

    Context 'When an invalid locale is used' {
        It 'Should throw the expected exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($localizedData.InvalidSystemLocaleError -f 'zzz-ZZZ') `
                    -ArgumentName 'SystemLocale'

                $testTargetParams = @{
                    SystemLocale     = 'zzz-ZZZ'
                    IsSingleInstance = 'Yes'
                }

                { Test-TargetResource @testTargetParams } | Should -Throw $errorRecord
            }
        }
    }

    Context 'When system is in the desired state' {
        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetParams = @{
                    SystemLocale     = 'en-US'
                    IsSingleInstance = 'Yes'
                }

                Test-TargetResource @testTargetParams | Should -BeTrue
            }
        }
    }

    Context 'When system is not in the desired state' {
        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetParams = @{
                    SystemLocale     = 'en-AU'
                    IsSingleInstance = 'Yes'
                }

                Test-TargetResource @testTargetParams | Should -BeFalse
            }
        }
    }
}

Describe 'DSC_SystemLocale\Test-SystemLocaleValue' -Tag 'Private' {
    Context 'When a valid System Locale is passed' {
        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-SystemLocaleValue -SystemLocale 'en-US' | Should -BeTrue
            }
        }
    }

    Context 'When an invalid System Locale is passed' {
        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-SystemLocaleValue -SystemLocale 'zzz-ZZZ' | Should -BeFalse
            }
        }
    }
}
