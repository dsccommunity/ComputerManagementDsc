$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'DSC_SystemRestorePoint'

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
    -TestType 'Integration'

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

# Begin Testing
try
{
    Describe 'SystemRestorePoint Integration Tests' {
        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile

        Describe "$($script:dscResourceName)_Integration" {
            Context 'When creating a restore point of type APPLICATION_INSTALL ' {
                $currentConfig = 'DSC_SystemRestorePoint_CreateAppInstallRestorePoint'
                $configDir = (Join-Path -Path $TestDrive -ChildPath $currentConfig)
                $configMof = (Join-Path -Path $configDir -ChildPath 'localhost.mof')

                It 'Should compile the MOF without throwing' {
                    {
                        . $currentConfig -OutputPath $configDir
                    } | Should -Not -Throw
                }

                It 'Should apply the MOF without throwing' {
                    {
                        Reset-DscLcm

                        Start-DscConfiguration -Path $configDir -Wait -Verbose -Force
                    } | Should -Not -Throw
                }

                It 'Should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $configMof -Verbose).InDesiredState | Should -BeTrue
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }
            }

            Context 'When creating a restore point of type APPlICAtION_UNINSTALL' {
                $currentConfig = 'DSC_SystemRestorePoint_CreateAppUninstallRestorePoint'
                $configDir = (Join-Path -Path $TestDrive -ChildPath $currentConfig)
                $configMof = (Join-Path -Path $configDir -ChildPath 'localhost.mof')

                It 'Should compile the MOF without throwing' {
                    {
                        . $currentConfig -OutputPath $configDir
                    } | Should -Not -Throw
                }

                It 'Should apply the MOF without throwing' {
                    {
                        Reset-DscLcm

                        Start-DscConfiguration -Path $configDir -Wait -Verbose -Force
                    } | Should -Not -Throw
                }

                It 'Should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $configMof -Verbose).InDesiredState | Should -BeTrue
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }
            }

            Context 'When creating a restore point of type DEVICE_DRIVER_INSTALL' {
                $currentConfig = 'DSC_SystemRestorePoint_CreateDeviceDriverRestorePoint'
                $configDir = (Join-Path -Path $TestDrive -ChildPath $currentConfig)
                $configMof = (Join-Path -Path $configDir -ChildPath 'localhost.mof')

                It 'Should compile the MOF without throwing' {
                    {
                        . $currentConfig -OutputPath $configDir
                    } | Should -Not -Throw
                }

                It 'Should apply the MOF without throwing' {
                    {
                        Reset-DscLcm

                        Start-DscConfiguration -Path $configDir -Wait -Verbose -Force
                    } | Should -Not -Throw
                }

                It 'Should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $configMof -Verbose).InDesiredState | Should -BeTrue
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }
            }

            Context 'When creating a restore point of type MODIFY_SETTINGS' {
                $currentConfig = 'DSC_SystemRestorePoint_CreateModifySettingsRestorePoint'
                $configDir = (Join-Path -Path $TestDrive -ChildPath $currentConfig)
                $configMof = (Join-Path -Path $configDir -ChildPath 'localhost.mof')

                It 'Should compile the MOF without throwing' {
                    {
                        . $currentConfig -OutputPath $configDir
                    } | Should -Not -Throw
                }

                It 'Should apply the MOF without throwing' {
                    {
                        Reset-DscLcm

                        Start-DscConfiguration -Path $configDir -Wait -Verbose -Force
                    } | Should -Not -Throw
                }

                It 'Should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $configMof -Verbose).InDesiredState | Should -BeTrue
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }
            }

            Context 'When creating a restore point of type CANCELLED_OPERATION' {
                $currentConfig = 'DSC_SystemRestorePoint_CreateCancelledOperationRestorePoint'
                $configDir = (Join-Path -Path $TestDrive -ChildPath $currentConfig)
                $configMof = (Join-Path -Path $configDir -ChildPath 'localhost.mof')

                It 'Should compile the MOF without throwing' {
                    {
                        . $currentConfig -OutputPath $configDir
                    } | Should -Not -Throw
                }

                It 'Should apply the MOF without throwing' {
                    {
                        Reset-DscLcm

                        Start-DscConfiguration -Path $configDir -Wait -Verbose -Force
                    } | Should -Not -Throw
                }

                It 'Should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $configMof -Verbose).InDesiredState | Should -BeTrue
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }
            }

            Context 'When deleting a restore point of type APPLICATION_INSTALL ' {
                $currentConfig = 'DSC_SystemRestorePoint_DeleteAppInstallRestorePoint'
                $configDir = (Join-Path -Path $TestDrive -ChildPath $currentConfig)
                $configMof = (Join-Path -Path $configDir -ChildPath 'localhost.mof')

                It 'Should compile the MOF without throwing' {
                    {
                        . $currentConfig -OutputPath $configDir
                    } | Should -Not -Throw
                }

                It 'Should apply the MOF without throwing' {
                    {
                        Reset-DscLcm

                        Start-DscConfiguration -Path $configDir -Wait -Verbose -Force
                    } | Should -Not -Throw
                }

                It 'Should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $configMof -Verbose).InDesiredState | Should -BeTrue
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }
            }

            Context 'When deleting a restore point of type APPlICAtION_UNINSTALL' {
                $currentConfig = 'DSC_SystemRestorePoint_DeleteAppUninstallRestorePoint'
                $configDir = (Join-Path -Path $TestDrive -ChildPath $currentConfig)
                $configMof = (Join-Path -Path $configDir -ChildPath 'localhost.mof')

                It 'Should compile the MOF without throwing' {
                    {
                        . $currentConfig -OutputPath $configDir
                    } | Should -Not -Throw
                }

                It 'Should apply the MOF without throwing' {
                    {
                        Reset-DscLcm

                        Start-DscConfiguration -Path $configDir -Wait -Verbose -Force
                    } | Should -Not -Throw
                }

                It 'Should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $configMof -Verbose).InDesiredState | Should -BeTrue
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }
            }

            Context 'When deleting a restore point of type DEVICE_DRIVER_INSTALL' {
                $currentConfig = 'DSC_SystemRestorePoint_DeleteDeviceDriverRestorePoint'
                $configDir = (Join-Path -Path $TestDrive -ChildPath $currentConfig)
                $configMof = (Join-Path -Path $configDir -ChildPath 'localhost.mof')

                It 'Should compile the MOF without throwing' {
                    {
                        . $currentConfig -OutputPath $configDir
                    } | Should -Not -Throw
                }

                It 'Should apply the MOF without throwing' {
                    {
                        Reset-DscLcm

                        Start-DscConfiguration -Path $configDir -Wait -Verbose -Force
                    } | Should -Not -Throw
                }

                It 'Should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $configMof -Verbose).InDesiredState | Should -BeTrue
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }
            }

            Context 'When deleting a restore point of type MODIFY_SETTINGS' {
                $currentConfig = 'DSC_SystemRestorePoint_DeleteModifySettingsRestorePoint'
                $configDir = (Join-Path -Path $TestDrive -ChildPath $currentConfig)
                $configMof = (Join-Path -Path $configDir -ChildPath 'localhost.mof')

                It 'Should compile the MOF without throwing' {
                    {
                        . $currentConfig -OutputPath $configDir
                    } | Should -Not -Throw
                }

                It 'Should apply the MOF without throwing' {
                    {
                        Reset-DscLcm

                        Start-DscConfiguration -Path $configDir -Wait -Verbose -Force
                    } | Should -Not -Throw
                }

                It 'Should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $configMof -Verbose).InDesiredState | Should -BeTrue
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }
            }

            Context 'When deleting a restore point of type CANCELLED_OPERATION' {
                $currentConfig = 'DSC_SystemRestorePoint_DeleteCancelledOperationRestorePoint'
                $configDir = (Join-Path -Path $TestDrive -ChildPath $currentConfig)
                $configMof = (Join-Path -Path $configDir -ChildPath 'localhost.mof')

                It 'Should compile the MOF without throwing' {
                    {
                        . $currentConfig -OutputPath $configDir
                    } | Should -Not -Throw
                }

                It 'Should apply the MOF without throwing' {
                    {
                        Reset-DscLcm

                        Start-DscConfiguration -Path $configDir -Wait -Verbose -Force
                    } | Should -Not -Throw
                }

                It 'Should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $configMof -Verbose).InDesiredState | Should -BeTrue
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
