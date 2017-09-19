#Requires -Version 5.0
$Global:DSCModuleName = 'xComputerManagement'
$Global:DSCResourceName = 'MSFT_xScheduledTask'
#region HEADER
# Integration Test Template Version: 1.1.1
[String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Integration
#endregion

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

# Begin Testing
try
{
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($Global:DSCResourceName).config.ps1"
    . $ConfigFile

    #region Pester Tests
    Describe $Global:DSCResourceName {

        $contexts = @{
            Once              = 'xScheduledTaskOnce'
            Daily             = 'xScheduledTaskDaily'
            DailyIndefinitely = 'xScheduledTaskDailyIndefinitely'
            Weekly            = 'xScheduledTaskWeekly'
            AtLogon           = 'xScheduledTaskLogon'
            AtStartup         = 'xScheduledTaskStartup'
        }

        foreach ($contextInfo in $contexts.GetEnumerator())
        {
            Context "[$($contextInfo.Key)] No scheduled task exists but it should" {
                $CurrentConfig = '{0}Add' -f $contextInfo.Value
                $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
                $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')

                It 'Should compile the MOF without throwing' {
                    {
                        . $CurrentConfig -OutputPath $ConfigDir
                    } | Should Not Throw
                }

                It 'Should apply the MOF correctly' {
                    {
                        Start-DscConfiguration -Path $ConfigDir -Wait -Force -Verbose
                    } | Should Not Throw
                }

                It 'Should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should be $true
                }
            }

            Context "[$($contextInfo.Key)] A scheduled task exists with the wrong settings" {
                $CurrentConfig = '{0}Mod' -f $contextInfo.Value
                $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
                $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')

                It 'Should compile the MOF without throwing' {
                    {
                        . $CurrentConfig -OutputPath $ConfigDir
                    } | Should Not Throw
                }

                It 'Should apply the MOF correctly' {
                    {
                        Start-DscConfiguration -Path $ConfigDir -Wait -Force -Verbose
                    } | Should Not Throw
                }

                It 'Should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should be $true
                }
            }

            Context "[$($contextInfo.Key)] A scheduled tasks exists but it should not" {
                $CurrentConfig = '{0}Del' -f $contextInfo.Value
                $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
                $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')

                It 'Should compile the MOF without throwing' {
                    {
                        . $CurrentConfig -OutputPath $ConfigDir
                    } | Should Not Throw
                }

                It 'Should apply the MOF correctly' {
                    {
                        Start-DscConfiguration -Path $ConfigDir -Wait -Force -Verbose
                    } | Should Not Throw
                }

                It 'Should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should be $true
                }
            }
        }

        Context "MOF is created in a different timezone to node MOF being applied to" {
            BeforeAll {
                $currentTimeZoneId = Get-TimeZoneId
            }

            $CurrentConfig = 'xScheduledTaskOnceCrossTimezone'
            $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
            $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')

            It 'Should compile the MOF without throwing in W. Australia Standard Time Timezone' {
                {

                    Set-TimeZoneId -Id 'W. Australia Standard Time'
                    . $CurrentConfig -OutputPath $ConfigDir
                } | Should Not Throw
            }

            It 'Should apply the MOF correctly in New Zealand Standard Time Timezone' {
                {
                    Set-TimeZoneId -Id 'New Zealand Standard Time'
                    Start-DscConfiguration -Path $ConfigDir -Wait -Force -Verbose
                } | Should Not Throw
            }

            It 'Should return a compliant state after being applied' {
                (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should be $true
            }

            It 'Should have set the resource and all the parameters should match' {
                $current = Get-DscConfiguration   | Where-Object {$_.ConfigurationName -eq $CurrentConfig}
                $current.TaskName              | Should Be 'Test task once cross timezone'
                $current.TaskPath              | Should Be '\xComputerManagement\'
                $current.ActionExecutable      | Should Be 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                $current.ScheduleType          | Should Be 'Once'
                $current.RepeatInterval        | Should Be '00:15:00'
                $current.RepetitionDuration    | Should Be '23:00:00'
                $current.ActionWorkingPath     | Should Be (Get-Location).Path
                $current.Enable                | Should Be $true
                $current.RandomDelay           | Should Be '01:00:00'
                $current.DisallowHardTerminate | Should Be $true
                $current.RunOnlyIfIdle         | Should Be $false
                $current.Priority              | Should Be 9
            }

            AfterAll {
                Set-TimeZoneId -Id $currentTimeZoneId
            }
        }
    }
}
finally
{
    #region FOOTER

    # Remove any traces of the created tasks
    Get-ScheduledTask -TaskPath '\xComputerManagement\' -ErrorAction SilentlyContinue | Unregister-ScheduledTask -ErrorAction SilentlyContinue -Confirm:$false

    $scheduler = New-Object -ComObject Schedule.Service
    $scheduler.Connect()
    $rootFolder = $scheduler.GetFolder('\')
    $rootFolder.DeleteFolder('xComputerManagement', 0)

    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
