<#
    .SYNOPSIS
        Unit test for DSC_IEEnhancedSecurityConfiguration DSC resource.

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
    $script:dscResourceName = 'DSC_IEEnhancedSecurityConfiguration'

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

Describe 'IEEnhancedSecurityConfiguration\Get-TargetResource' -Tag 'Get' {
    BeforeDiscovery {
        $testCases_Enabled = @(
            # Enabled for administrators
            @{
                Role    = 'Administrators'
                Enabled = $true
            },

            # Enabled for users
            @{
                Role    = 'Users'
                Enabled = $true
            }
        )

        $testCases_Disabled = @(
            # Disabled for administrators
            @{
                Role    = 'Administrators'
                Enabled = $false
            },

            # Disabled for users
            @{
                Role    = 'Users'
                Enabled = $false
            }
        )
    }

    Context 'When the system is in the desired present state' {
        Context 'When IE Enhanced Security Configuration is enabled for each role' {
            BeforeAll {
                Mock -CommandName Get-ItemProperty -MockWith {
                    return @{
                        IsInstalled = 1
                    }
                }
            }

            It 'Should return the state as enabled for <Role>' -TestCases $testCases_Enabled {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource -Role $Role -Enabled $Enabled

                    $result.Role | Should -Be $Role
                    $result.Enabled | Should -Be $Enabled
                    $result.SuppressRestart | Should -BeFalse
                }
            }
        }

        Context 'When IE Enhanced Security Configuration is disabled for each role' {
            BeforeAll {
                Mock -CommandName Get-ItemProperty -MockWith {
                    return @{
                        IsInstalled = 0
                    }
                }
            }

            It 'Should return the state as disabled for <Role>' -TestCases $testCases_Disabled {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource -Role $Role -Enabled $Enabled

                    $result.Role | Should -Be $Role
                    $result.Enabled | Should -Be $Enabled
                    $result.SuppressRestart | Should -BeFalse
                }
            }
        }
    }

    Context 'When the system is not in the desired present state' {
        Context 'When IE Enhanced Security Configuration does not match the desired state enabled' {
            BeforeAll {
                Mock -CommandName Get-ItemProperty -MockWith {
                    return @{
                        IsInstalled = 0
                    }
                }
            }

            It 'Should return the state as disabled for <Role>' -TestCases $testCases_Enabled {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource -Role $Role -Enabled $Enabled -SuppressRestart $true

                    $result.Role | Should -Be $Role
                    $result.Enabled | Should -BeFalse
                    $result.SuppressRestart | Should -BeTrue
                }
            }
        }

        Context 'When IE Enhanced Security Configuration does not match the desired state disabled' {
            BeforeAll {
                Mock -CommandName Get-ItemProperty -MockWith {
                    return @{
                        IsInstalled = 1
                    }
                }
            }

            It 'Should return the state as enabled for <Role>' -TestCases $testCases_Disabled {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource -Role $Role -Enabled $Enabled

                    $result.Role | Should -Be $Role
                    $result.Enabled | Should -BeTrue
                    $result.SuppressRestart | Should -BeFalse
                }
            }
        }

        Context 'When desired state cannot be determined' {
            BeforeAll {
                Mock -CommandName Write-Warning
                Mock -CommandName Get-ItemProperty -MockWith {
                    throw
                }
            }

            It 'Should write the correct warning' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource -Role 'Users' -Enabled $true

                    $result.Role | Should -Be 'Users'
                    $result.Enabled | Should -BeFalse
                    $result.SuppressRestart | Should -BeFalse
                }

                Should -Invoke -CommandName Write-Warning -ParameterFilter {
                    $Message -ilike '*(IEESC0007)'
                } -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'IEEnhancedSecurityConfiguration\Set-TargetResource' -Tag 'Set' {
    BeforeDiscovery {
        $testCases_Enabled = @(
            # Enabled for administrators
            @{
                Role    = 'Administrators'
                Enabled = $true
            },

            # Enabled for users
            @{
                Role    = 'Users'
                Enabled = $true
            }
        )

        $testCases_Disabled = @(
            # Disabled for administrators
            @{
                Role    = 'Administrators'
                Enabled = $false
            },

            # Disabled for users
            @{
                Role    = 'Users'
                Enabled = $false
            }
        )
    }

    Context 'When the system is in the desired present state' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $global:DSCMachineStatus = 0
            }
        }

        Context 'When IE Enhanced Security Configuration is enabled for each role' {
            BeforeAll {
                Mock -CommandName Write-Warning
                Mock -CommandName Set-ItemProperty
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Enabled = $true
                    }
                }
            }

            It 'Should return the state as enabled for <Role>' -TestCases $testCases_Enabled {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    { Set-TargetResource -Role $Role -Enabled $Enabled } | Should -Not -Throw

                    $global:DSCMachineStatus | Should -Be 0
                }

                Should -Invoke -CommandName Set-ItemProperty -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName Write-Warning -Exactly -Times 0 -Scope It
            }
        }

        Context 'When IE Enhanced Security Configuration is disabled for each role' {
            BeforeAll {
                Mock -CommandName Write-Warning
                Mock -CommandName Set-ItemProperty
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Enabled = $false
                    }
                }
            }

            It 'Should return the state as enabled for <Role>' -TestCases $testCases_Disabled {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    { Set-TargetResource -Role $Role -Enabled $Enabled } | Should -Not -Throw

                    $global:DSCMachineStatus | Should -Be 0
                }

                Should -Invoke -CommandName Set-ItemProperty -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName Write-Warning -Exactly -Times 0 -Scope It
            }
        }
    }

    Context 'When the system is not in the desired present state' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $global:DSCMachineStatus = 0
            }
        }

        Context 'When IE Enhanced Security Configuration should be enabled' {
            BeforeAll {
                Mock -CommandName Write-Warning
                Mock -CommandName Set-ItemProperty
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Enabled = $false
                    }
                }
            }

            It 'Should return the state as enabled for <Role>' -TestCases $testCases_Enabled {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    { Set-TargetResource -Role $Role -Enabled $Enabled } | Should -Not -Throw

                    $global:DSCMachineStatus | Should -Be 1
                }

                Should -Invoke -CommandName Set-ItemProperty -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Write-Warning -Exactly -Times 0 -Scope It
            }
        }

        Context 'When IE Enhanced Security Configuration should be disabled' {
            BeforeAll {
                Mock -CommandName Write-Warning
                Mock -CommandName Set-ItemProperty
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Enabled = $true
                    }
                }
            }

            It 'Should return the state as enabled for <Role>' -TestCases $testCases_Disabled {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    { Set-TargetResource -Role $Role -Enabled $Enabled } | Should -Not -Throw

                    $global:DSCMachineStatus | Should -Be 1
                }

                Should -Invoke -CommandName Set-ItemProperty -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Write-Warning -Exactly -Times 0 -Scope It
            }
        }

        Context 'When restart is suppressed' {
            BeforeAll {
                Mock -CommandName Write-Warning
                Mock -CommandName Set-ItemProperty
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Enabled = $true
                    }
                }
            }

            It 'Should should suppress the restart when changing the state for <Role>' -TestCases $testCases_Disabled {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    { Set-TargetResource -Role $Role -Enabled $Enabled -SuppressRestart $true } | Should -Not -Throw

                    $global:DSCMachineStatus | Should -Be 0
                }

                Should -Invoke -CommandName Set-ItemProperty -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Write-Warning -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the Set-ItemProperty throws an error' {
            BeforeAll {
                Mock -CommandName Set-ItemProperty -MockWith {
                    throw
                }

                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Enabled = $false
                    }
                }
            }

            It 'Should throw the correct error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $errorMessage = $script:localizedData.FailedToSetDesiredState -f 'Users'

                    { Set-TargetResource -Role 'Users' -Enabled $true } | Should -Throw -ExpectedMessage $errorMessage.Exception.Message
                }
            }
        }
    }
}

