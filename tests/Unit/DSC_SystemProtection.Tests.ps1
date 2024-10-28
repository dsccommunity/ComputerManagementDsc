<#
    .SYNOPSIS
        Unit test for DSC_SystemProtection DSC resource.

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
    $script:dscModuleName   = 'ComputerManagementDsc'
    $script:dscResourceName = 'DSC_SystemProtection'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName']          = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName']        = $script:dscResourceName
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

Describe "DSC_SystemProtection\Get-TargetResource" -Tag 'Get' {
    Context 'When running on a workstation OS' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $workstationMock = @{
                    ParameterFilter = $([scriptblock]::Create('$ClassName -eq ''Win32_OperatingSystem'''))
                    MockWith        = $([scriptblock]::Create('@{ ProductType = 1 }'))
                }

                Mock -CommandName Get-CimInstance @workstationMock
                Mock -CommandName Get-SystemProtectionState { 'Present' }
                Mock -CommandName Get-SppRegistryValue { '\\?\Volume{f3f152fa-a383-4fb9-a823-fb7e1bfd1db1}\:(P%3A)' }
                Mock -CommandName Get-DiskUsageConfiguration { 5 }
            }
        }

        Context 'When getting the target resource' {
            It 'Should throw when the system is corrupt' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $errorMessage = $script:localizedData.GetEnabledDrivesFailure

                    Mock -CommandName Get-SppRegistryValue { $null }

                    { Get-TargetResource -Ensure 'Present' -DriveLetter 'P' } |
                        Should -Throw -ExpectedMessage $errorMessage.Exception.Message
                }
            }
        }

        Context 'When getting the target resource with Drive P protected' {
            It 'Should get the system protection settings' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $protectionSettings = Get-TargetResource -Ensure 'Present' -DriveLetter 'P'

                    $protectionSettings | Should -BeOfType Hashtable
                    $protectionSettings.Ensure | Should -Be 'Present'
                    $protectionSettings.DriveLetter | Should -Be 'P'
                    $protectionSettings.DiskUsage | Should -Be 5
                }
            }
        }
    }

    Context 'When running on a server OS' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $serverMock = @{
                    ParameterFilter = $([scriptblock]::Create('$ClassName -eq ''Win32_OperatingSystem'''))
                    MockWith        = $([scriptblock]::Create('@{ ProductType = 3 }'))
                }

                Mock -CommandName Get-CimInstance @serverMock
            }
        }

        Context 'When getting the target resource' {
            It 'Should return Absent and write a warning on a server operating system' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    Mock -CommandName Write-Warning

                    $protectionSettings = Get-TargetResource -Ensure 'Present' -DriveLetter 'C'

                    $protectionSettings.Ensure | Should -Be 'Absent'
                    Assert-MockCalled -CommandName Write-Warning -Times 1
                }
            }
        }
    }
}

