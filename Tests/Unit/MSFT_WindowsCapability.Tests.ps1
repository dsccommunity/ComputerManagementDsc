#region HEADER
$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'MSFT_WindowsCapability'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

# Unit Test Template Version: 1.2.4
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath 'DscResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -ResourceType 'Mof' `
    -TestType Unit
#endregion HEADER

# Begin Testing
try
{
    InModuleScope $script:dscResourceName {
        $script:testResourceName = 'Test'

        $script:testAndSetTargetResourceParameters = @{
            Name     = $script:testResourceName
            LogLevel = 'WarningsInfo'
            LogPath  = Join-Path -Path $ENV:Temp -ChildPath 'Logfile.log'
        }

        $getWindowsCapabilityIsInstalled = {
            @{
                Name     = 'XPS.Viewer~~~~0.0.1.0'
                State    = 'Installed'
            }
        }

        $getWindowsCapabilityIsNotInstalled = {
            @{
                Name     = 'XPS.Viewer~~~~0.0.1.0'
                State    = 'NotPresent'
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

        Describe "MSFT_WindowsCapability\Get-TargetResource" {
            Context 'When a Windows Capability is enabled' {
                Mock -CommandName Get-WindowsCapability `
                    -MockWith $getWindowsCapabilityIsInstalled `
                    -ModuleName 'MSFT_WindowsCapability' `
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
                    -ModuleName 'MSFT_WindowsCapability' `
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

        Describe "MSFT_WindowsCapability\Test-TargetResource" {
            Context 'When a Windows Capability is enabled' {
                Mock -CommandName Get-WindowsCapability `
                    -MockWith $getWindowsCapabilityIsInstalled `
                    -ModuleName 'MSFT_WindowsCapability' `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:testTargetResourceResult = Test-TargetResource $script:testAndSetTargetResourceParameters
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
                    -ModuleName 'MSFT_WindowsCapability' `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:testTargetResourceResult = Test-TargetResource $script:testAndSetTargetResourceParameters
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

        Describe "MSFT_WindowsCapability\Set-TargetResource" {

            Context 'When a Windows Capability is not enabled' {
                Mock -CommandName Add-WindowsCapability `
                -MockWith $getWindowsCapabilityIsInstalled `
                -ModuleName 'MSFT_WindowsCapability' `
                -Verifiable

                It 'Should call Add-WindowsCapability when Ensure set to Present' {
                    { Set-TargetResource -Name $testResourceName } | Should -Not -Throw
                    Assert-MockCalled -CommandName Add-WindowsCapability -Times 1 -Exactly -Scope It
                }

                It 'Should call all verifiable mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'When a Windows Capability is already enabled' {
                Mock -CommandName Add-WindowsCapability `
                -MockWith $getWindowsCapabilityIsInstalled `
                -ModuleName 'MSFT_WindowsCapability' `
                -Verifiable

                It 'Should not call Add-WindowsCapability when Windows Capability is already enabled' {
                    { Set-TargetResource -Name $testResourceName } | Should -Not -Throw
                    Assert-MockCalled -CommandName Add-WindowsCapability -Times 0 -Exactly -Scope It
                }

                It 'Should call all verifiable mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'When a Windows Capability is already disabled' {
                Mock -CommandName Add-WindowsCapability `
                -MockWith $getWindowsCapabilityIsNotInstalled `
                -ModuleName 'MSFT_WindowsCapability' `
                -Verifiable

                It 'Should not call Remove-WindowsCapability when Windows Capability is already disabled' {
                    { Set-TargetResource -Name $testResourceName } | Should -Not -Throw
                    Assert-MockCalled -CommandName Remove-WindowsCapability -Times 0 -Exactly -Scope It
                }

                It 'Should call all verifiable mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'When a Windows Capability is enabled and should not' {
                Mock -CommandName Remove-WindowsCapability `
                -MockWith $getWindowsCapabilityIsInstalled `
                -ModuleName 'MSFT_WindowsCapability' `
                -Verifiable

                It 'Should call Remove-WindowsCapability when Windows Capability is enabled' {
                    { Set-TargetResource -Name $testResourceName } | Should -Not -Throw
                    Assert-MockCalled -CommandName Remove-WindowsCapability -Times 1 -Exactly -Scope It
                }

                It 'Should call all verifiable mocks' {
                    Assert-VerifiableMock
                }
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
