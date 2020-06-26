$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'DSC_WindowsEventLog'

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
    Describe 'WindowsEventLog Integration Tests' {
        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile

        Describe "$($script:dscResourceName)_Integration" {
            Context 'When setting Windows Event Log to Logmode Retain' {
                $currentConfig = 'DSC_WindowsEventLog_RetainSize'
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

            Context 'When setting Windows Event Log to Logmode AutoBackup with LogRetentionDays of 30 days' {
                $currentConfig = 'DSC_WindowsEventLog_AutobackupLogRetention'
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

            Context 'When setting Windows Event Log to Logmode Circular, MaximumSizeInBytes 20971520, LogFilePath C:\temp\Application.evtx' {
                $currentConfig = 'DSC_WindowsEventLog_CircularLogPath'
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

            Context 'When setting Windows Event Log to Default' {
                $currentConfig = 'DSC_WindowsEventLog_Default'
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

            Context 'When enabling a Logfile other than Application Eventlog' {
                $currentConfig = 'DSC_WindowsEventLog_EnableLog'
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

            Context 'When disableing a Logfile other than Application Windows Event Log' {
                $currentConfig = 'DSC_WindowsEventLog_DisableLog'
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

            Context 'When setting Eventlog to Logmode Circular with a SecurityDescriptor' {
                $currentConfig = 'DSC_WindowsEventLog_CircularSecurityDescriptor'
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

            Context 'When enabling a Logfile other than Application Windows Event Log with Retention' {
                $currentConfig = 'DSC_WindowsEventLog_EnableBackupLog'
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

                It 'Should return a incompliant state' {
                    (Test-DscConfiguration -ReferenceConfiguration $configMof -Verbose).InDesiredState | Should -BeFalse
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }
            }

            Context 'When disabling a Logfile other than Application Eventlog with retention' {
                $currentConfig = 'DSC_WindowsEventLog_DisableBackupLog'
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

            Context 'When setting Windows Event Log back to the default configuration' {
                $currentConfig = 'DSC_WindowsEventLog_Default'
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