Describe "DSC_SystemProtection\Test-TargetResource" -Tag 'Test' {
    Context 'When running on a workstation OS' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $workstationMock = @{
                    ParameterFilter = $([scriptblock]::Create('$ClassName -eq ''Win32_OperatingSystem'''))
                    MockWith        = $([scriptblock]::Create('@{ ProductType = 1 }'))
                }

                Mock -CommandName Get-CimInstance @workstationMock
                Mock -CommandName Get-SystemProtectionState { 'Present' }
                Mock -CommandName Get-SppRegistryValue { '\\?\Volume{f3f152fa-a383-4fb9-a823-fb7e1bfd1db1}\:(P%3A)' }
                Mock -CommandName Get-DiskUsageConfiguration { 5 }
            }
        }

        Context 'When testing the target resource' {
            It 'Should throw when Ensure is neither Present nor Absent' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    { Test-TargetResource -Ensure 'Purgatory' } | Should -Throw
                }
            }

            It 'Should throw when DriveLetter is invalid' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    { Test-TargetResource -Ensure 'Present' -DriveLetter '5' } | Should -Throw
                    { Test-TargetResource -Ensure 'Present' -DriveLetter 'CD' } | Should -Throw
                }
            }

            It 'Should throw when DiskUsage is less than 1' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    { Test-TargetResource -Ensure 'Present' -DriveLetter 'P' -DiskUsage 0 } | Should -Throw
                }
            }

            It 'Should throw when DiskUsage is greater than 100' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    { Test-TargetResource -Ensure 'Present' -DriveLetter 'P' -DiskUsage 101 } | Should -Throw
                }
            }
        }

        Context 'When system protection is in the desired state' {
            It 'Should return true when only the drive letter is specified' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Test-TargetResource -Ensure 'Present' -DriveLetter 'P'

                    $result | Should -BeTrue
                }
            }

            It 'Should return true when drive letter and disk usage are specified' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Test-TargetResource -Ensure 'Present' -DriveLetter 'P' -DiskUsage 5

                    $result | Should -BeTrue
                }
            }
        }

        Context 'When system protection is not in the desired state' {
            It 'Should return false when drive protection changes are necessary' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Test-TargetResource -Ensure 'Absent' -DriveLetter 'P'

                    $result | Should -BeFalse
                }
            }

            It 'Should return false when disk usage changes are necessary' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Test-TargetResource -Ensure 'Present' -DriveLetter 'P' -DiskUsage 25

                    $result | Should -BeFalse
                }
            }
        }
    }

    Context 'When running on a server OS' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $serverMock = @{
                    ParameterFilter = $([scriptblock]::Create('$ClassName -eq ''Win32_OperatingSystem'''))
                    MockWith        = $([scriptblock]::Create('@{ ProductType = 3 }'))
                }

                Mock -CommandName Get-CimInstance @serverMock
            }
        }

        It 'Should return Present and write warnings on a server operating system' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Mock -CommandName Write-Warning

                $desiredState = Test-TargetResource -Ensure 'Present' -DriveLetter 'C'

                $desiredState | Should -BeTrue
                Assert-MockCalled -CommandName Write-Warning -Times 2
            }
        }
    }
}

