<#
    .SYNOPSIS
        Unit test for PSResource DSC resource.
#>

# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

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

try
{
    $script:dscModuleName = 'ComputerManagementDsc'

    Import-Module -Name $script:dscModuleName

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName

    Describe 'PSResource' {
        Context 'When class is instantiated' {
            It 'Should not throw an exception' {
                InModuleScope -ScriptBlock {
                    { [PSResource]::new() } | Should -Not -Throw
                }
            }

            It 'Should have a default or empty constructor' {
                InModuleScope -ScriptBlock {
                    $instance = [PSResource]::new()
                    $instance | Should -Not -BeNullOrEmpty
                }
            }

            It 'Should be the correct type' {
                InModuleScope -ScriptBlock {
                    $instance = [PSResource]::new()
                    $instance.GetType().Name | Should -Be 'PSResource'
                }
            }
        }
    }

    Describe 'PSResource\Get()' -Tag 'Get' {

        Context 'When the system is in the desired state' {
        }

        Context 'When the system is not in the desired state' {
        }
    }

    Describe 'PSResource\Set()' -Tag 'Set' {
    }

    Describe 'PSResource\Test()' -Tag 'Test' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockPSResourceInstance = [PSResource] @{
                    Name       = 'ComputerManagementDsc'
                    Repository = 'PSGallery'
                }
            }
        }

        Context 'When the system is in the desired state' {
            BeforeAll {
                InModuleScope -ScriptBlock {

                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    $script:mockPSResourceInstance.Test() | Should -BeTrue
                }
            }
        }

        Context 'When the system is not in the desired state' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockPSResourceInstance |
                        # Mock method Compare() which is called by the base method Test ()
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                            return @{
                                Property      = 'Version'
                                ExpectedValue = '8.6.0'
                                ActualValue   = '8.5.0'
                            }
                        }
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    $script:mockPSResourceInstance.Test() | Should -BeFalse
                }
            }
        }
    }

    Describe 'PSResource\GetCurrentState()' -Tag 'GetCurrentState' {
        Context 'When the system is in the desired state' {
        }

        Context 'When the system is not in the desired state' {
        }
    }

    Describe 'PSResource\Modify()' -Tag 'Modify' {
    }

    Describe 'PSResource\TestSingleInstance()' -Tag 'TestSingleInstance' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockPSResourceInstance = [PSResource] @{
                    Name       = 'ComputerManagementDsc'
                    Repository = 'PSGallery'
                    Ensure     = 'Present'
                }
            }
        }
        Context 'When there are zero resources installed' {
            BeforeAll {
                Mock -CommandName Get-Module
            }

            It 'Should Correctly return False when Zero Resources are Installed' {

                InModuleScope -ScriptBlock {
                    $script:mockPSResourceInstance.TestSingleInstance() | Should -BeFalse
                }

                Assert-MockCalled Get-Module -Exactly -Times 1 -Scope It
            }
        }

        Context 'When there is one resource installed' {
            BeforeAll {
                Mock -CommandName Get-Module -MockWith {
                    return @{
                        Name = 'ComputerManagementDsc'
                    }
                }
            }

            It 'Should Correctly return True when One Resource is Installed' {
                InModuleScope -ScriptBlock {
                    $script:mockPSResourceInstance.TestSingleInstance() | Should -BeTrue
                }

                Assert-MockCalled Get-Module -Exactly -Times 1 -Scope It
            }
        }

        Context 'When there are multiple resources installed' {
            BeforeAll {
                Mock -CommandName Get-Module -MockWith {
                    return @(
                        @{
                            Name    = 'ComputerManagementDsc'
                            Version = '8.5.0'
                        },
                        @{
                            Name    = 'ComputerManagementDsc'
                            Version = '8.6.0'
                        }
                    )
                }
            }
        }
        It 'Should Correctly return False' {
            InModuleScope -ScriptBlock {
                $script:mockPSResourceInstance.TestSingleInstance() | Should -BeFalse
            }

            Assert-MockCalled Get-Module -Exactly -Times 1 -Scope It
        }
    }

    Describe 'PSResource\GetLatestVersion()' -Tag 'GetLatestVersion' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockPSResourceInstance = [PSResource] @{
                    Name       = 'ComputerManagementDsc'
                    Ensure     = 'Present'
                }
            }
        }

        Context 'When there is one resource on the repository' {
            BeforeEach {
                Mock -CommandName Find-Module -MockWith {
                    return New-MockObject -Type Version -Properties {Version = '8.6.0'}
                }
            }

            It 'Should return the correct version' {

                InModuleScope -ScriptBlock {
                    $script:mockPSResourceInstance.GetLatestVersion() | Should -Be '8.6.0'
                }

                Assert-MockCalled Find-Module -Exactly -Times 1 -Scope It
            }
        }
    }

    Describe 'PSResource\GetInstalledResource()' -Tag 'GetInstalledResource' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockPSResourceInstance = [PSResource] @{
                    Name       = 'ComputerManagementDsc'
                    Ensure     = 'Present'
                }
            }
        }

        It 'Should return nothing' {
            InModuleScope -ScriptBlock {
                Mock -CommandName Get-Module
                { $script:mockPSResourceInstance.GetInstalledResource() | Should -BeNullOrEmpty }
            }
        }

        It 'Should return one object' {
            InModuleScope -ScriptBlock {
                Mock -CommandName Get-Module -MockWith {
                    return @(New-MockObject -Type System.Management.Automation.PSModuleInfo)
                }
                {
                    $script:mockPSResourceInstance.GetInstalledResource().Count | Should -Be 1
                }
            }
        }

        It 'Should return two objects' {
            InModuleScope -ScriptBlock {
                Mock -CommandName Get-Module -MockWith {
                    return @(
                        New-MockObject -Type System.Management.Automation.PSModuleInfo,
                        New-MockObject -Type System.Management.Automation.PSModuleInfo
                    )
                }
                {
                    $script:mockPSResourceInstance.GetInstalledResource().Count | Should -Be 2
                }
            }
        }
    }

    Describe 'PSResource\GetFullVersion()' -Tag 'GetFullVersion' {
    }

    Describe 'PSResource\TestPrerelease()' -Tag 'TestPrerelease' {

    }

    Describe 'PSResource\TestLatestVersion()' -Tag 'TestLatestVersion' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockPSResourceInstance = [PSResource] @{
                    Name       = 'ComputerManagementDsc'
                    Repository = 'PSGallery'
                    Ensure     = 'Present'
                } | Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetLatestVersion' -Value {
                    return '8.6.0'
                }
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                $script:mockPSResourceInstance.TestLatestVersion('8.6.0') | Should -BeTrue
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                $script:mockPSResourceInstance.TestLatestVersion('8.5.0') | Should -BeFalse
            }
        }
    }

    Describe 'PSResource\SetSingleInstance()' -Tag 'TestSingleInstance' {
        InModuleScope -ScriptBlock {
            $script:mockPSResourceInstance = [PSResource] @{
                Name           = 'ComputerManagementDsc'
                Ensure         = 'Present'
                SingleInstance = $True
            }
        }

        It 'Should not throw and return True when one resource is present' {
            InModuleScope -ScriptBlock {
                $script:mockPSResourceInstance.TestSingleInstance(
                    @(
                        @{
                            Name    = 'ComputerManagementDsc'
                            Version = '8.6.0'
                        }
                    )
                ) | Should -BeTrue
            }
        }

        It 'Should not throw and return False when zero resources are present' {
            InModuleScope -ScriptBlock {
                $script:mockPSResourceInstance.TestSingleInstance(
                    @()
                ) | Should -BeFalse
            }
        }

        It 'Should not throw and return False when more than one resource is present' {
            InModuleScope -ScriptBlock {
                $script:mockPSResourceInstance.TestSingleInstance(
                    @(
                        @{
                            Name    = 'ComputerManagementDsc'
                            Version = '8.6.0'
                        },
                        @{
                            Name    = 'ComputerManagementDsc'
                            Version = '8.5.0'
                        }
                    )
                ) | Should -BeFalse
            }
        }
    }

    Describe 'PSResource\GetLatestVersion()' -Tag 'GetLatestVersion' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockPSResourceInstance = [PSResource] @{
                    Name           = 'ComputerManagementDsc'
                    Ensure         = 'Present'
                }
            }
        }

        Context 'When only one resource is installed' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockPSResourceInstance |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'FindResource' -Value {
                        @{
                            Name    = 'ComputerManagementDsc'
                            Version = '8.6.0'
                        }
                    }
                }
            }
            It 'Should return the latest version installed on the system' {
                InModuleScope -ScriptBlock {
                    $script:mockPSResourceInstance.GetLatestVersion() | Should -Be '8.6.0'
                }
            }
        }
    }

    Describe 'PSResource\SetLatest()' -Tag 'SetLatest' {

    }
}
finally
{
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}
