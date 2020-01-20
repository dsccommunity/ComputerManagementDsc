$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'DSC_WindowsCapability'

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
    InModuleScope $script:dscResourceName {
        $script:testResourceName = 'Test'

        $script:testAndSetTargetResourceParametersPresent = @{
            Name   = $script:testResourceName
            Ensure = 'Present'
        }

        $script:testAndSetTargetResourceParametersAbsent = @{
            Name   = $script:testResourceName
            Ensure = 'Absent'
        }

        $getWindowsCapabilityIsInstalled = {
            @{
                Name   = 'Test'
                State  = 'Installed'
                Ensure = 'Present'
            }
        }

        $getWindowsCapabilityIsNotInstalled = {
            @{
                Name   = 'Test'
                State  = 'NotPresent'
                Ensure = 'Absent'
            }
        }

        function Get-WindowsCapability
        {
            [CmdletBinding()]
            param
            (
                [Parameter()]
                [System.String]
                $Name,

                [Parameter()]
                [Switch]
                $Online = $true
            )
        }

        function Add-WindowsCapability
        {
            [CmdletBinding()]
            param
            (
                [Parameter()]
                [System.String]
                $Name,

                [Parameter()]
                [Switch]
                $Online = $true
            )
        }

        function Remove-WindowsCapability
        {
            [CmdletBinding()]
            param
            (
                [Parameter()]
                [System.String]
                $Name,

                [Parameter()]
                [Switch]
                $Online = $true
            )
        }

        Describe 'DSC_WindowsCapability\Get-TargetResource' {
            Context 'When a Windows Capability is enabled and it should' {
                Mock -CommandName Get-WindowsCapability `
                    -MockWith $getWindowsCapabilityIsInstalled `
                    -ModuleName 'DSC_WindowsCapability' `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:getTargetResourceResult = Get-TargetResource -Name $script:testResourceName -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return expected result' {
                    $script:getTargetResourceResult.Name | Should -Be $script:testResourceName
                    $script:getTargetResourceResult.State | Should -Be 'Installed'
                }

                It 'Should call all verifiable mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'When a Windows Capability is not enabled' {
                Mock -CommandName Get-WindowsCapability `
                    -MockWith $getWindowsCapabilityIsNotInstalled `
                    -ModuleName 'DSC_WindowsCapability' `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:getTargetResourceResult = Get-TargetResource -Name $script:testResourceName -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return expected result' {
                    $script:getTargetResourceResult.Name | Should -Be $script:testResourceName
                    $script:getTargetResourceResult.State | Should -Be 'NotPresent'
                }

                It 'Should call all verifiable mocks' {
                    Assert-VerifiableMock
                }
            }
        }

        Describe 'DSC_WindowsCapability\Test-TargetResource' {
            Context 'When a Windows Capability is enabled' {
                Mock -CommandName Get-WindowsCapability `
                    -MockWith $getWindowsCapabilityIsInstalled `
                    -ModuleName 'DSC_WindowsCapability' `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:testTargetResourceResult = Test-TargetResource $script:testAndSetTargetResourceParametersPresent
                    } | Should -Not -Throw
                }

                It 'Should return true' {
                    $script:testTargetResourceResult | Should -BeTrue
                }

                It 'Should call all verifiable mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'When a Windows Capability is not enabled' {
                Mock -CommandName Get-WindowsCapability `
                    -MockWith $getWindowsCapabilityIsNotInstalled `
                    -ModuleName 'DSC_WindowsCapability' `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:testTargetResourceResult = Test-TargetResource $script:testAndSetTargetResourceParametersAbsent
                    } | Should -Not -Throw
                }

                It 'Should return true' {
                    $script:testTargetResourceResult | Should -BeTrue
                }

                It 'Should call all verifiable mocks' {
                    Assert-VerifiableMock
                }
            }
        }

        Describe 'DSC_WindowsCapability\Set-TargetResource' {
            Context 'When a Windows Capability is not enabled' {
                Mock -CommandName Get-WindowsCapability `
                    -MockWith $getWindowsCapabilityIsNotInstalled `
                    -ModuleName 'DSC_WindowsCapability' `
                    -Verifiable

                Mock -CommandName Add-WindowsCapability -MockWith { }

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource @script:testAndSetTargetResourceParametersAbsent
                    } | Should -Not -Throw
                }

                It 'Should call Add-WindowsCapability when Ensure set to Present' {
                    {
                        Set-TargetResource -Name $testResourceName
                    } | Should -Not -Throw
                    Assert-MockCalled -CommandName Add-WindowsCapability -Times 1 -Exactly -Scope It
                }

                It 'Should call Get-WindowsCapability when Ensure set to Present' {
                    { Set-TargetResource -Name $testResourceName } | Should -Not -Throw
                    Assert-MockCalled -CommandName Get-WindowsCapability -Times 1 -Exactly -Scope It
                }
            }

            Context 'When a Windows Capability is already enabled' {
                Mock -CommandName Get-WindowsCapability `
                    -MockWith $getWindowsCapabilityIsInstalled `
                    -ModuleName 'DSC_WindowsCapability' `
                    -Verifiable

                Mock -CommandName Add-WindowsCapability -MockWith { }

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource @script:testAndSetTargetResourceParametersPresent
                    } | Should -Not -Throw
                }

                It 'Should not call Add-WindowsCapability when Windows Capability is already enabled' {
                    { Set-TargetResource -Name $testResourceName } | Should -Not -Throw
                    Assert-MockCalled -CommandName Add-WindowsCapability -Times 0 -Exactly -Scope It
                }

                It 'Should call Get-WindowsCapability when when Windows Capability is already enabled' {
                    { Set-TargetResource -Name $testResourceName } | Should -Not -Throw
                    Assert-MockCalled -CommandName Get-WindowsCapability -Times 1 -Exactly -Scope It
                }
            }

            Context 'When a Windows Capability is already disabled' {
                Mock -CommandName Get-WindowsCapability `
                    -MockWith $getWindowsCapabilityIsNotInstalled `
                    -ModuleName 'DSC_WindowsCapability' `
                    -Verifiable

                Mock -CommandName Remove-WindowsCapability -MockWith { }

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource @script:testAndSetTargetResourceParametersPresent
                    } | Should -Not -Throw
                }

                It 'Should not call Remove-WindowsCapability when Windows Capability is already disabled' {
                    {
                        Set-TargetResource -Name $testResourceName
                    } | Should -Not -Throw
                    Assert-MockCalled -CommandName Remove-WindowsCapability -Times 0 -Exactly -Scope It
                }

                It 'Should call Get-WindowsCapability when when Windows Capability is already enabled' {
                    { Set-TargetResource -Name $testResourceName } | Should -Not -Throw
                    Assert-MockCalled -CommandName Get-WindowsCapability -Times 1 -Exactly -Scope It
                }
            }

            Context 'When a Windows Capability is enabled and should not be' {
                Mock -CommandName Get-WindowsCapability `
                    -MockWith $getWindowsCapabilityIsInstalled `
                    -ModuleName 'DSC_WindowsCapability' `
                    -Verifiable

                Mock -CommandName Remove-WindowsCapability -MockWith { }

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource @script:testAndSetTargetResourceParametersAbsent
                    } | Should -Not -Throw
                }

                It 'Should call Remove-WindowsCapability when Ensure set to Absent' {
                    { Set-TargetResource -Name $testResourceName -Ensure 'Absent' } | Should -Not -Throw
                    Assert-MockCalled -CommandName Remove-WindowsCapability -Times 1 -Exactly -Scope It
                }

                It 'Should call Get-WindowsCapability when Windows Capability is set to Absent' {
                    { Set-TargetResource -Name $testResourceName -Ensure 'Absent' } | Should -Not -Throw
                    Assert-MockCalled -CommandName Get-WindowsCapability -Times 1 -Exactly -Scope It
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