Describe "DSC_SystemProtection\Set-TargetResource" -Tag 'Set' {
    Context 'When running on a workstation OS' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $workstationMock = @{
                    ParameterFilter = $([scriptblock]::Create('$ClassName -eq ''Win32_OperatingSystem'''))
                    MockWith        = $([scriptblock]::Create('@{ ProductType = 1 }'))
                }

                Mock -CommandName Get-CimInstance @workstationMock
                Mock -CommandName Get-SystemProtectionState { 'Present' }
                Mock -CommandName Get-SppRegistryValue { '\\?\Volume{f3f152fa-a383-4fb9-a823-fb7e1bfd1db1}\:(P%3A)' }
                Mock -CommandName Get-DiskUsageConfiguration { 5 }
            }
        }

        Context 'When setting the target resource' {
            It 'Should throw when Ensure is neither Present nor Absent' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    { Set-TargetResource -Ensure 'Purgatory' } | Should -Throw
                }
            }

            It 'Should throw when DriveLetter is invalid' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    { Set-TargetResource -Ensure 'Present' -DriveLetter '5' } | Should -Throw
                    { Set-TargetResource -Ensure 'Present' -DriveLetter 'CD' } | Should -Throw
                }
            }

            It 'Should throw when DiskUsage is less than 1' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    { Set-TargetResource -Ensure 'Present' -DriveLetter 'P' -DiskUsage 0 } | Should -Throw
                }
            }

            It 'Should throw when DiskUsage is greater than 100' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    { Set-TargetResource -Ensure 'Present' -DriveLetter 'P' -DiskUsage 110 } | Should -Throw
                }
            }

            It 'Should throw when the operating system cannot enable system protection' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $errorMessage = $script:localizedData.EnableComputerRestoreFailure -f 'C'

                    Mock -CommandName Enable-ComputerRestore { throw  }

                    { Set-TargetResource -Ensure 'Present' -DriveLetter 'C' } |
                        Should -Throw -ExpectedMessage $errorMessage.Exception.Message
                }
            }

            It 'Should throw when the operating system cannot disable system protection' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $errorMessage = $script:localizedData.EnableComputerRestoreFailure -f 'C'

                    Mock -CommandName Disable-ComputerRestore { throw  }

                    { Set-TargetResource -Ensure 'Absent' -DriveLetter 'C' } |
                        Should -Throw -ExpectedMessage $errorMessage.Exception.Message
                }
            }
        }

        Context 'When configuration is required' {
            It 'Should enable system protection for Drive P' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    Mock -CommandName Enable-ComputerRestore

                    Set-TargetResource -Ensure 'Present' -DriveLetter 'P'

                    Assert-MockCalled -CommandName Enable-ComputerRestore -Times 1
                }
            }

            It 'Should disable system protection for Drive P' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    Mock -CommandName Disable-ComputerRestore

                    Set-TargetResource -Ensure 'Absent' -DriveLetter 'P'

                    Assert-MockCalled -CommandName Disable-ComputerRestore
                }
            }

            It 'Should enable set maximum disk usage to 20%' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    Mock -CommandName Enable-ComputerRestore
                    Mock -CommandName Invoke-VssAdmin { @{ ExitCode = 0 } }

                    Set-TargetResource -Ensure 'Present' -DriveLetter 'P' -DiskUsage 20

                    Assert-MockCalled -CommandName Enable-ComputerRestore -Times 1
                    Assert-MockCalled -CommandName Invoke-VssAdmin -Times 1
                }
            }

            It 'Should throw if the attempt to resize fails without the Force option' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $errorMessage = $script:localizedData.VssShadowResizeFailure -f 'P'

                    Mock -CommandName Enable-ComputerRestore
                    Mock -CommandName Invoke-VssAdmin -ParameterFilter { $Operation -eq 'Resize' } { @{ ExitCode = 2 } }

                    { Set-TargetResource -Ensure  'Present' -DriveLetter 'P' -DiskUsage 1 } |
                        Should -Throw -ExpectedMessage $errorMessage.Exception.Message
                }
            }

            It 'Should delete restore points on disk usage reduction with Force option' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:wasCalledPreviously = $false

                    Mock -CommandName Write-Warning
                    Mock -CommandName Enable-ComputerRestore
                    Mock -CommandName Invoke-VssAdmin -ParameterFilter { $Operation -eq 'Delete' } { @{ ExitCode = 0 } }
                    Mock -CommandName Invoke-VssAdmin -ParameterFilter { $Operation -eq 'Resize' } `
                        {
                            if ($script:wasCalledPreviously)
                            {
                                @{ ExitCode = 0 }
                            }
                            else
                            {
                                $script:wasCalledPreviously = $true
                                @{ ExitCode = 2 }
                            }
                        }

                    Set-TargetResource -Ensure  'Present' -DriveLetter 'P' -DiskUsage 1 -Force $true

                    Assert-MockCalled -CommandName Enable-ComputerRestore -Times 1
                    Assert-MockCalled -CommandName Invoke-VssAdmin -ParameterFilter { $Operation -eq 'Resize' } -Times 2
                    Assert-MockCalled -CommandName Invoke-VssAdmin -ParameterFilter { $Operation -eq 'Delete' } -Times 1
                    Assert-MockCalled -CommandName Write-Warning -Times 1
                }
            }

            It 'Should throw if the attempt to delete restore points fails' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $errorMessage = $script:localizedData.VssShadowDeleteFailure -f 'P'

                    Mock -CommandName Write-Warning
                    Mock -CommandName Enable-ComputerRestore
                    Mock -CommandName Invoke-VssAdmin -ParameterFilter { $Operation -eq 'Delete' } { @{ ExitCode = 2 } }
                    Mock -CommandName Invoke-VssAdmin -ParameterFilter { $Operation -eq 'Resize' } { @{ ExitCode = 2 } }

                    { Set-TargetResource -Ensure  'Present' -DriveLetter 'P' -DiskUsage 1 -Force $true } |
                        Should -Throw -ExpectedMessage $errorMessage.Exception.Message
                }
            }
        }
    }

    Context 'When running on a server OS' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $serverMock = @{
                    ParameterFilter = $([scriptblock]::Create('$ClassName -eq ''Win32_OperatingSystem'''))
                    MockWith        = $([scriptblock]::Create('@{ ProductType = 3 }'))
                }

                Mock -CommandName Get-CimInstance @serverMock
            }
        }

        It 'Should throw when applied to a server operating system' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

            $errorMessage = $script:localizedData.NotWorkstationOS

                { Set-TargetResource -Ensure 'Present' -DriveLetter 'C' } |
                    Should -Throw -ExpectedMessage $errorMessage.Exception.Message
            }
        }
    }
}
