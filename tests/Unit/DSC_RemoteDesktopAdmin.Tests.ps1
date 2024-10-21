<#
    .SYNOPSIS
        Unit test for DSC_RemoteDesktopAdmin DSC resource.

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
    $script:dscResourceName = 'DSC_RemoteDesktopAdmin'

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

Describe 'DSC_RemoteDesktopAdmin\Get-TargetResource' -Tag 'Get' {
    Context 'When Remote Desktop Admin settings exist' {
        Context 'When Ensure is Present' {
            BeforeAll {
                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter { $Name -eq 'fDenyTSConnections' } `
                    -MockWith { @{fDenyTSConnections = 0 } }

                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter { $Name -eq 'UserAuthentication' } `
                    -MockWith { @{UserAuthentication = 0 } }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $targetResource = Get-TargetResource -IsSingleInstance 'Yes'
                    $targetResource.Ensure | Should -Be 'Present'
                }
            }
        }

        Context 'When Ensure is Absent' {
            BeforeAll {
                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter { $Name -eq 'fDenyTSConnections' } `
                    -MockWith { @{fDenyTSConnections = 1 } }

                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter { $Name -eq 'UserAuthentication' } `
                    -MockWith { @{UserAuthentication = 0 } }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $targetResource = Get-TargetResource -IsSingleInstance 'Yes'
                    $targetResource.Ensure | Should -Be 'Absent'
                }
            }
        }

        Context 'When UserAuthentication is NonSecure' {
            BeforeAll {
                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter { $Name -eq 'fDenyTSConnections' } `
                    -MockWith { @{fDenyTSConnections = 0 } }

                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter { $Name -eq 'UserAuthentication' } `
                    -MockWith { @{UserAuthentication = 0 } }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource -IsSingleInstance 'Yes'
                    $result.UserAuthentication | Should -Be 'NonSecure'
                }
            }
        }

        Context 'When UserAuthentication is Secure' {
            BeforeAll {
                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter { $Name -eq 'fDenyTSConnections' } `
                    -MockWith { @{fDenyTSConnections = 0 } }

                Mock -CommandName Get-ItemProperty `
                    -ParameterFilter { $Name -eq 'UserAuthentication' } `
                    -MockWith { @{UserAuthentication = 1 } }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource -IsSingleInstance 'Yes'
                    $result.UserAuthentication | Should -Be 'Secure'
                }
            }
        }
    }
}

Describe 'DSC_RemoteDesktopAdmin\Test-TargetResource' -Tag 'Test' {
    Context 'When the system is in the desired state' {
        Context 'When Ensure is present' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        IsSingleInstance   = 'Yes'
                        Ensure             = 'Present'
                        UserAuthentication = 'Secure'
                    }
                }
                It 'Should return true' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $testTargetResourceParameters = @{
                            IsSingleInstance = 'Yes'
                            Ensure           = 'Present'
                        }

                        Test-TargetResource @testTargetResourceParameters | Should -BeTrue
                    }
                }
            }
        }

        Context 'When Ensure is absent' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        IsSingleInstance   = 'Yes'
                        Ensure             = 'Absent'
                        UserAuthentication = 'NonSecure'
                    }
                }
            }

            It 'Should return true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceParameters = @{
                        IsSingleInstance = 'Yes'
                        Ensure           = 'Absent'
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -BeTrue
                }
            }
        }

        Context 'When User Authentication is Secure' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        IsSingleInstance   = 'Yes'
                        Ensure             = 'Present'
                        UserAuthentication = 'Secure'
                    }
                }
            }

            It 'Should return true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceParameters = @{
                        IsSingleInstance   = 'Yes'
                        Ensure             = 'Present'
                        UserAuthentication = 'Secure'
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -BeTrue
                }
            }
        }

        Context 'When User Authentication is NonSecure' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        IsSingleInstance   = 'Yes'
                        Ensure             = 'Present'
                        UserAuthentication = 'NonSecure'
                    }
                }
            }

            It 'Should return true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceParameters = @{
                        IsSingleInstance   = 'Yes'
                        Ensure             = 'Present'
                        UserAuthentication = 'NonSecure'
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -BeTrue
                }
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When Ensure is present' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        IsSingleInstance   = 'Yes'
                        Ensure             = 'Present'
                        UserAuthentication = 'Secure'
                    }
                }
            }

            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceParameters = @{
                        IsSingleInstance = 'Yes'
                        Ensure           = 'Absent'
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -BeFalse
                }
            }
        }

        Context 'When Ensure is absent' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        IsSingleInstance   = 'Yes'
                        Ensure             = 'Absent'
                        UserAuthentication = 'NonSecure'
                    }
                }
            }

            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceParameters = @{
                        IsSingleInstance = 'Yes'
                        Ensure           = 'Present'
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -BeFalse
                }
            }
        }

        Context 'When User Authentication is Secure' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith { @{
                        IsSingleInstance   = 'Yes'
                        Ensure             = 'Present'
                        UserAuthentication = 'Secure'
                    }
                }
            }

            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceParameters = @{
                        IsSingleInstance   = 'Yes'
                        Ensure             = 'Present'
                        UserAuthentication = 'NonSecure'
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -BeFalse
                }
            }
        }

        Context 'When User Authentication is NonSecure' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        IsSingleInstance   = 'Yes'
                        Ensure             = 'Present'
                        UserAuthentication = 'NonSecure'
                    }
                }
            }

            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceParameters = @{
                        IsSingleInstance   = 'Yes'
                        Ensure             = 'Present'
                        UserAuthentication = 'Secure'
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -BeFalse
                }
            }
        }
    }
}

Describe 'DSC_RemoteDesktopAdmin\Set-TargetResource' -Tag 'Set' {
    Context 'When the system is not in the desired state' {
        BeforeEach {
            Mock -CommandName Set-ItemProperty
        }

        Context 'When Ensure is absent' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        IsSingleInstance   = 'Yes'
                        Ensure             = 'Absent'
                        UserAuthentication = 'NonSecure'
                    }
                }
            }

            It 'Should set the state to Present' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    Set-TargetResource -IsSingleInstance 'Yes' -Ensure 'Present'
                }

                Should -Invoke -CommandName Set-ItemProperty -ParameterFilter {
                    $Name -eq 'fDenyTSConnections' -and
                    $Value -eq '0'
                    $Type -eq 'DWord'
                } -Times 1 -Exactly -Scope It
            }
        }

        Context 'When Ensure is Present' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        IsSingleInstance   = 'Yes'
                        Ensure             = 'Present'
                        UserAuthentication = 'NonSecure'
                    }
                }
            }
            It 'Should set the state to Absent' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    Set-TargetResource -IsSingleInstance 'yes' -Ensure 'Absent'
                }

                Should -Invoke -CommandName Set-ItemProperty -ParameterFilter {
                    $Name -eq 'fDenyTSConnections' -and
                    $Value -eq '1'
                    $Type -eq 'DWord'
                } -Times 1 -Exactly -Scope It
            }
        }

        Context 'When User Authentication is NonSecure' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        IsSingleInstance   = 'Yes'
                        Ensure             = 'Present'
                        UserAuthentication = 'NonSecure'
                    }
                }
            }

            It 'Should set UserAuthentication to Secure' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    Set-TargetResource -IsSingleInstance 'yes' -Ensure 'Present' -UserAuthentication 'Secure'
                }

                Should -Invoke -CommandName Set-ItemProperty -ParameterFilter {
                    $Name -eq 'UserAuthentication' -and
                    $Value -eq '1'
                    $Type -eq 'DWord'
                } -Times 1 -Exactly -Scope It
            }
        }

        Context 'When User Authentication is Secure' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    @{
                        IsSingleInstance   = 'Yes'
                        Ensure             = 'Present'
                        UserAuthentication = 'Secure'
                    }
                }
            }

            It 'Should set UserAuthentication to NonSecure' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    Set-TargetResource -IsSingleInstance 'yes' -Ensure 'Present' -UserAuthentication 'NonSecure'
                }

                Should -Invoke -CommandName Set-ItemProperty -ParameterFilter {
                    $Name -eq 'UserAuthentication' -and
                    $Value -eq '0'
                    $Type -eq 'DWord'
                } -Times 1 -Exactly -Scope It
            }
        }
    }
}
