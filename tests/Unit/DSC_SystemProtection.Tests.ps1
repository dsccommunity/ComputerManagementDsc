$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'DSC_SystemProtection'

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
        $fullDriveParams = @{
            Ensure      = 'Present'
            DriveLetter = 'P'
            DiskUsage   = 5
        }

        $partialDriveParams = @{
            Ensure      = 'Present'
            DriveLetter = 'P'
        }

        $workstationMock = @{
            ParameterFilter = $([scriptblock]::Create('$ClassName -eq ''Win32_OperatingSystem'''))
            MockWith        = $([scriptblock]::Create('@{ ProductType = 1 }'))
        }

        $serverMock = @{
            ParameterFilter = $([scriptblock]::Create('$ClassName -eq ''Win32_OperatingSystem'''))
            MockWith        = $([scriptblock]::Create('@{ ProductType = 3 }'))
        }

        $mocks = @{
            MaxPercentValueDriveP        = 5
            SystemProtectionStateEnabled = 'Present'
            SanitizedDriveGuid           = '\\?\Volume{f3f152fa-a383-4fb9-a823-fb7e1bfd1db1}\'
            SppRegistryValueDriveP       = '\\?\Volume{f3f152fa-a383-4fb9-a823-fb7e1bfd1db1}\:(P%3A)'

            SppRegistryItemDriveP = @{
                {09F7EDC5-294E-4180-AF6A-FB0E6A0E9513} = '\\?\Volume{f3f152fa-a383-4fb9-a823-fb7e1bfd1db1}\:(P%3A)'
            }

            VssAdminFailure = @{
                ExitCode = 2
            }

            VssAdminSuccess = @{
                ExitCode = 0
            }

            GetVolumeSize = @{
                Size = 200GB
            }

            GetCimInstanceestoreEnabled  = @{
                RPSessionInterval = 1
            }

            GetCimInstanceestoreDisabled = @{
                RPSessionInterval = 0
            }

            GetCimInstanceShadowStorage  = @{
                AllocatedSpace = [System.Uint64]40GB
                DiffVolume     = @{
                    DeviceID = '\\?\Volume{f3f152fa-a383-4fb9-a823-fb7e1bfd1db1}\'
                }
                MaxSpace       = [System.UInt64]45GB
                UsedSpace      = [System.UInt64]35GB
                Volume         = @{
                    DeviceID = '\\?\Volume{f3f152fa-a383-4fb9-a823-fb7e1bfd1db1}\'
                }
            }
        }

        Describe "DSC_SystemProtection\Get-TargetResource" -Tag 'Get' {
            Context 'When running on a workstation OS' {
                Context 'When getting the target resource' {
                    It 'Should throw when the system is corrupt' {
                        $errorRecord = Get-InvalidOperationRecord -Message $script:localizedData.GetEnabledDrivesFailure

                        Mock -CommandName Get-SystemProtectionState -MockWith { return $mocks.SystemProtectionStateEnabled }
                        Mock -CommandName Get-SppRegistryValue -MockWith { return $null }
                        Mock -CommandName Get-CimInstance @workstationMock

                        { Get-TargetResource -Ensure 'Present' -DriveLetter 'P' } | Should -Throw $errorRecord
                    }
                }

                Context 'When getting the target resource with Drive P protected' {
                    It 'Should get the system protection settings' {
                        Mock -CommandName Get-SystemProtectionState -MockWith { return $mocks.SystemProtectionStateEnabled }
                        Mock -CommandName Get-SppRegistryValue -MockWith { return $mocks.SppRegistryValueDriveP }
                        Mock -CommandName Get-DiskUsageConfiguration -MockWith { return $mocks.MaxPercentValueDriveP }
                        Mock -CommandName Get-CimInstance @workstationMock

                        $protectionSettings = Get-TargetResource -Ensure 'Present' -DriveLetter 'P'

                        $protectionSettings | Should -BeOfType Hashtable
                        $protectionSettings.Ensure | Should -Be 'Present'
                        $protectionSettings.DriveLetter | Should -Be 'P'
                        $protectionSettings.DiskUsage | Should -Be 5
                    }
                }
            }

            Context 'When running on a server OS' {
                Context 'When getting the target resource' {
                    It 'Should return Absent and write a warning on a server operating system' {
                        Mock -CommandName Write-Warning
                        Mock -CommandName Get-CimInstance @serverMock

                        $protectionSettings = Get-TargetResource -Ensure 'Present' -DriveLetter 'C'

                        $protectionSettings.Ensure | Should -Be 'Absent'
                        Assert-MockCalled -CommandName Write-Warning -Times 1
                    }
                }
            }
        }

        Describe "DSC_SystemProtection\Test-TargetResource" -Tag 'Test' {
            Context 'When running on a workstation OS' {
                Context 'When testing the target resource' {
                    It 'Should throw when Ensure is neither Present nor Absent' {
                        { Test-TargetResource -Ensure 'Purgatory' } | Should -Throw
                    }

                    It 'Should throw when DriveLetter is invalid' {
                        { Test-TargetResource -Ensure 'Present' -DriveLetter '5' } | Should -Throw
                        { Test-TargetResource -Ensure 'Present' -DriveLetter 'CD' } | Should -Throw
                    }

                    It 'Should throw when DiskUsage is less than 1' {
                        { Test-TargetResource -Ensure 'Present' -DriveLetter 'P' -DiskUsage 0 } | Should -Throw
                    }

                    It 'Should throw when DiskUsage is greater than 100' {
                        { Test-TargetResource -Ensure 'Present' -DriveLetter 'P' -DiskUsage 101 } | Should -Throw
                    }
                }

                Context 'When system protection is in the desired state' {
                    Mock -CommandName Get-SppRegistryValue -MockWith { return $mocks.SppRegistryValueDriveP }
                    Mock -CommandName Get-DiskUsageConfiguration -MockWith { return $mocks.MaxPercentValueDriveP }
                    Mock -CommandName Get-CimInstance @workstationMock

                    It 'Should return true when only the drive letter is specified' {
                        $result = Test-TargetResource @partialDriveParams
                        $result | Should -BeTrue
                    }

                    It 'Should return true when drive letter and disk usage are specified' {
                        $result = Test-TargetResource @fullDriveParams
                        $result | Should -BeTrue
                    }
                }

                Context 'When system protection is not in the desired state' {
                    Mock -CommandName Get-SppRegistryValue -MockWith { return $mocks.SppRegistryValueDriveP }
                    Mock -CommandName Get-DiskUsageConfiguration -MockWith { return $mocks.MaxPercentValueDriveP }
                    Mock -CommandName Get-CimInstance @workstationMock

                    It 'Should return false when drive protection changes are necessary' {
                        $result = Test-TargetResource -Ensure 'Absent' -DriveLetter 'P'

                        $result | Should -BeFalse
                    }

                    It 'Should return false when disk usage changes are necessary' {
                        $result = Test-TargetResource -Ensure 'Present' -DriveLetter 'P' -DiskUsage 25

                        $result | Should -BeFalse
                    }
                }
            }

            Context 'When running on a server OS' {
                It 'Should return Absent and write warnings on a server operating system' {
                    Mock -CommandName Write-Warning
                    Mock -CommandName Get-CimInstance @serverMock

                    $desiredState = Test-TargetResource -Ensure 'Present' -DriveLetter 'C'

                    $desiredState | Should -BeTrue
                    Assert-MockCalled -CommandName Write-Warning -Times 2
                }
            }
        }

        Describe "DSC_SystemProtection\Set-TargetResource" -Tag 'Set' {
            Context 'When running on a workstation OS' {
                Context 'When setting the target resource' {
                    It 'Should throw when Ensure is neither Present nor Absent' {
                        { Set-TargetResource -Ensure 'Purgatory' } | Should -Throw
                    }

                    It 'Should throw when DriveLetter is invalid' {
                        { Set-TargetResource -Ensure 'Present' -DriveLetter '5' } | Should -Throw
                        { Set-TargetResource -Ensure 'Present' -DriveLetter 'CD' } | Should -Throw
                    }

                    It 'Should throw when DiskUsage is less than 1' {
                        { Set-TargetResource -Ensure 'Present' -DriveLetter 'P' -DiskUsage 0 } | Should -Throw
                    }

                    It 'Should throw when DiskUsage is greater than 100' {
                        { Set-TargetResource -Ensure 'Present' -DriveLetter 'P' -DiskUsage 110 } | Should -Throw
                    }

                    It 'Should throw when the operating system cannot enable system protection' {
                        $errorRecord = Get-InvalidOperationRecord `
                            -Message ($script:localizedData.EnableComputerRestoreFailure -f 'C')

                        Mock -CommandName Enable-ComputerRestore -MockWith { throw  }
                        Mock -CommandName Get-CimInstance @workstationMock

                        { Set-TargetResource -Ensure 'Present' -DriveLetter 'C' } | Should -Throw $errorRecord
                    }

                    It 'Should throw when the operating system cannot disable system protection' {
                        $errorRecord = Get-InvalidOperationRecord `
                            -Message ($script:localizedData.DisableComputerRestoreFailure -f 'C')

                        Mock -CommandName Disable-ComputerRestore -MockWith { throw  }
                        Mock -CommandName Get-CimInstance @workstationMock

                        { Set-TargetResource -Ensure 'Absent' -DriveLetter 'C' } | Should -Throw $errorRecord
                    }
                }

                Context 'When configuration is required' {
                    Mock -CommandName Get-CimInstance @workstationMock

                    It 'Should enable system protection for Drive P' {
                        Mock -CommandName Enable-ComputerRestore

                        Set-TargetResource -Ensure 'Present' -DriveLetter 'P'

                        Assert-MockCalled -CommandName Enable-ComputerRestore -Times 1
                    }

                    It 'Should disable system protection for Drive P' {
                        Mock -CommandName Disable-ComputerRestore

                        Set-TargetResource -Ensure 'Absent' -DriveLetter 'P'

                        Assert-MockCalled -CommandName Disable-ComputerRestore
                    }

                    It 'Should enable set maximum disk usage to 20%' {
                        Mock -CommandName Enable-ComputerRestore
                        Mock -CommandName Invoke-VssAdmin -MockWith { return $mocks.VssAdminSuccess }

                        Set-TargetResource -Ensure 'Present' -DriveLetter 'P' -DiskUsage 20

                        Assert-MockCalled -CommandName Enable-ComputerRestore -Times 1
                        Assert-MockCalled -CommandName Invoke-VssAdmin -Times 1
                    }

                    It 'Should throw if the attempt to reisze fails without the Force option' {
                        $errorRecord = Get-InvalidOperationRecord `
                            -Message ($script:localizedData.VssShadowResizeFailure -f 'P')

                        Mock -CommandName Enable-ComputerRestore
                        Mock -CommandName Invoke-VssAdmin `
                            -MockWith { $mocks.VssAdminFailure } `
                            -ParameterFilter { $Operation -eq 'Resize' }

                        { Set-TargetResource `
                            -Ensure  'Present' -DriveLetter 'P' -DiskUsage 1 } | Should -Throw $errorRecord
                    }

                    It 'Should delete restore points on disk usage reduction with Force option' {
                        $script:wasCalledPreviously = $false

                        Mock -CommandName Enable-ComputerRestore
                        Mock -CommandName Invoke-VssAdmin `
                            -MockWith { $mocks.VssAdminSuccess } `
                            -ParameterFilter { $Operation -eq 'Delete' }
                        Mock -CommandName Invoke-VssAdmin `
                            -ParameterFilter { $Operation -eq 'Resize' } `
                            -MockWith {
                                if ($script:wasCalledPreviously)
                                {
                                    $mocks.VssAdminSuccess
                                }
                                else
                                {
                                    $script:wasCalledPreviously = $true
                                    $mocks.VssAdminFailure
                                }
                            }

                        Set-TargetResource -Ensure  'Present' -DriveLetter 'P' -DiskUsage 1 -Force $true

                        Assert-MockCalled -CommandName Enable-ComputerRestore -Times 1
                        Assert-MockCalled -CommandName Invoke-VssAdmin `
                            -ParameterFilter {  $Operation -eq 'Resize' } -Times 2
                        Assert-MockCalled -CommandName Invoke-VssAdmin `
                            -ParameterFilter { $Operation -eq 'Delete' } -Times 1
                    }

                    It 'Should throw if the attempt to delete restore points fails' {
                        $errorRecord = Get-InvalidOperationRecord `
                            -Message ($script:localizedData.VssShadowDeleteFailure -f 'P')

                        Mock -CommandName Enable-ComputerRestore
                        Mock -CommandName Invoke-VssAdmin `
                            -MockWith { $mocks.VssAdminFailure } `
                            -ParameterFilter { $Operation -eq 'Resize' }
                        Mock -CommandName Invoke-VssAdmin `
                            -MockWith { $mocks.VssAdminFailure } `
                            -ParameterFilter { $Operation -eq 'Delete' }

                        { Set-TargetResource `
                            -Ensure  'Present' -DriveLetter 'P' -DiskUsage 1 -Force $true } | Should -Throw $errorRecord
                    }

                    It 'Should throw if all attempts to resize fails with Force option' {
                        $errorRecord = Get-InvalidOperationRecord `
                            -Message ($script:localizedData.VssShadowResizeFailureWithForce2 -f 'P')

                        Mock -CommandName Enable-ComputerRestore
                        Mock -CommandName Invoke-VssAdmin `
                            -MockWith { $mocks.VssAdminFailure } `
                            -ParameterFilter { $Operation -eq 'Resize' }
                        Mock -CommandName Invoke-VssAdmin `
                            -MockWith { $mocks.VssAdminSuccess } `
                            -ParameterFilter { $Operation -eq 'Delete' }

                        { Set-TargetResource `
                            -Ensure  'Present' -DriveLetter 'P' -DiskUsage 1 -Force $true } | Should -Throw $errorRecord
                    }
                }
            }

            Context 'When running on a server OS' {
                It 'Should throw when applied to a server operating system' {
                    $errorRecord = Get-InvalidOperationRecord -Message $script:localizedData.NotWorkstationOS

                    Mock -CommandName Get-CimInstance @serverMock

                    { Set-TargetResource -Ensure 'Present' -DriveLetter 'C' } | Should -Throw $errorRecord
                }
            }
        }

        Describe "DSC_SystemProtection\Get-DiskUsageConfiguration" -Tag 'Helper' {
            Context 'When getting maximum disk usage for a protected drive' {
                It 'Should throw if the shadow storage lookup fails' {
                    $errorRecord = Get-InvalidOperationRecord `
                        -Message $script:localizedData.UnknownOperatingSystemError

                    Mock -CommandName Get-CimInstance -MockWith { throw }

                    { Get-DiskUsageConfiguration -Drive $mocks.SppRegistryValueDriveP } | Should -Throw $errorRecord
                }

                It 'Should throw if the volume size lookup fails' {
                    $errorRecord = Get-InvalidOperationRecord `
                        -Message $script:localizedData.UnknownOperatingSystemError

                    Mock -CommandName Get-Volume -MockWith { throw }

                    { Get-DiskUsageConfiguration -Drive $mocks.SppRegistryValueDriveP } | Should -Throw $errorRecord
                }

                It 'Should return an integer' {
                    Mock -CommandName Get-CimInstance -MockWith { return $mocks.GetCimInstanceShadowStorage }
                    Mock -CommandName Get-Volume -MockWith { return $mocks.GetVolumeSize }

                    $result = Get-DiskUsageConfiguration -Drive $mocks.SppRegistryValueDriveP

                    $result | Should -BeOfType Int
                }
            }
        }

        Describe "DSC_SystemProtection\Get-SppRegistryValue" -Tag 'Helper' {
            Context 'When getting system protection settings from the registry' {
                It 'Should return null if the registry settings are not found' {
                    Mock -CommandName Get-ItemProperty -MockWith { return $null }

                    $result = Get-SppRegistryValue

                    $result | Should -BeNull
                }

                It 'Should return the registry value when settings exist' {
                    Mock -CommandName Get-ItemProperty -MockWith { return $mocks.SppRegistryItemDriveP }
                    Mock -CommandName Get-ItemPropertyValue -MockWith { return $mocks.SppRegistryValueDriveP }

                    $result = Get-SppRegistryValue

                    $result | Should -Not -BeNull
                }
            }
        }

        Describe "DSC_SystemProtection\Get-SystemProtectionState" -Tag 'Helper' {
            Context 'When getting system protection state' {
                It 'Should throw when we encounter a problem from CIM' {
                    $errorRecord = Get-InvalidOperationRecord `
                        -Message $script:localizedData.UnknownOperatingSystemError

                    Mock -CommandName Get-CimInstance -MockWith { throw }

                    { Get-SystemProtectionState } | Should -Throw $errorRecord
                }

                It 'Should return Present when system protection is enabled' {
                    Mock -CommandName Get-CimInstance -MockWith { return $mocks.GetCimInstanceestoreEnabled }

                    $result = Get-SystemProtectionState

                    $result | Should -Be 'Present'
                }

                It 'Should return Absent when system protection is disabled' {
                    Mock -CommandName Get-CimInstance -MockWith { return $mocks.GetCimInstanceestoreDisabled }

                    $result = Get-SystemProtectionState

                    $result | Should -Be 'Absent'
                }
            }
        }

        Describe "DSC_SystemProtection\Invoke-VssAdmin" -Tag 'Helper' {
            Context 'When configuring volume shadow copies' {
                It 'Should resize volume shadow storage ' {
                    Mock -CommandName Start-VssAdminProcess -MockWith { return $mocks.VssAdminSuccess }

                    { Invoke-VssAdmin -Operation Resize -Drive 'P:' -DiskUsage 20 } | Should -Not -Throw
                }

                It 'Should delete volume shadow storage ' {
                    Mock -CommandName Start-VssAdminProcess -MockWith { return $mocks.VssAdminSuccess }

                    { Invoke-VssAdmin -Operation Delete -Drive 'P:' } | Should -Not -Throw
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
