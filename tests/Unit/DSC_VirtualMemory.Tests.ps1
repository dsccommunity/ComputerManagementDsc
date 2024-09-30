<#
    .SYNOPSIS
        Unit test for DSC_VirtualMemory DSC resource.

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
    $script:dscResourceName = 'DSC_VirtualMemory'

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

Describe 'DSC_VirtualMemory\Get-TargetResource' -Tag 'Get' {
    BeforeEach {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $script:testParameters = @{
                Drive = 'K:'
                Type  = 'CustomSize'
            }
        }
    }

    Context 'When automatic managed page file is enabled' {
        BeforeAll {
            Mock -CommandName Get-CimInstance -ParameterFilter {
                $ClassName -eq 'Win32_ComputerSystem'
            } -MockWith {
                [PSObject] @{
                    AutomaticManagedPageFile = $true
                    Name                     = 'K:\pagefile.sys'
                }
            }
        }

        It 'Should return type set to AutoManagePagingFile' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @testParameters
                $result.Type | Should -Be 'AutoManagePagingFile'
            }

            Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                $ClassName -eq 'Win32_ComputerSystem'
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When automatic managed page file is disabled and no page file set' {
        BeforeAll {
            Mock -CommandName Get-CimInstance -ParameterFilter {
                $ClassName -eq 'Win32_ComputerSystem'
            } -MockWith {
                [PSObject] @{
                    AutomaticManagedPageFile = $false
                    Name                     = 'K:\pagefile.sys'
                }
            }

            Mock -CommandName Get-PageFileSetting -ParameterFilter { $Drive -eq 'K:' }
        }

        It 'Should return type set to NoPagingFile' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @testParameters
                $result.Type | Should -Be 'NoPagingFile'
            }

            Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                $ClassName -eq 'Win32_ComputerSystem'
            } -Exactly -Times 1 -Scope It

            Should -Invoke -CommandName Get-PageFileSetting -ParameterFilter {
                $Drive -eq 'K:'
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When automatic managed page file is disabled and system managed size is set' {
        BeforeAll {
            Mock -CommandName Get-CimInstance -ParameterFilter {
                $ClassName -eq 'Win32_ComputerSystem'
            } -MockWith {
                [PSObject] @{
                    AutomaticManagedPageFile = $false
                    Name                     = 'K:\pagefile.sys'
                }
            }

            Mock -CommandName Get-PageFileSetting -ParameterFilter {
                $Drive -eq 'K:'
            } -MockWith {
                [PSObject] @{
                    InitialSize = 0
                    MaximumSize = 0
                    Name        = 'K:\'
                }
            }
        }

        It 'Should return a expected type and drive letter' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @testParameters
                $result.Type | Should -Be 'SystemManagedSize'
                $result.Drive | Should -Be ([System.IO.DriveInfo] $testParameters.Drive).Name
            }

            Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                $ClassName -eq 'Win32_ComputerSystem'
            } -Exactly -Times 1 -Scope It

            Should -Invoke -CommandName Get-PageFileSetting -ParameterFilter {
                $Drive -eq 'K:'
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When automatic managed page file is disabled and custom size is set' {
        BeforeAll {
            Mock -CommandName Get-CimInstance -ParameterFilter {
                $ClassName -eq 'Win32_ComputerSystem'
            } -MockWith {
                [PSObject] @{
                    AutomaticManagedPageFile = $false
                    Name                     = 'K:\pagefile.sys'
                }
            }

            Mock -CommandName Get-PageFileSetting -ParameterFilter {
                $Drive -eq 'K:'
            } -MockWith {
                [PSObject] @{
                    InitialSize = 10
                    MaximumSize = 20
                    Name        = 'K:\'
                }
            }
        }

        It 'Should return expected type and drive letter' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @testParameters
                $result.Type | Should -Be 'CustomSize'
                $result.Drive | Should -Be ([System.IO.DriveInfo] $testParameters.Drive).Name
            }

            Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                $ClassName -eq 'Win32_ComputerSystem'
            } -Exactly -Times 1 -Scope It

            Should -Invoke -CommandName Get-PageFileSetting -ParameterFilter {
                $Drive -eq 'K:'
            } -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'DSC_VirtualMemory\Set-TargetResource' -Tag 'Set' {
    BeforeEach {
        <#
                    These mocks are to handle when disk drive
                    used for testing does not exist.
                #>
        Mock -CommandName Get-DriveInfo -ParameterFilter {
            $Drive -eq 'K:'
        } -MockWith {
            [PSObject] @{
                Name = 'K:\'
            }
        }

        Mock -CommandName Join-Path -ParameterFilter {
            $Path -eq 'K:\' -and
            $ChildPath -eq 'pagefile.sys'
        } -MockWith { 'K:\pagefile.sys' }

    }

    Context 'When automatic managed page file should be enabled' {
        BeforeAll {
            Mock -CommandName Get-CimInstance -ParameterFilter {
                $ClassName -eq 'Win32_ComputerSystem'
            } -MockWith {
                [PSObject] @{
                    AutomaticManagedPageFile = $false
                    Name                     = 'K:\pagefile.sys'
                }
            }

            Mock -CommandName Set-AutoManagePaging -ParameterFilter { $State -eq 'Enable' }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParameters = @{
                    Drive       = 'K:'
                    Type        = 'AutoManagePagingFile'
                    InitialSize = 0
                    MaximumSize = 0
                }

                { Set-TargetResource @testParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                $ClassName -eq 'Win32_ComputerSystem'
            } -Exactly -Times 1 -Scope It

            Should -Invoke -CommandName Set-AutoManagePaging -ParameterFilter {
                $State -eq 'Enable'
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When CustomSize is required' {
        Context 'When automatic managed page file is enabled and no page file set' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } -MockWith { [PSObject] @{
                        AutomaticManagedPageFile = $true
                        Name                     = 'K:\pagefile.sys'
                    } }

                Mock -CommandName Set-AutoManagePaging -ParameterFilter { $State -eq 'Disable' }
                Mock -CommandName Get-PageFileSetting -ParameterFilter { $Drive -eq 'K:' }
                Mock -CommandName New-PageFile -ParameterFilter { $PageFileName -eq 'K:\pagefile.sys' }
                Mock -CommandName Set-PageFileSetting -ParameterFilter {
                    $Drive -eq 'K:' -and
                    $InitialSize -eq 10 -and
                    $MaximumSize -eq 20
                }
            }

            It 'Should not throw an exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = @{
                        Drive       = 'K:'
                        Type        = 'CustomSize'
                        InitialSize = 10
                        MaximumSize = 20
                    }

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Set-AutoManagePaging -ParameterFilter {
                    $State -eq 'Disable'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Get-PageFileSetting -ParameterFilter {
                    $Drive -eq 'K:'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName New-PageFile -ParameterFilter {
                    $PageFileName -eq 'K:\pagefile.sys'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Set-PageFileSetting -ParameterFilter {
                    $Drive -eq 'K:' -and
                    $InitialSize -eq 10 -and
                    $MaximumSize -eq 20
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When automatic managed page file is enabled and page file is set' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } -MockWith { [PSObject] @{
                        AutomaticManagedPageFile = $true
                        Name                     = 'K:\pagefile.sys'
                    }
                }

                Mock -CommandName Set-AutoManagePaging -ParameterFilter { $State -eq 'Disable' }
                Mock -CommandName Get-PageFileSetting -ParameterFilter { $Drive -eq 'K:' } -MockWith {
                    [PSObject] @{
                        Name        = 'K:\pagefile.sys'
                        InitialSize = 10
                        MaximumSize = 20
                    }
                }

                Mock -CommandName New-PageFile -ParameterFilter { $PageFileName -eq 'K:\pagefile.sys' }
                Mock -CommandName Set-PageFileSetting -ParameterFilter {
                    $Drive -eq 'K:' -and
                    $InitialSize -eq 10 -and
                    $MaximumSize -eq 20
                }
            }

            It 'Should not throw an exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = @{
                        Drive       = 'K:'
                        Type        = 'CustomSize'
                        InitialSize = 10
                        MaximumSize = 20
                    }

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Set-AutoManagePaging -ParameterFilter {
                    $State -eq 'Disable'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Get-PageFileSetting -ParameterFilter {
                    $Drive -eq 'K:'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName New-PageFile -ParameterFilter {
                    $PageFileName -eq 'K:\pagefile.sys'
                } -Exactly -Times 0 -Scope It

                Should -Invoke -CommandName Set-PageFileSetting -ParameterFilter {
                    $Drive -eq 'K:' -and
                    $InitialSize -eq 10 -and
                    $MaximumSize -eq 20
                } -Exactly -Times 1 -Scope It
            }
        }
    }
    Context 'When SystemManagedSize is required' {
        Context 'When automatic managed page file is enabled and no page file set' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } -MockWith {
                    [PSObject] @{
                        AutomaticManagedPageFile = $true
                        Name                     = 'K:\pagefile.sys'
                    }
                }

                Mock -CommandName Set-AutoManagePaging -ParameterFilter { $State -eq 'Disable' }
                Mock -CommandName Get-PageFileSetting -ParameterFilter { $Drive -eq 'K:' }
                Mock -CommandName New-PageFile -ParameterFilter { $PageFileName -eq 'K:\pagefile.sys' }
                Mock -CommandName Set-PageFileSetting -ParameterFilter { $Drive -eq 'K:' }
            }

            It 'Should not throw an exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = @{
                        Drive = 'K:'
                        Type  = 'SystemManagedSize'
                    }

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Set-AutoManagePaging -ParameterFilter {
                    $State -eq 'Disable'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Get-PageFileSetting -ParameterFilter {
                    $Drive -eq 'K:'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName New-PageFile -ParameterFilter {
                    $PageFileName -eq 'K:\pagefile.sys'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Set-PageFileSetting -ParameterFilter {
                    $Drive -eq 'K:'
                } -Exactly -Times 1 -Scope It
            }
        }


        Context 'When automatic managed page file is enabled and page file is set' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } -MockWith {
                    [PSObject] @{
                        AutomaticManagedPageFile = $true
                        Name                     = 'K:\pagefile.sys'
                    }
                }

                Mock -CommandName Set-AutoManagePaging -ParameterFilter { $State -eq 'Disable' }
                Mock -CommandName Get-PageFileSetting -ParameterFilter { $Drive -eq 'K:' } -MockWith {
                    [PSObject] @{
                        Name        = 'K:\pagefile.sys'
                        InitialSize = 10
                        MaximumSize = 20
                    }
                }

                Mock -CommandName New-PageFile -ParameterFilter { $PageFileName -eq 'K:\pagefile.sys' }
                Mock -CommandName Set-PageFileSetting -ParameterFilter { $Drive -eq 'K:' }
            }

            It 'Should not throw an exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = @{
                        Drive = 'K:'
                        Type  = 'SystemManagedSize'
                    }

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Set-AutoManagePaging -ParameterFilter {
                    $State -eq 'Disable'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Get-PageFileSetting -ParameterFilter {
                    $Drive -eq 'K:'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName New-PageFile -ParameterFilter {
                    $PageFileName -eq 'K:\pagefile.sys'
                } -Exactly -Times 0 -Scope It

                Should -Invoke -CommandName Set-PageFileSetting -ParameterFilter {
                    $Drive -eq 'K:'
                } -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When NoPagingFile is required' {
        Context 'When automatic managed page file is enabled and no page file set' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } -MockWith {
                    [PSObject] @{
                        AutomaticManagedPageFile = $true
                        Name                     = 'K:\pagefile.sys'
                    }
                }

                Mock -CommandName Set-AutoManagePaging -ParameterFilter { $State -eq 'Disable' }
                Mock -CommandName Get-PageFileSetting -ParameterFilter { $Drive -eq 'K:' }
                Mock -CommandName Remove-CimInstance
            }

            It 'Should not throw an exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = @{
                        Drive = 'K:'
                        Type  = 'NoPagingFile'
                    }

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Set-AutoManagePaging -ParameterFilter {
                    $State -eq 'Disable'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Get-PageFileSetting -ParameterFilter {
                    $Drive -eq 'K:'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Remove-CimInstance -Exactly -Times 0 -Scope It
            }
        }

        Context 'When automatic managed page file is enabled and page file is set' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } -MockWith {
                    [PSObject] @{
                        AutomaticManagedPageFile = $true
                        Name                     = 'K:\pagefile.sys'
                    }
                }

                Mock -CommandName Set-AutoManagePaging -ParameterFilter { $State -eq 'Disable' }
                Mock -CommandName Get-PageFileSetting -ParameterFilter {
                    $Drive -eq 'K:'
                } -MockWith {
                    [PSObject] @{
                        Name        = 'K:\pagefile.sys'
                        InitialSize = 10
                        MaximumSize = 20
                    }
                }

                Mock -CommandName Remove-CimInstance -RemoveParameterType 'InputObject'
            }

            It 'Should not throw an exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = @{
                        Drive = 'K:'
                        Type  = 'NoPagingFile'
                    }

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Set-AutoManagePaging -ParameterFilter {
                    $State -eq 'Disable'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Get-PageFileSetting -ParameterFilter {
                    $Drive -eq 'K:'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Remove-CimInstance -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'DSC_VirtualMemory\Test-TargetResource' -Tag 'Test' {
    Context 'In desired state' {
        Context 'When automatic managed page file is enabled' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } -MockWith {
                    [PSObject] @{
                        AutomaticManagedPageFile = $true
                        Name                     = 'K:\pagefile.sys'
                    }
                }
            }

            It 'Should return true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = @{
                        Drive       = 'K:'
                        Type        = 'AutoManagePagingFile'
                        InitialSize = 0
                        MaximumSize = 0
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -BeTrue
                }

                Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When automatic managed page file is disabled and no page file set' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } -MockWith {
                    [PSObject] @{
                        AutomaticManagedPageFile = $false
                        Name                     = 'K:\pagefile.sys'
                    }
                }

                Mock -CommandName Get-PageFileSetting -ParameterFilter { $Drive -eq 'K:' }
            }

            It 'Should return true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = @{
                        Drive       = 'K:'
                        Type        = 'NoPagingFile'
                        InitialSize = 0
                        MaximumSize = 0
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -BeTrue
                }

                Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Get-PageFileSetting -ParameterFilter {
                    $Drive -eq 'K:'
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When automatic managed page file is disabled and system managed size is set' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } -MockWith {
                    [PSObject] @{
                        AutomaticManagedPageFile = $false
                        Name                     = 'K:\pagefile.sys'
                    }
                }

                Mock -CommandName Get-PageFileSetting -ParameterFilter {
                    $Drive -eq 'K:'
                } -MockWith {
                    [PSObject] @{
                        InitialSize = 0
                        MaximumSize = 0
                        Name        = "'K:'\"
                    }
                }
            }

            It 'Should return true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = @{
                        Drive       = 'K:'
                        Type        = 'SystemManagedSize'
                        InitialSize = 0
                        MaximumSize = 0
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -BeTrue
                }

                Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Get-PageFileSetting -ParameterFilter {
                    $Drive -eq 'K:'
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When automatic managed page file is disabled and custom size is set' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } -MockWith {
                    [PSObject] @{
                        AutomaticManagedPageFile = $false
                        Name                     = 'K:\pagefile.sys'
                    }
                }

                Mock -CommandName Get-PageFileSetting -ParameterFilter {
                    $Drive -eq 'K:'
                } -MockWith {
                    [PSObject] @{
                        InitialSize = 10
                        MaximumSize = 20
                        Name        = 'K:\'
                    }
                }
            }

            It 'Should return true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0
                    $testParameters = @{
                        Drive       = 'K:'
                        Type        = 'CustomSize'
                        InitialSize = 10
                        MaximumSize = 20
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -BeTrue
                }

                Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Get-PageFileSetting -ParameterFilter {
                    $Drive -eq 'K:'
                } -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'Not in desired state' {
        Context 'When automatic managed page file is enabled' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } -MockWith {
                    [PSObject] @{
                        AutomaticManagedPageFile = $false
                        Name                     = 'K:\pagefile.sys'
                    }
                }
            }

            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = @{
                        Drive       = 'K:'
                        Type        = 'AutoManagePagingFile'
                        InitialSize = 0
                        MaximumSize = 0
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -BeFalse
                }

                Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When automatic managed page file is disabled and no page file set' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } -MockWith {
                    [PSObject] @{
                        AutomaticManagedPageFile = $false
                        Name                     = 'K:\pagefile.sys'
                    }
                }

                Mock -CommandName Get-PageFileSetting -ParameterFilter {
                    $Drive -eq 'K:'
                } -MockWith {
                    [PSObject] @{
                        InitialSize = 10
                        MaximumSize = 20
                        Name        = 'K:\'
                    }
                }
            }

            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = @{
                        Drive       = 'K:'
                        Type        = 'NoPagingFile'
                        InitialSize = 0
                        MaximumSize = 0
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -BeFalse
                }

                Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Get-PageFileSetting -ParameterFilter {
                    $Drive -eq 'K:'
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When automatic managed page file is disabled and system managed size is set' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } -MockWith {
                    [PSObject] @{
                        AutomaticManagedPageFile = $false
                        Name                     = 'K:\pagefile.sys'
                    }
                }

                Mock -CommandName Get-PageFileSetting -ParameterFilter {
                    $Drive -eq 'K:'
                } -MockWith {
                    [PSObject] @{
                        InitialSize = 10
                        MaximumSize = 20
                        Name        = 'K:\'
                    }
                }
            }

            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = @{
                        Drive       = 'K:'
                        Type        = 'SystemManagedSize'
                        InitialSize = 0
                        MaximumSize = 0
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -BeFalse
                }

                Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Get-PageFileSetting -ParameterFilter {
                    $Drive -eq 'K:'
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When automatic managed page file is disabled and custom size is set and initial size differs' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } -MockWith {
                    [PSObject] @{
                        AutomaticManagedPageFile = $false
                        Name                     = 'K:\pagefile.sys'
                    }
                }

                Mock -CommandName Get-PageFileSetting -ParameterFilter {
                    $Drive -eq 'K:'
                } -MockWith {
                    [PSObject] @{
                        InitialSize = 10
                        MaximumSize = 20
                        Name        = 'K:\'
                    }
                }
            }

            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = @{
                        Drive       = 'K:'
                        Type        = 'CustomSize'
                        InitialSize = 10 + 10
                        MaximumSize = 20
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -BeFalse
                }

                Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Get-PageFileSetting -ParameterFilter {
                    $Drive -eq 'K:'
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When automatic managed page file is disabled and custom size is set and maximum size differs' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } -MockWith {
                    [PSObject] @{
                        AutomaticManagedPageFile = $false
                        Name                     = 'K:\pagefile.sys'
                    }
                }

                Mock -CommandName Get-PageFileSetting -ParameterFilter {
                    $Drive -eq 'K:'
                } -MockWith {
                    [PSObject] @{
                        InitialSize = 10
                        MaximumSize = 20
                        Name        = 'K:\'
                    }
                }
            }

            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = @{
                        Drive       = 'K:'
                        Type        = 'CustomSize'
                        InitialSize = 10
                        MaximumSize = 20 + 10
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -BeFalse
                }

                Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Get-PageFileSetting -ParameterFilter {
                    $Drive -eq 'K:'
                } -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'DSC_VirtualMemory\Get-PageFileSetting' -Tag 'Private' {
    Context 'Page file defined on drive K:' {
        BeforeAll {
            Mock -CommandName Get-CimInstance -ParameterFilter {
                $ClassName -eq 'Win32_PageFileSetting' -and
                $Filter -eq "SettingID='pagefile.sys @ K:'"
            } -MockWith {
                [PSObject] @{
                    InitialSize = 10
                    MaximumSize = 20
                    Name        = 'K:\'
                }
            }
        }

        It 'Should return the expected object' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-PageFileSetting -Drive 'K:'
                $result.InitialSize | Should -Be 10
                $result.MaximumSize | Should -Be 20
                $result.Name | Should -Be 'K:\'
            }

            Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                $ClassName -eq 'Win32_PageFileSetting' -and
                $Filter -eq "SettingID='pagefile.sys @ K:'"
            } -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'DSC_VirtualMemory\Set-PageFileSetting' -Tag 'Private' {
    Context 'Set page file settings on drive K:' {
        BeforeAll {
            Mock -CommandName Set-CimInstance -ParameterFilter {
                $Namespace -eq 'root\cimv2' -and
                $Query -eq "Select * from Win32_PageFileSetting where SettingID='pagefile.sys @ K:'" -and
                $Property.InitialSize -eq 10 -and
                $Property.MaximumSize -eq 20
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setPageFileSettingParameters = @{
                    Drive       = 'K:'
                    InitialSize = 10
                    MaximumSize = 20
                }

                { Set-PageFileSetting @setPageFileSettingParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Set-CimInstance -ParameterFilter {
                $Namespace -eq 'root\cimv2' -and
                $Query -eq "Select * from Win32_PageFileSetting where SettingID='pagefile.sys @ K:'" -and
                $Property.InitialSize -eq 10 -and
                $Property.MaximumSize -eq 20
            } -Exactly -Times 1 -Scope It
        }
    }

}

Describe 'DSC_VirtualMemory\Set-AutoManagePaging' -Tag 'Private' {
    Context 'Enable auto managed page file' {
        BeforeAll {
            Mock -CommandName Set-CimInstance -ParameterFilter {
                $Namespace -eq 'root\cimv2' -and
                $Query -eq 'Select * from Win32_ComputerSystem' -and
                $Property.AutomaticManagedPageFile -eq $true
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-AutoManagePaging -State Enable } | Should -Not -Throw
            }

            Should -Invoke -CommandName Set-CimInstance -ParameterFilter {
                $Namespace -eq 'root\cimv2' -and
                $Query -eq 'Select * from Win32_ComputerSystem' -and
                $Property.AutomaticManagedPageFile -eq $true
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'Disable auto managed page file' {
        BeforeAll {
            Mock -CommandName Set-CimInstance -ParameterFilter {
                $Namespace -eq 'root\cimv2' -and
                $Query -eq 'Select * from Win32_ComputerSystem' -and
                $Property.AutomaticManagedPageFile -eq $false
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-AutoManagePaging -State Disable } | Should -Not -Throw
            }

            Should -Invoke -CommandName Set-CimInstance -ParameterFilter {
                $Namespace -eq 'root\cimv2' -and
                $Query -eq 'Select * from Win32_ComputerSystem' -and
                $Property.AutomaticManagedPageFile -eq $false
            } -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'DSC_VirtualMemory\New-PageFile' -Tag 'Private' {
    Context 'Create a new page file' {
        BeforeAll {
            Mock -CommandName New-CimInstance -ParameterFilter {
                $Namespace -eq 'root\cimv2' -and
                $ClassName -eq 'Win32_PageFileSetting' -and
                $Property.Name -eq 'K:\pagefile.sys'
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { New-PageFile -PageFileName 'K:\pagefile.sys' } | Should -Not -Throw
            }

            Should -Invoke -CommandName New-CimInstance -ParameterFilter {
                $Namespace -eq 'root\cimv2' -and
                $ClassName -eq 'Win32_PageFileSetting' -and
                $Property.Name -eq 'K:\pagefile.sys'
            } -Exactly -Times 1 -Scope It
        }
    }
}
