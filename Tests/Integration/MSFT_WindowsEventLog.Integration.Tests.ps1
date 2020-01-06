#region HEADER
$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'MSFT_WindowsEventLog'

# Integration Test Template Version: 1.3.3
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
    -TestType Integration
#endregion

# Using try/finally to always cleanup.
try
{
    #region Integration Tests
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configFile
    Describe "$($script:dscResourceName)_Integration" {

        Context 'Set Windows Event Log to Logmode Retain' {
            $CurrentConfig = 'MSFT_WindowsEventLog_RetainSize'
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
            $CurrentConfig = 'MSFT_WindowsEventLog_AutobackupLogRetention'
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
            $CurrentConfig = 'MSFT_WindowsEventLog_CircularLogPath'
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
            $CurrentConfig = 'MSFT_WindowsEventLog_Default'
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
            $CurrentConfig = 'MSFT_WindowsEventLog_EnableLog'
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
            $CurrentConfig = 'MSFT_WindowsEventLog_DisableLog'
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
            $CurrentConfig = 'MSFT_WindowsEventLog_CircularSecurityDescriptor'
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
            $CurrentConfig = 'MSFT_WindowsEventLog_EnableBackupLog'
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
            $CurrentConfig = 'MSFT_WindowsEventLog_DisableBackupLog'
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
            $CurrentConfig = 'MSFT_WindowsEventLog_Default'
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
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
