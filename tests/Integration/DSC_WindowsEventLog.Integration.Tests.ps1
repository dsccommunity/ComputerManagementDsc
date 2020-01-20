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

            Context 'Set Windows Event Log to Logmode Retain' {
                $CurrentConfig = 'DSC_WindowsEventLog_RetainSize'
                $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
                $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')

                It 'Should compile a MOF file without error' {
                    {
                        . $CurrentConfig -OutputPath $ConfigDir
                    } | Should -Not -Throw
                }

                It 'Should apply the MOF correctly' {
                    {
                        Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                    } | Should -Not -Throw
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should -BeTrue
                }
            }

            Context 'Set Windows Event Log to Logmode AutoBackup with LogRetentionDays of 30 days' {
                $CurrentConfig = 'DSC_WindowsEventLog_AutobackupLogRetention'
                $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
                $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')

                It 'Should compile a MOF file without error' {
                    {
                        . $CurrentConfig -OutputPath $ConfigDir
                    } | Should -Not -Throw
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should apply the MOF correctly' {
                    {
                        Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                    } | Should -Not -Throw
                }

                It 'Should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should -BeTrue
                }
            }

            Context 'Set Windows Event Log to Logmode Circular, MaximumSizeInBytes 20971520, LogFilePath C:\temp\Application.evtx' {
                $CurrentConfig = 'DSC_WindowsEventLog_CircularLogPath'
                $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
                $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')

                It 'Should compile a MOF file without error' {
                    {
                        . $CurrentConfig -OutputPath $ConfigDir
                    } | Should -Not -Throw
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should apply the MOF correctly' {
                    {
                        Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                    } | Should -Not -Throw
                }

                It 'Should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should -BeTrue
                }
            }

            Context 'Set Windows Event Log to Default' {
                $CurrentConfig = 'DSC_WindowsEventLog_Default'
                $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
                $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')

                It 'Should compile a MOF file without error' {
                    {
                        . $CurrentConfig -OutputPath $ConfigDir
                    } | Should -Not -Throw
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should apply the MOF correctly' {
                    {
                        Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                    } | Should -Not -Throw
                }

                It 'Should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should -BeTrue
                }
            }

            Context 'Enable a Logfile other than Application Eventlog' {
                $CurrentConfig = 'DSC_WindowsEventLog_EnableLog'
                $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
                $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')

                It 'Should compile a MOF file without error' {
                    {
                        . $CurrentConfig -OutputPath $ConfigDir
                    } | Should -Not -Throw
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should apply the MOF correctly' {
                    {
                        Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                    } | Should -Not -Throw
                }

                It 'Should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should -BeTrue
                }
            }

            Context 'Disable a Logfile other than Application Windows Event Log' {
                $CurrentConfig = 'DSC_WindowsEventLog_DisableLog'
                $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
                $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')

                It 'Should compile a MOF file without error' {
                    {
                        . $CurrentConfig -OutputPath $ConfigDir
                    } | Should -Not -Throw
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should apply the MOF correctly' {
                    {
                        Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                    } | Should -Not -Throw
                }

                It 'Should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should -BeTrue
                }
            }

            Context 'Set Eventlog to Logmode Circular with a SecurityDescriptor' {
                $CurrentConfig = 'DSC_WindowsEventLog_CircularSecurityDescriptor'
                $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
                $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')

                It 'Should compile a MOF file without error' {
                    {
                        . $CurrentConfig -OutputPath $ConfigDir
                    } | Should -Not -Throw
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should apply the MOF correctly' {
                    {
                        Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                    } | Should -Not -Throw
                }

                It 'Should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should -BeTrue
                }
            }

            Context 'Enable a Logfile other than Application Windows Event Log with Retention' {
                $CurrentConfig = 'DSC_WindowsEventLog_EnableBackupLog'
                $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
                $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')

                It 'Should compile a MOF file error' {
                    {
                        . $CurrentConfig -OutputPath $ConfigDir
                    } | Should -Not -Throw
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should not apply the MOF' {
                    {
                        Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                    } | Should -Not -Throw
                }

                It 'Should return a incompliant state' {
                    (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should -BeFalse
                }
            }

            Context 'Disable a Logfile other than Application Eventlog with retention' {
                $CurrentConfig = 'DSC_WindowsEventLog_DisableBackupLog'
                $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
                $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')

                It 'Should compile a MOF file without error' {
                    {
                        . $CurrentConfig -OutputPath $ConfigDir
                    } | Should -Not -Throw
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should apply the MOF correctly' {
                    {
                        Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                    } | Should -Not -Throw
                }

                It 'Should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should -BeTrue
                }
            }

            Context 'Set Windows Event Log back to the default configuration' {
                $CurrentConfig = 'DSC_WindowsEventLog_Default'
                $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
                $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')

                It 'Should compile a MOF file without error' {
                    {
                        . $CurrentConfig -OutputPath $ConfigDir
                    } | Should -Not -Throw
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should apply the MOF correctly' {
                    {
                        Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                    } | Should -Not -Throw
                }

                It 'Should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should -BeTrue
                }
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