Describe 'IEEnhancedSecurityConfiguration\Test-TargetResource' {
    BeforeDiscovery {
        $testCases_Enabled = @(
            # Enabled for administrators
            @{
                Role    = 'Administrators'
                Enabled = $true
            },

            # Enabled for users
            @{
                Role    = 'Users'
                Enabled = $true
            }
        )

        $testCases_Disabled = @(
            # Disabled for administrators
            @{
                Role    = 'Administrators'
                Enabled = $false
            },

            # Disabled for users
            @{
                Role    = 'Users'
                Enabled = $false
            }
        )
    }

    Context 'When the system is in the desired present state' {
        Context 'When IE Enhanced Security Configuration is enabled for each role' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Enabled = $true
                    }
                }
            }

            It 'Should return $true for <Role>' -TestCases $testCases_Enabled {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Test-TargetResource -Role $Role -Enabled $Enabled

                    $result | Should -BeTrue
                }
            }
        }

        Context 'When IE Enhanced Security Configuration is disabled for each role' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Enabled = $false
                    }
                }
            }

            It 'Should return $true for <Role>' -TestCases $testCases_Disabled {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Test-TargetResource -Role $Role -Enabled $Enabled

                    $result | Should -BeTrue
                }
            }
        }
    }

    Context 'When the system is not in the desired present state' {
        Context 'When IE Enhanced Security Configuration does not match the desired state enabled' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Enabled = $false
                    }
                }
            }

            It 'Should return $false for <Role>' -TestCases $testCases_Enabled {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Test-TargetResource -Role $Role -Enabled $Enabled

                    $result | Should -BeFalse
                }
            }
        }

        Context 'When IE Enhanced Security Configuration does not match the desired state disabled' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Enabled = $true
                    }
                }
            }

            It 'Should return $false for <Role>' -TestCases $testCases_Disabled {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                $result = Test-TargetResource -Role $Role -Enabled $Enabled

                $result | Should -BeFalse
                }
            }
        }
    }
}
