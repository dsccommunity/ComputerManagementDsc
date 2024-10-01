<#
    .SYNOPSIS
        Unit test for DSC_WindowsCapability DSC resource.

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
    $script:dscResourceName = 'DSC_WindowsCapability'

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

Describe 'DSC_WindowsCapability\Get-TargetResource' {
    Context 'When a Windows Capability is installed' {
        BeforeAll {
            Mock -CommandName Get-WindowsCapability -MockWith {
                @{
                    Name     = 'Test'
                    State    = 'Installed'
                    LogLevel = 'Errors'
                    LogPath  = 'LogPath'
                }
            }
        }

        It 'Should return expected result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getTargetResourceResult = Get-TargetResource -Name 'Test'

                { $getTargetResourceResult } | Should -Not -Throw

                $getTargetResourceResult.Name | Should -Be 'Test'
                $getTargetResourceResult.Ensure | Should -Be 'Present'
                $getTargetResourceResult.LogLevel | Should -Be 'Errors'
                $getTargetResourceResult.LogPath | Should -Be 'LogPath'
            }

            Should -Invoke -CommandName Get-WindowsCapability -ParameterFilter {
                $Name -eq 'Test' -and
                $Online -eq $true
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When a Windows Capability is not installed' {
        BeforeAll {
            Mock -CommandName Get-WindowsCapability -MockWith {
                @{
                    Name     = 'Test'
                    State    = 'NotPresent'
                    LogLevel = 'Errors'
                    LogPath  = 'LogPath'
                }
            }
        }

        It 'Should return expected result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getTargetResourceResult = Get-TargetResource -Name 'Test'

                { $getTargetResourceResult } | Should -Not -Throw

                $getTargetResourceResult.Name | Should -Be 'Test'
                $getTargetResourceResult.Ensure | Should -Be 'Absent'
                $getTargetResourceResult.LogLevel | Should -Be 'Errors'
                $getTargetResourceResult.LogPath | Should -Be 'LogPath'
            }

            Should -Invoke -CommandName Get-WindowsCapability -ParameterFilter {
                $Name -eq 'Test' -and
                $Online -eq $true
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When a Windows Capability does not exist' {
        BeforeAll {
            Mock -CommandName Get-WindowsCapability -MockWith {
                @{
                    Name     = ''
                    State    = ''
                    LogLevel = 'Errors'
                    LogPath  = 'LogPath'
                }
            }
        }

        It 'Should throw expected exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockErrorRecord = Get-InvalidArgumentRecord -Message (
                    $script:localizedData.CapabilityNameNotFound -f 'Test'
                ) -ArgumentName 'Name'

                { $getTargetResourceResult = Get-TargetResource -Name 'Test' } |
                    Should -Throw -ExpectedMessage ($mockErrorRecord.Exception.Message + '*')

            }

            Should -Invoke -CommandName Get-WindowsCapability -ParameterFilter {
                $Name -eq 'Test' -and
                $Online -eq $true
            } -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'DSC_WindowsCapability\Test-TargetResource' {
    Context 'When a Windows Capability is installed and should be' {
        BeforeAll {
            Mock -CommandName Get-WindowsCapability -MockWith {
                @{
                    Name     = 'Test'
                    State    = 'Installed'
                    LogLevel = 'Errors'
                    LogPath  = 'LogPath'
                }
            }
        }

        It 'Should return correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = @{
                    Name   = 'Test'
                    Ensure = 'Present'
                }

                $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters

                { $testTargetResourceResult } | Should -Not -Throw

                $testTargetResourceResult | Should -BeTrue
            }

            Should -Invoke -CommandName Get-WindowsCapability -ParameterFilter {
                $Name -eq 'Test' -and
                $Online -eq $true
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When a Windows Capability is not installed and should be' {
        BeforeAll {
            Mock -CommandName Get-WindowsCapability -MockWith {
                @{
                    Name     = 'Test'
                    State    = 'NotPresent'
                    LogLevel = 'Errors'
                    LogPath  = 'LogPath'
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = @{
                    Name   = 'Test'
                    Ensure = 'Present'
                }

                $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters

                { $testTargetResourceResult } | Should -Not -Throw

                $testTargetResourceResult | Should -BeFalse
            }

            Should -Invoke -CommandName Get-WindowsCapability -ParameterFilter {
                $Name -eq 'Test' -and
                $Online -eq $true
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When a Windows Capability is installed and should not be' {
        BeforeAll {
            Mock -CommandName Get-WindowsCapability -MockWith {
                @{
                    Name     = 'Test'
                    State    = 'Installed'
                    LogLevel = 'Errors'
                    LogPath  = 'LogPath'
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = @{
                    Name   = 'Test'
                    Ensure = 'Absent'
                }

                $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters

                { $testTargetResourceResult } | Should -Not -Throw

                $testTargetResourceResult | Should -BeFalse
            }

            Should -Invoke -CommandName Get-WindowsCapability -ParameterFilter {
                $Name -eq 'Test' -and
                $Online -eq $true
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When a Windows Capability is not installed and should not be' {
        BeforeAll {
            Mock -CommandName Get-WindowsCapability -MockWith {
                @{
                    Name     = 'Test'
                    State    = 'NotPresent'
                    LogLevel = 'Errors'
                    LogPath  = 'LogPath'
                }
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = @{
                    Name   = 'Test'
                    Ensure = 'Absent'
                }

                $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters

                { $testTargetResourceResult } | Should -Not -Throw

                $testTargetResourceResult | Should -BeTrue
            }

            Should -Invoke -CommandName Get-WindowsCapability -ParameterFilter {
                $Name -eq 'Test' -and
                $Online -eq $true
            } -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'DSC_WindowsCapability\Set-TargetResource' {
    BeforeAll {
        Mock -CommandName Add-WindowsCapability
        Mock -CommandName Remove-WindowsCapability
    }

    Context 'When a Windows Capability is installed and should be' {
        BeforeAll {
            Mock -CommandName Get-WindowsCapability -MockWith {
                @{
                    Name     = 'Test'
                    State    = 'NotPresent'
                    LogLevel = 'Errors'
                    LogPath  = 'LogPath'
                }
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    Name   = 'Test'
                    Ensure = 'Absent'
                }

                { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-WindowsCapability -ParameterFilter {
                $Name -eq 'Test' -and
                $Online -eq $true
            } -Exactly -Times 1 -Scope It

            Should -Invoke -CommandName Add-WindowsCapability -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Remove-WindowsCapability -Exactly -Times 0 -Scope It
        }
    }

    Context 'When a Windows Capability is not installed and should be' {
        BeforeAll {
            Mock -CommandName Get-WindowsCapability -MockWith {
                @{
                    Name     = 'Test'
                    State    = 'NotPresent'
                    LogLevel = 'Errors'
                    LogPath  = 'LogPath'
                }
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    Name   = 'Test'
                    Ensure = 'Present'
                }

                { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-WindowsCapability -ParameterFilter {
                $Name -eq 'Test' -and
                $Online -eq $true
            } -Exactly -Times 1 -Scope It

            Should -Invoke -CommandName Add-WindowsCapability -ParameterFilter {
                $Name -eq 'Test' -and
                $Online -eq $true
            } -Exactly -Times 1 -Scope It

            Should -Invoke -CommandName Remove-WindowsCapability -Exactly -Times 0 -Scope It
        }
    }

    Context 'When a Windows Capability is installed and should not be' {
        BeforeAll {
            Mock -CommandName Get-WindowsCapability -MockWith {
                @{
                    Name     = 'Test'
                    State    = 'Installed'
                    LogLevel = 'Errors'
                    LogPath  = 'LogPath'
                }
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    Name   = 'Test'
                    Ensure = 'Absent'
                }

                { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-WindowsCapability -ParameterFilter {
                $Name -eq 'Test' -and
                $Online -eq $true
            } -Exactly -Times 1 -Scope It

            Should -Invoke -CommandName Add-WindowsCapability -Exactly -Times 0 -Scope It

            Should -Invoke -CommandName Remove-WindowsCapability -ParameterFilter {
                $Name -eq 'Test' -and
                $Online -eq $true
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When a Windows Capability is not installed and should not be' {
        BeforeAll {
            Mock -CommandName Get-WindowsCapability -MockWith {
                @{
                    Name     = 'Test'
                    State    = 'NotPresent'
                    LogLevel = 'Errors'
                    LogPath  = 'LogPath'
                }
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    Name   = 'Test'
                    Ensure = 'Absent'
                }

                { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-WindowsCapability -ParameterFilter {
                $Name -eq 'Test' -and
                $Online -eq $true
            } -Exactly -Times 1 -Scope It

            Should -Invoke -CommandName Add-WindowsCapability -Exactly -Times 0
            Should -Invoke -CommandName Remove-WindowsCapability -Exactly -Times 0 -Scope It
        }
    }
}
