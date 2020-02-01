#region HEADER
$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'DSC_IEEnhancedSecurityConfiguration'

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

# Begin Testing
try
{
    # Assign the localized data from the module into a local variable
    InModuleScope $script:dscResourceName {
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

        Describe 'IEEnhancedSecurityConfiguration\Get-TargetResource' {
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
                        param
                        (
                            [Parameter()]
                            [System.String]
                            $Role,

                            [Parameter()]
                            [System.Boolean]
                            $Enabled
                        )

                        $result = Get-TargetResource -Role $Role -Enabled $Enabled -Verbose
                        $result.Role | Should -Be $Role
                        $result.Enabled | Should -Be $Enabled
                        $result.SuppressRestart | Should -BeFalse
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
                        param
                        (
                            [Parameter()]
                            [System.String]
                            $Role,

                            [Parameter()]
                            [System.Boolean]
                            $Enabled
                        )

                        $result = Get-TargetResource -Role $Role -Enabled $Enabled -Verbose
                        $result.Role | Should -Be $Role
                        $result.Enabled | Should -Be $Enabled
                        $result.SuppressRestart | Should -BeFalse
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
                        param
                        (
                            [Parameter()]
                            [System.String]
                            $Role,

                            [Parameter()]
                            [System.Boolean]
                            $Enabled
                        )

                        $result = Get-TargetResource -Role $Role -Enabled $Enabled -SuppressRestart $true -Verbose
                        $result.Role | Should -Be $Role
                        $result.Enabled | Should -BeFalse
                        $result.SuppressRestart | Should -BeTrue
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
                        param
                        (
                            [Parameter()]
                            [System.String]
                            $Role,

                            [Parameter()]
                            [System.Boolean]
                            $Enabled
                        )

                        $result = Get-TargetResource -Role $Role -Enabled $Enabled -Verbose
                        $result.Role | Should -Be $Role
                        $result.Enabled | Should -BeTrue
                        $result.SuppressRestart | Should -BeFalse
                    }
                }
            }
        }

        Describe 'IEEnhancedSecurityConfiguration\Set-TargetResource' {
            Context 'When the system is in the desired present state' {
                BeforeEach {
                    $global:DSCMachineStatus = 0
                }

                Context 'When IE Enhanced Security Configuration is enabled for each role' {
                    BeforeAll {
                        Mock -CommandName Write-Warning
                        Mock -CommandName Set-ItemProperty
                        Mock -CommandName Get-ItemProperty -MockWith {
                            return @{
                                IsInstalled = 1
                            }
                        }
                    }

                    It 'Should return the state as enabled for <Role>' -TestCases $testCases_Enabled {
                        param
                        (
                            [Parameter()]
                            [System.String]
                            $Role,

                            [Parameter()]
                            [System.Boolean]
                            $Enabled
                        )

                        { Set-TargetResource -Role $Role -Enabled $Enabled -Verbose } | Should -Not -Throw

                        Assert-MockCalled -CommandName Set-ItemProperty -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope It
                        $global:DSCMachineStatus | Should -Be 0
                    }
                }

                Context 'When IE Enhanced Security Configuration is disabled for each role' {
                    BeforeAll {
                        Mock -CommandName Write-Warning
                        Mock -CommandName Set-ItemProperty
                        Mock -CommandName Get-ItemProperty -MockWith {
                            return @{
                                IsInstalled = 0
                            }
                        }
                    }

                    It 'Should return the state as enabled for <Role>' -TestCases $testCases_Disabled {
                        param
                        (
                            [Parameter()]
                            [System.String]
                            $Role,

                            [Parameter()]
                            [System.Boolean]
                            $Enabled
                        )

                        { Set-TargetResource -Role $Role -Enabled $Enabled -Verbose } | Should -Not -Throw

                        Assert-MockCalled -CommandName Set-ItemProperty -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope It
                        $global:DSCMachineStatus | Should -Be 0
                    }
                }
            }

            Context 'When the system is not in the desired present state' {
                BeforeEach {
                    $global:DSCMachineStatus = 0
                }

                Context 'When IE Enhanced Security Configuration should be enabled' {
                    BeforeAll {
                        Mock -CommandName Write-Warning
                        Mock -CommandName Set-ItemProperty
                        Mock -CommandName Get-ItemProperty -MockWith {
                            return @{
                                IsInstalled = 0
                            }
                        }
                    }

                    It 'Should return the state as enabled for <Role>' -TestCases $testCases_Enabled {
                        param
                        (
                            [Parameter()]
                            [System.String]
                            $Role,

                            [Parameter()]
                            [System.Boolean]
                            $Enabled
                        )

                        { Set-TargetResource -Role $Role -Enabled $Enabled -Verbose } | Should -Not -Throw

                        Assert-MockCalled -CommandName Set-ItemProperty -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope It
                        $global:DSCMachineStatus | Should -Be 1
                    }
                }

                Context 'When IE Enhanced Security Configuration should be disabled' {
                    BeforeAll {
                        Mock -CommandName Write-Warning
                        Mock -CommandName Set-ItemProperty
                        Mock -CommandName Get-ItemProperty -MockWith {
                            return @{
                                IsInstalled = 1
                            }
                        }
                    }

                    It 'Should return the state as enabled for <Role>' -TestCases $testCases_Disabled {
                        param
                        (
                            [Parameter()]
                            [System.String]
                            $Role,

                            [Parameter()]
                            [System.Boolean]
                            $Enabled
                        )

                        { Set-TargetResource -Role $Role -Enabled $Enabled -Verbose } | Should -Not -Throw

                        Assert-MockCalled -CommandName Set-ItemProperty -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Write-Warning -Exactly -Times 0 -Scope It
                        $global:DSCMachineStatus | Should -Be 1
                    }
                }

                Context 'When restart is suppressed' {
                    BeforeAll {
                        Mock -CommandName Write-Warning
                        Mock -CommandName Set-ItemProperty
                        Mock -CommandName Get-ItemProperty -MockWith {
                            return @{
                                IsInstalled = 1
                            }
                        }
                    }

                    It 'Should should suppress the restart when changing the state for <Role>' -TestCases $testCases_Disabled {
                        param
                        (
                            [Parameter()]
                            [System.String]
                            $Role,

                            [Parameter()]
                            [System.Boolean]
                            $Enabled
                        )

                        { Set-TargetResource -Role $Role -Enabled $Enabled -SuppressRestart $true -Verbose } | Should -Not -Throw

                        Assert-MockCalled -CommandName Set-ItemProperty -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Write-Warning -Exactly -Times 1 -Scope It
                        $global:DSCMachineStatus | Should -Be 0
                    }
                }
            }
        }

        Describe 'IEEnhancedSecurityConfiguration\Test-TargetResource' {
            Context 'When the system is in the desired present state' {
                Context 'When IE Enhanced Security Configuration is enabled for each role' {
                    BeforeAll {
                        Mock -CommandName Get-ItemProperty -MockWith {
                            return @{
                                IsInstalled = 1
                            }
                        }
                    }

                    It 'Should return $true for <Role>' -TestCases $testCases_Enabled {
                        param
                        (
                            [Parameter()]
                            [System.String]
                            $Role,

                            [Parameter()]
                            [System.Boolean]
                            $Enabled
                        )

                        $result = Test-TargetResource -Role $Role -Enabled $Enabled -Verbose
                        $result | Should -BeTrue
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

                    It 'Should return $true for <Role>' -TestCases $testCases_Disabled {
                        param
                        (
                            [Parameter()]
                            [System.String]
                            $Role,

                            [Parameter()]
                            [System.Boolean]
                            $Enabled
                        )

                        $result = Test-TargetResource -Role $Role -Enabled $Enabled -Verbose
                        $result | Should -BeTrue
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

                    It 'Should return $false for <Role>' -TestCases $testCases_Enabled {
                        param
                        (
                            [Parameter()]
                            [System.String]
                            $Role,

                            [Parameter()]
                            [System.Boolean]
                            $Enabled
                        )

                        $result = Test-TargetResource -Role $Role -Enabled $Enabled -Verbose
                        $result | Should -BeFalse
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

                    It 'Should return $false for <Role>' -TestCases $testCases_Disabled {
                        param
                        (
                            [Parameter()]
                            [System.String]
                            $Role,

                            [Parameter()]
                            [System.Boolean]
                            $Enabled
                        )

                        $result = Test-TargetResource -Role $Role -Enabled $Enabled -Verbose
                        $result | Should -BeFalse
                    }
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
