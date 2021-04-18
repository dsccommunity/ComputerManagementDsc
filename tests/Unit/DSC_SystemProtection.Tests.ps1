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

        $fullFrequencyParams = @{
            Ensure    = 'Present'
            Frequency = 1440
        }

        $mocks = @{
            MaxPercentValueDriveP        = 5
            SystemProtectionStateEnabled = 'Present'
            SanitizedDriveGuid           = '\\?\Volume{f3f152fa-a383-4fb9-a823-fb7e1bfd1db1}\'
            SppRegistryValueDriveP       = '\\?\Volume{f3f152fa-a383-4fb9-a823-fb7e1bfd1db1}\:(P%3A)'
            SppRegistryValueFrequency    = 0

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

            SppRegistryKeyFrequency = @{
                SystemRestorePointCreationFrequency = 0
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
            Context 'When getting the target resource' {
                It 'Should throw when the system is corrupt' {
                    $errorRecord = Get-InvalidOperationRecord -Message $script:localizedData.GetEnabledDrivesFailure

                    Mock -CommandName Get-SppRegistryValue -MockWith { return $null }
                    { Get-TargetResource } | Should -Throw $errorRecord
                }
            }

            Context 'When getting the target resource with Drive P protected' {
                It 'Should get the system protection settings' {
                    Mock -CommandName Get-SystemProtectionState -MockWith { return $mocks.SystemProtectionStateEnabled }
                    Mock -CommandName Get-SppRegistryValue -MockWith { return $mocks.SppRegistryValueDriveP }
                    Mock -CommandName Get-DiskUsageConfiguration -MockWith { return $mocks.MaxPercentValueDriveP }

                    $protectionSettings = Get-TargetResource

                    $protectionSettings | Should -BeOfType Hashtable
                    $protectionSettings.Ensure | Should -Be 'Present'
                    $protectionSettings.ProtectedDrives.P | Should -Be 5
                    $protectionSettings.Frequency | Should -Be 1440
                }
            }
        }

        Describe "DSC_SystemProtection\Test-TargetResource" -Tag 'Test' {
            Context 'When testing with values that are out of bounds or invalid' {
                It 'Should throw when Ensure is neither Present nor Absent' {
                    { Test-TargetResource -Ensure 'Purgatory' } | Should -Throw
                }

                It 'Should throw when DriveLetter is invalid' {
                    { Test-TargetResource -Ensure 'Present' -DriveLetter '5' } | Should -Throw
                }

                It 'Should throw when DiskUsage is less than 1' {
                    { Test-TargetResource -Ensure 'Present' -DriveLetter 'P' -DiskUsage 0 } | Should -Throw
                }

                It 'Should throw when DiskUsage is greater than 100' {
                    { Test-TargetResource -Ensure 'Present' -DriveLetter 'P' -DiskUsage 101 } | Should -Throw
                }

                It 'Should throw when Frequency is less than 0' {
                    { Test-TargetResource -Ensure 'Present' -Frequency -1 } | Should -Throw
                }

                It 'Should throw when Frequncy is greater than 2147483647' {
                    { Test-TargetResource -Ensure 'Present' -Frequency 2147483648 } | Should -Throw
                }

                It 'Should throw when DriveLetter and Frequency are both defined' {
                    $errorRecord = Get-InvalidArgumentRecord -Message `
                        $script:localizedData.MultipleSettings -ArgumentName 'Ensure'

                    { Test-TargetResource `
                        -Ensure 'Present' -DriveLetter 'P' -Frequency 10 } | Should -Throw $errorRecord
                }

                It 'Should throw when neither DriveLetter nor Frequency are defined' {
                    $errorRecord = Get-InvalidArgumentRecord -Message `
                        $script:localizedData.InsufficentArguments -ArgumentName 'Ensure'

                    { Test-TargetResource -Ensure 'Present' } | Should -Throw $errorRecord
                }

            }

            Context 'When system protection is in the desired state' {
                Mock -CommandName Get-SppRegistryValue -MockWith { return $mocks.SppRegistryValueDriveP }
                Mock -CommandName Get-DiskUsageConfiguration -MockWith { return $mocks.MaxPercentValueDriveP }

                It 'Should return a boolean' {
                    $result = Test-TargetResource @fullDriveParams
                    $result | Should -BeOfType Boolean
                }

                It 'Should return true when only the drive letter is specified' {
                    $result = Test-TargetResource @partialDriveParams
                    $result | Should -BeTrue
                }

                It 'Should return true when drive letter and disk usage are specified' {
                    $result = Test-TargetResource @fullDriveParams
                    $result | Should -BeTrue
                }

                It 'Should return true when the frequency is specified' {
                    $result = Test-TargetResource @fullFrequencyParams
                    $result | Should -BeTrue
                }
            }

            Context 'When system protection is not in the desired state' {
                Mock -CommandName Get-SppRegistryValue -MockWith { return $mocks.SppRegistryValueDriveP }
                Mock -CommandName Get-DiskUsageConfiguration -MockWith { return $mocks.MaxPercentValueDriveP }

                It 'Should return false when Ensure setting changes are required' {
                    $result = Test-TargetResource -Ensure 'Absent' -DriveLetter 'P'
                    $result | Should -BeFalse
                }

                It 'Should return false when DiskUsage setting changes are required' {
                    $result = Test-TargetResource -Ensure 'Present' -DriveLetter 'P' -DiskUsage 25
                    $result | Should -BeFalse
                }

                It 'Should return false when Frequency setting changes are required' {
                    $result = Test-TargetResource -Ensure 'Present' -Frequency 0
                    $result | Should -BeFalse
                }
            }
        }

        Describe "DSC_SystemProtection\Set-TargetResource" -Tag 'Set' {
            Context 'When setting the target resource' {
                It 'Should throw when no configuration parameters have been set with Ensure Present' {
                    $errorRecord = Get-InvalidArgumentRecord -Message `
                        $script:localizedData.InsufficentArguments -ArgumentName 'Ensure'

                    { Set-TargetResource -Ensure 'Present' } | Should -Throw $errorRecord
                }

                It 'Should throw when no configuration parameters have been set with Ensure Absent' {
                    $errorRecord = Get-InvalidArgumentRecord -Message `
                        $script:localizedData.InsufficentArguments -ArgumentName 'Ensure'

                    { Set-TargetResource -Ensure 'Absent' } | Should -Throw $errorRecord
                }

                It 'Should throw when the operating system cannot enable system protection' {
                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($script:localizedData.EnableRestoreFailure -f 'C')

                    Mock -CommandName Enable-ComputerRestore -MockWith { throw  }
                    { Set-TargetResource -Ensure 'Present' -DriveLetter 'C' } | Should -Throw $errorRecord
                }

                It 'Should throw when the operating system cannot disable system protection' {
                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($script:localizedData.DisableRestoreFailure -f 'C')

                    Mock -CommandName Disable-ComputerRestore -MockWith { throw  }
                    { Set-TargetResource -Ensure 'Absent' -DriveLetter 'C' } | Should -Throw $errorRecord
                }
            }

            Context 'When configuring with values that are out of bounds or invalid' {
                It 'Should throw when Ensure is neither Present nor Absent' {
                    { Set-TargetResource -Ensure 'Purgatory' } | Should -Throw
                }

                It 'Should throw when DriveLetter is invalid' {
                    { Set-TargetResource -Ensure 'Present' -DriveLetter '5' } | Should -Throw
                }

                It 'Should throw when DiskUsage is less than 1' {
                    { Set-TargetResource -Ensure 'Present' -DriveLetter 'P' -DiskUsage 0 } | Should -Throw
                }

                It 'Should throw when DiskUsage is greater than 100' {
                    { Set-TargetResource -Ensure 'Present' -DriveLetter 'P' -DiskUsage 110 } | Should -Throw
                }

                It 'Should throw when Frequency is less than 0' {
                    { Set-TargetResource -Ensure 'Present' -Frequency -1 } | Should -Throw
                }

                It 'Should throw when Frequncy is greater than 2147483647' {
                    { Set-TargetResource -Ensure 'Present' -Frequency 2147483648 } | Should -Throw
                }

                It 'Should throw when neither DriveLetter nor Frequency are defined' {
                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message $script:localizedData.InsufficentArguments -ArgumentName 'Ensure'

                    { Set-TargetResource -Ensure 'Present' } | Should -Throw $errorRecord
                }

                It 'Should throw when DriveLetter and Frequency are both defined with Ensure Present' {
                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message $script:localizedData.MultipleSettings -ArgumentName 'Ensure'

                    { Set-TargetResource `
                        -Ensure 'Present' -DriveLetter 'P' -Frequency 10 } | Should -Throw $errorRecord
                }

                It 'Should throw when DriveLetter and Frequency are both defined with Ensure Absent' {
                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message $script:localizedData.MultipleSettings -ArgumentName 'Ensure'

                    { Set-TargetResource `
                        -Ensure 'Absent' -DriveLetter 'P' -Frequency 10 } | Should -Throw $errorRecord
                }
            }

            Context 'When configuration is required' {
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

                It 'Should configure automatic restore point frequency to 0' {
                    Mock -CommandName Set-SystemProtectionFrequency

                    Set-TargetResource -Ensure 'Present' -Frequency 0
                    Assert-MockCalled -CommandName Set-SystemProtectionFrequency -Times 1
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

        Describe "DSC_SystemProtection\Get-SystemProtectionFrequency" -Tag 'Helper' {
            Context 'When getting system protection frequency from the registry' {
                It 'Should return the registry value when settings exist' {
                    Mock -CommandName Get-ItemProperty -MockWith { return $mocks.SppRegistryKeyFrequency }
                    Mock -CommandName Get-ItemPropertyValue -MockWith { return $mocks.SppRegistryValueFrequency }

                    $result = Get-SppRegistryValue
                    $result | Should -Not -Be 1440
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

        Describe "DSC_SystemProtection\Set-SystemProtectionFrequency" -Tag 'Helper' {
            Context 'When setting system protection frequency' {
                It 'Should throw when we encounter a problem deleting from the registry' {
                    $errorRecord = Get-InvalidOperationRecord `
                        -Message $script:localizedData.SetFrequencyFailure

                    Mock -CommandName Remove-ItemProperty -MockWith { throw }
                    { Set-SystemProtectionFrequency -Frequency 1440 } | Should -Throw $errorRecord
                }

                It 'Should throw when we encounter a problem writing to the registry' {
                    $errorRecord = Get-InvalidOperationRecord `
                        -Message $script:localizedData.SetFrequencyFailure

                    Mock -CommandName Set-ItemProperty -MockWith { throw }
                    { Set-SystemProtectionFrequency -Frequency 0 } | Should -Throw $errorRecord
                }

                It 'Should set the frequency to 0 in the registry' {
                    Mock -CommandName Set-ItemProperty
                    { Set-SystemProtectionFrequency } | Should -Not -Throw
                }

                It 'Should delete the frequency registry key when setting to 1440' {
                    Mock -CommandName Remove-ItemProperty
                    { Set-SystemProtectionFrequency } | Should -Not -Throw
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
