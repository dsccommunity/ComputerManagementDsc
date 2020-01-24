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
        $script:testCapabilityName = 'Test'

        $script:testAndSetTargetResourceParametersPresent = @{
            Name    = $script:testCapabilityName
            Ensure  = 'Present'
            Verbose = $true
        }

        $script:testAndSetTargetResourceParametersAbsent = @{
            Name    = $script:testCapabilityName
            Ensure  = 'Absent'
            Verbose = $true
        }

        $script:getWindowsCapabilityDoesNotExist = {
            @{
                Name     = ''
                State    = ''
                LogLevel = 'Errors'
                LogPath  = 'LogPath'
            }
        }

        $script:getWindowsCapabilityIsInstalled = {
            @{
                Name     = $script:testCapabilityName
                State    = 'Installed'
                LogLevel = 'Errors'
                LogPath  = 'LogPath'
            }
        }

        $script:getWindowsCapabilityIsNotInstalled = {
            @{
                Name     = $script:testCapabilityName
                State    = 'NotPresent'
                LogLevel = 'Errors'
                LogPath  = 'LogPath'
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
            Context 'When a Windows Capability is installed' {
                Mock -CommandName Get-WindowsCapability `
                    -MockWith $script:getWindowsCapabilityIsInstalled

                It 'Should not throw an exception' {
                    {
                        $script:getTargetResourceResult = Get-TargetResource `
                            -Name $script:testCapabilityName -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return expected result' {
                    $script:getTargetResourceResult.Name | Should -Be $script:testCapabilityName
                    $script:getTargetResourceResult.Ensure | Should -Be 'Present'
                    $script:getTargetResourceResult.LogLevel | Should -Be 'Errors'
                    $script:getTargetResourceResult.LogPath | Should -Be 'LogPath'
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-WindowsCapability `
                        -ParameterFilter {
                        $Name -eq $script:testCapabilityName -and `
                            $Online -eq $true
                    } `
                        -Exactly `
                        -Times 1
                }
            }

            Context 'When a Windows Capability is not installed' {
                Mock -CommandName Get-WindowsCapability `
                    -MockWith $script:getWindowsCapabilityIsNotInstalled

                It 'Should not throw an exception' {
                    {
                        $script:getTargetResourceResult = Get-TargetResource `
                            -Name $script:testCapabilityName -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return expected result' {
                    $script:getTargetResourceResult.Name | Should -Be $script:testCapabilityName
                    $script:getTargetResourceResult.Ensure | Should -Be 'Absent'
                    $script:getTargetResourceResult.LogLevel | Should -Be 'Errors'
                    $script:getTargetResourceResult.LogPath | Should -Be 'LogPath'
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-WindowsCapability `
                        -ParameterFilter {
                        $Name -eq $script:testCapabilityName -and `
                            $Online -eq $true
                    } `
                        -Exactly `
                        -Times 1
                }
            }

            Context 'When a Windows Capability does not exist' {
                Mock -CommandName Get-WindowsCapability `
                    -MockWith $script:getWindowsCapabilityDoesNotExist

                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($script:localizedData.CapabilityNameNotFound -f $script:testCapabilityName) `
                    -ArgumentName 'Name'

                It 'Should throw expected exception' {
                    {
                        $script:getTargetResourceResult = Get-TargetResource `
                            -Name $script:testCapabilityName -Verbose
                    } | Should -Throw $errorRecord
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-WindowsCapability `
                        -ParameterFilter {
                        $Name -eq $script:testCapabilityName -and `
                            $Online -eq $true
                    } `
                        -Exactly `
                        -Times 1
                }
            }
        }

        Describe 'DSC_WindowsCapability\Test-TargetResource' {
            Context 'When a Windows Capability is installed and should be' {
                Mock -CommandName Get-WindowsCapability `
                    -MockWith $script:getWindowsCapabilityIsInstalled

                It 'Should not throw an exception' {
                    {
                        $script:testTargetResourceResult = Test-TargetResource @script:testAndSetTargetResourceParametersPresent
                    } | Should -Not -Throw
                }

                It 'Should return true' {
                    $script:testTargetResourceResult | Should -BeTrue
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-WindowsCapability `
                        -ParameterFilter {
                        $Name -eq $script:testCapabilityName -and `
                            $Online -eq $true
                    } `
                        -Exactly `
                        -Times 1
                }
            }

            Context 'When a Windows Capability is not installed and should be' {
                Mock -CommandName Get-WindowsCapability `
                    -MockWith $script:getWindowsCapabilityIsNotInstalled

                It 'Should not throw an exception' {
                    {
                        $script:testTargetResourceResult = Test-TargetResource @script:testAndSetTargetResourceParametersPresent
                    } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:testTargetResourceResult | Should -BeFalse
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-WindowsCapability `
                        -ParameterFilter {
                        $Name -eq $script:testCapabilityName -and `
                            $Online -eq $true
                    } `
                        -Exactly `
                        -Times 1
                }
            }

            Context 'When a Windows Capability is installed and should not be' {
                Mock -CommandName Get-WindowsCapability `
                    -MockWith $script:getWindowsCapabilityIsInstalled

                It 'Should not throw an exception' {
                    {
                        $script:testTargetResourceResult = Test-TargetResource @script:testAndSetTargetResourceParametersAbsent
                    } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:testTargetResourceResult | Should -BeFalse
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-WindowsCapability `
                        -ParameterFilter {
                        $Name -eq $script:testCapabilityName -and `
                            $Online -eq $true
                    } `
                        -Exactly `
                        -Times 1
                }
            }

            Context 'When a Windows Capability is not installed and should not be' {
                Mock -CommandName Get-WindowsCapability `
                    -MockWith $script:getWindowsCapabilityIsNotInstalled

                It 'Should not throw an exception' {
                    {
                        $script:testTargetResourceResult = Test-TargetResource @script:testAndSetTargetResourceParametersAbsent
                    } | Should -Not -Throw
                }

                It 'Should return true' {
                    $script:testTargetResourceResult | Should -BeTrue
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-WindowsCapability `
                        -ParameterFilter {
                        $Name -eq $script:testCapabilityName -and `
                            $Online -eq $true
                    } `
                        -Exactly `
                        -Times 1
                }
            }
        }

        Describe 'DSC_WindowsCapability\Set-TargetResource' {
            BeforeAll {
                Mock -CommandName Add-WindowsCapability
                Mock -CommandName Remove-WindowsCapability
            }

            Context 'When a Windows Capability is installed and should be' {
                Mock -CommandName Get-WindowsCapability `
                    -MockWith $script:getWindowsCapabilityIsNotInstalled

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource @script:testAndSetTargetResourceParametersAbsent
                    } | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-WindowsCapability `
                        -ParameterFilter {
                        $Name -eq $script:testCapabilityName -and `
                            $Online -eq $true
                    } `
                        -Exactly `
                        -Times 1

                    Assert-MockCalled `
                        -CommandName Add-WindowsCapability `
                        -Exactly `
                        -Times 0

                    Assert-MockCalled `
                        -CommandName Remove-WindowsCapability `
                        -Exactly `
                        -Times 0
                }
            }

            Context 'When a Windows Capability is not installed and should be' {
                Mock -CommandName Get-WindowsCapability `
                    -MockWith $script:getWindowsCapabilityIsNotInstalled

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource @script:testAndSetTargetResourceParametersPresent
                    } | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-WindowsCapability `
                        -ParameterFilter {
                        $Name -eq $script:testCapabilityName -and `
                            $Online -eq $true
                    } `
                        -Exactly `
                        -Times 1

                    Assert-MockCalled `
                        -CommandName Add-WindowsCapability `
                        -ParameterFilter {
                        $Name -eq $script:testCapabilityName -and `
                            $Online -eq $true
                    } `
                        -Exactly `
                        -Times 1

                    Assert-MockCalled `
                        -CommandName Remove-WindowsCapability `
                        -Exactly `
                        -Times 0
                }
            }

            Context 'When a Windows Capability is installed and should not be' {
                Mock -CommandName Get-WindowsCapability `
                    -MockWith $script:getWindowsCapabilityIsInstalled

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource @script:testAndSetTargetResourceParametersAbsent
                    } | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-WindowsCapability `
                        -ParameterFilter {
                        $Name -eq $script:testCapabilityName -and `
                            $Online -eq $true
                    } `
                        -Exactly `
                        -Times 1

                    Assert-MockCalled `
                        -CommandName Add-WindowsCapability `
                        -Exactly `
                        -Times 0

                    Assert-MockCalled `
                        -CommandName Remove-WindowsCapability `
                        -ParameterFilter {
                        $Name -eq $script:testCapabilityName -and `
                            $Online -eq $true
                    } `
                        -Exactly `
                        -Times 1
                }
            }

            Context 'When a Windows Capability is not installed and should not be' {
                Mock -CommandName Get-WindowsCapability `
                    -MockWith $script:getWindowsCapabilityIsNotInstalled

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource @script:testAndSetTargetResourceParametersAbsent
                    } | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-WindowsCapability `
                        -ParameterFilter {
                        $Name -eq $script:testCapabilityName -and `
                            $Online -eq $true
                    } `
                        -Exactly `
                        -Times 1

                    Assert-MockCalled `
                        -CommandName Add-WindowsCapability `
                        -Exactly `
                        -Times 0

                    Assert-MockCalled `
                        -CommandName Remove-WindowsCapability `
                        -Exactly `
                        -Times 0
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
