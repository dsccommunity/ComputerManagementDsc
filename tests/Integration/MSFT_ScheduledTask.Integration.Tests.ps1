#Requires -Version 5.0
#region HEADER
$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'MSFT_ScheduledTask'

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

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

# Load the ComputerManagementDsc.Common module to use Set-TimezoneId function
Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'Modules' -ChildPath 'ComputerManagementDsc.Common')) -Force

# Begin Testing
try
{
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $ConfigFile

    #region Pester Tests
    Describe $script:dscResourceName {

        $contexts = @{
            Once              = 'ScheduledTaskOnce'
            Daily             = 'ScheduledTaskDaily'
            DailyIndefinitely = 'ScheduledTaskDailyIndefinitely'
            Weekly            = 'ScheduledTaskWeekly'
            AtLogon           = 'ScheduledTaskLogon'
            AtStartup         = 'ScheduledTaskStartup'
            ExecuteAs         = 'ScheduledTaskExecuteAs'
            ExecuteAsGroup    = 'ScheduledTaskExecuteAsGroup'
            OnEvent           = 'ScheduledTaskOnEvent'
        }

        $configData = @{
            AllNodes = @(
                @{
                    NodeName                    = 'localhost'
                    PSDscAllowPlainTextPassword = $true
                }
            )
        }

        foreach ($contextInfo in $contexts.GetEnumerator())
        {
            Context "[$($contextInfo.Key)] No scheduled task exists but it should" {
                $currentConfig = '{0}Add' -f $contextInfo.Value
                $configDir = (Join-Path -Path $TestDrive -ChildPath $currentConfig)
                $configMof = (Join-Path -Path $configDir -ChildPath 'localhost.mof')

                It 'Should compile the MOF without throwing' {
                    {
                        . $currentConfig `
                            -OutputPath $configDir `
                            -ConfigurationData $configData
                    } | Should -Not -Throw
                }

                It 'Should apply the MOF correctly' {
                    {
                        Start-DscConfiguration `
                            -Path $configDir `
                            -Wait `
                            -Force `
                            -Verbose `
                            -ErrorAction Stop
                    } | Should -Not -Throw
                }

                It 'Should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $configMof -Verbose).InDesiredState | Should -BeTrue
                }
            }

            Context "[$($contextInfo.Key)] A scheduled task exists with the wrong settings" {
                $currentConfig = '{0}Mod' -f $contextInfo.Value
                $configDir = (Join-Path -Path $TestDrive -ChildPath $currentConfig)
                $configMof = (Join-Path -Path $configDir -ChildPath 'localhost.mof')

                It 'Should compile the MOF without throwing' {
                    {
                        . $currentConfig `
                            -OutputPath $configDir `
                            -ConfigurationData $configData
                    } | Should -Not -Throw
                }

                It 'Should apply the MOF correctly' {
                    {
                        Start-DscConfiguration `
                            -Path $configDir `
                            -Wait `
                            -Force `
                            -Verbose `
                            -ErrorAction Stop
                    } | Should -Not -Throw
                }

                It 'Should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $configMof -Verbose).InDesiredState | Should -BeTrue
                }
            }

            Context "[$($contextInfo.Key)] A scheduled tasks exists but it should not" {
                $currentConfig = '{0}Del' -f $contextInfo.Value
                $configDir = (Join-Path -Path $TestDrive -ChildPath $currentConfig)
                $configMof = (Join-Path -Path $configDir -ChildPath 'localhost.mof')

                It 'Should compile the MOF without throwing' {
                    {
                        . $currentConfig `
                            -OutputPath $configDir `
                            -ConfigurationData $configData
                    } | Should -Not -Throw
                }

                It 'Should apply the MOF correctly' {
                    {
                        Start-DscConfiguration `
                            -Path $configDir `
                            -Wait `
                            -Force `
                            -Verbose `
                            -ErrorAction Stop
                    } | Should -Not -Throw
                }

                It 'Should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $configMof -Verbose).InDesiredState | Should -BeTrue
                }
            }
        }

        Context "MOF is created in a different timezone to node MOF being applied to" {
            BeforeAll {
                $currentTimeZoneId = Get-TimeZoneId
            }

            $currentConfig = 'ScheduledTaskOnceCrossTimezone'
            $configDir = (Join-Path -Path $TestDrive -ChildPath $currentConfig)
            $configMof = (Join-Path -Path $configDir -ChildPath 'localhost.mof')

            It 'Should compile the MOF without throwing in W. Australia Standard Time Timezone' {
                {

                    Set-TimeZoneId -TimeZoneId 'W. Australia Standard Time'
                    . $currentConfig `
                        -OutputPath $configDir
                } | Should -Not -Throw
            }

            It 'Should apply the MOF correctly in New Zealand Standard Time Timezone' {
                {
                    Set-TimeZoneId -TimeZoneId 'New Zealand Standard Time'
                    Start-DscConfiguration `
                        -Path $configDir `
                        -Wait `
                        -Force `
                        -Verbose `
                        -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should return a compliant state after being applied' {
                (Test-DscConfiguration -ReferenceConfiguration $configMof -Verbose).InDesiredState | Should -BeTrue
            }

            It 'Should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration   | Where-Object -FilterScript {$_.ConfigurationName -eq $currentConfig}
                $current.TaskName              | Should -Be 'Test task once cross timezone'
                $current.TaskPath              | Should -Be '\ComputerManagementDsc\'
                $current.ActionExecutable      | Should -Be 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                $current.ScheduleType          | Should -Be 'Once'
                $current.RepeatInterval        | Should -Be '00:15:00'
                $current.RepetitionDuration    | Should -Be '23:00:00'
                $current.ActionWorkingPath     | Should -Be (Get-Location).Path
                $current.Enable                | Should -BeTrue
                $current.RandomDelay           | Should -Be '01:00:00'
                $current.DisallowHardTerminate | Should -BeTrue
                $current.RunOnlyIfIdle         | Should -BeFalse
                $current.Priority              | Should -Be 9
                $current.RunLevel              | Should -Be 'Limited'
                $current.ExecutionTimeLimit    | Should -Be '00:00:00'
            }

            AfterAll {
                Set-TimeZoneId -TimeZoneId $currentTimeZoneId
            }
        }

        Context "When a scheduled task is created and synchronize across time zone is disabled" {
            $currentConfig = 'ScheduledTaskOnceSynchronizeAcrossTimeZoneDisabled'
            $configDir = (Join-Path -Path $TestDrive -ChildPath $currentConfig)
            $configMof = (Join-Path -Path $configDir -ChildPath 'localhost.mof')

            It 'Should compile the MOF without throwing' {
                {
                    . $currentConfig `
                        -OutputPath $configDir
                } | Should -Not -Throw
            }

            It 'Should apply the MOF correctly' {
                {
                    Start-DscConfiguration `
                        -Path $configDir `
                        -Wait `
                        -Force `
                        -Verbose `
                        -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should return a compliant state after being applied' {
                (Test-DscConfiguration -ReferenceConfiguration $configMof -Verbose).InDesiredState | Should -BeTrue
            }

            $expectedStartTime = '2018-10-01T01:00:00'

            It 'Should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration    | Where-Object -FilterScript {$_.ConfigurationName -eq $currentConfig}
                $current.TaskName                  | Should -Be 'Test task sync across time zone disabled'
                $current.TaskPath                  | Should -Be '\ComputerManagementDsc\'
                $current.ActionExecutable          | Should -Be 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                $current.ScheduleType              | Should -Be 'Once'
                $current.StartTime                 | Should -Be (Get-Date -Date $expectedStartTime)
                $current.SynchronizeAcrossTimeZone | Should -BeFalse
                $current.ActionWorkingPath         | Should -Be (Get-Location).Path
                $current.Enable                    | Should -BeTrue
            }

            It "Should have the trigger startBoundary set to $expectedStartTime" {
                $task = (Get-ScheduledTask -TaskName 'Test task sync across time zone disabled')
                $task.Triggers[0].StartBoundary | Should -Be $expectedStartTime
            }
        }

        Context "When a scheduled task is created and synchronize across time zone is enabled" {
            $currentConfig = 'ScheduledTaskOnceSynchronizeAcrossTimeZoneEnabled'
            $configDir = (Join-Path -Path $TestDrive -ChildPath $currentConfig)
            $configMof = (Join-Path -Path $configDir -ChildPath 'localhost.mof')

            It 'Should compile the MOF without throwing' {
                {
                    . $currentConfig `
                        -OutputPath $configDir
                } | Should -Not -Throw
            }

            It 'Should apply the MOF correctly' {
                {
                    Start-DscConfiguration `
                        -Path $configDir `
                        -Wait `
                        -Force `
                        -Verbose `
                        -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should return a compliant state after being applied' {
                (Test-DscConfiguration -ReferenceConfiguration $configMof -Verbose).InDesiredState | Should -BeTrue
            }

            $expectedStartTime = '2018-10-01T01:00:00' + (Get-Date -Format 'zzz')

            It 'Should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration    | Where-Object -FilterScript {$_.ConfigurationName -eq $currentConfig}
                $current.TaskName                  | Should -Be 'Test task sync across time zone enabled'
                $current.TaskPath                  | Should -Be '\ComputerManagementDsc\'
                $current.ActionExecutable          | Should -Be 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                $current.ScheduleType              | Should -Be 'Once'
                $current.StartTime                 | Should -Be (Get-Date -Date $expectedStartTime)
                $current.SynchronizeAcrossTimeZone | Should -BeTrue
                $current.ActionWorkingPath         | Should -Be (Get-Location).Path
                $current.Enable                    | Should -BeTrue
            }

            It "Should have the trigger startBoundary set to $expectedStartTime" {
                $task = (Get-ScheduledTask -TaskName 'Test task sync across time zone enabled')
                $task.Triggers[0].StartBoundary | Should -Be $expectedStartTime
            }
        }

        # Simulate a "built-in" scheduled task
        $action = New-ScheduledTaskAction -Execute 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date)
        $task = New-ScheduledTask -Action $action -Trigger $trigger
        Register-ScheduledTask -InputObject $task -TaskName 'Test task builtin' -TaskPath '\ComputerManagementDsc\' -User 'NT AUTHORITY\SYSTEM'

        Context 'Built-in task needs to be disabled' {
            $currentConfig = 'ScheduledTaskDisableBuiltIn'
            $configDir = (Join-Path -Path $TestDrive -ChildPath $currentConfig)
            $configMof = (Join-Path -Path $configDir -ChildPath 'localhost.mof')

            It 'Should compile the MOF without throwing' {
                {
                    . $currentConfig `
                        -OutputPath $configDir `
                        -ConfigurationData $configData
                } | Should -Not -Throw
            }

            It 'Should apply the MOF correctly' {
                {
                    Start-DscConfiguration `
                        -Path $configDir `
                        -Wait `
                        -Force `
                        -Verbose `
                        -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should return a compliant state after being applied' {
                (Test-DscConfiguration -ReferenceConfiguration $configMof -Verbose).InDesiredState | Should -BeTrue
            }

            It 'Should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration   | Where-Object -FilterScript {
                    $_.ConfigurationName -eq $currentConfig
                }
                $current.TaskName              | Should -Be 'Test task builtin'
                $current.TaskPath              | Should -Be '\ComputerManagementDsc\'
                $current.Enable                | Should -BeFalse
            }
        }

        Context 'Built-in task needs to be removed' {
            $currentConfig = 'ScheduledTaskRemoveBuiltIn'
            $configDir = (Join-Path -Path $TestDrive -ChildPath $currentConfig)
            $configMof = (Join-Path -Path $configDir -ChildPath 'localhost.mof')


            It 'Should compile the MOF without throwing' {
                {
                    . $currentConfig `
                        -OutputPath $configDir `
                        -ConfigurationData $configData
                } | Should -Not -Throw
            }

            It 'Should apply the MOF correctly' {
                {
                    Start-DscConfiguration `
                        -Path $configDir `
                        -Wait `
                        -Force `
                        -Verbose `
                        -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should return a compliant state after being applied' {
                (Test-DscConfiguration -ReferenceConfiguration $configMof -Verbose).InDesiredState | Should -BeTrue
            }

            It 'Should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration   | Where-Object -FilterScript {
                    $_.ConfigurationName -eq $currentConfig
                }
                $current.TaskName              | Should -Be 'Test task builtin'
                $current.TaskPath              | Should -Be '\ComputerManagementDsc\'
                $current.Ensure                | Should -Be 'Absent'
            }
        }
    }
}
finally
{
    #region FOOTER

    # Remove any traces of the created tasks
    Get-ScheduledTask -TaskPath '\ComputerManagementDsc\' -ErrorAction SilentlyContinue | Unregister-ScheduledTask -ErrorAction SilentlyContinue -Confirm:$false

    $scheduler = New-Object -ComObject Schedule.Service
    $scheduler.Connect()
    $rootFolder = $scheduler.GetFolder('\')
    $rootFolder.DeleteFolder('ComputerManagementDsc', 0)

    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
