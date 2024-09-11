#Requires -Version 5.0

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

    <#
        Need to define that variables here to be used in the Pester Discover to
        build the ForEach-blocks.
    #>
    $script:dscModuleName = 'ComputerManagementDsc'
    $script:dscResourceName = 'DSC_ScheduledTask'

    # Ensure that the tests can be performed on this computer
    $script:skipIntegrationTests = $false
}

BeforeAll {
    $script:dscModuleName = 'ComputerManagementDsc'
    $script:dscResourceName = 'DSC_ScheduledTask'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Integration'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')
}

AfterAll {
    # Remove any traces of the created tasks
    Get-ScheduledTask -TaskPath '\ComputerManagementDsc\' -ErrorAction SilentlyContinue | Unregister-ScheduledTask -ErrorAction SilentlyContinue -Confirm:$false

    $scheduler = New-Object -ComObject Schedule.Service
    $scheduler.Connect()
    $rootFolder = $scheduler.GetFolder('\')
    $rootFolder.DeleteFolder('ComputerManagementDsc', 0)

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Describe "$($script:dscResourceName)_Integration" {
    BeforeDiscovery {
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
            BuiltInAccount    = 'ScheduledTaskServiceAccount'
        }
    }

    BeforeAll {
        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile

        $configData = @{
            AllNodes = @(
                @{
                    NodeName                    = 'localhost'
                    PSDscAllowPlainTextPassword = $true
                }
            )
        }
    }

    Context '<_.Key> No scheduled task exists but it should' -ForEach $contexts {
        BeforeAll {
            $currentConfig = '{0}Add' -f $_.Value
            $configDir = (Join-Path -Path $TestDrive -ChildPath $currentConfig)
            $configMof = (Join-Path -Path $configDir -ChildPath 'localhost.mof')
        }

        It 'Should compile the MOF without throwing' {
            {
                . $currentConfig `
                    -OutputPath $configDir `
                    -ConfigurationData $configData
            } | Should -Not -Throw
        }

        It 'Should apply the MOF correctly' {
            {
                Reset-DscLcm

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

    Context '<$_.Key> A scheduled task exists with the wrong settings' -ForEach $contexts {
        BeforeAll {
            $currentConfig = '{0}Mod' -f $contextInfo.Value
            $configDir = (Join-Path -Path $TestDrive -ChildPath $currentConfig)
            $configMof = (Join-Path -Path $configDir -ChildPath 'localhost.mof')
        }

        It 'Should compile the MOF without throwing' {
            {
                . $currentConfig `
                    -OutputPath $configDir `
                    -ConfigurationData $configData
            } | Should -Not -Throw
        }

        It 'Should apply the MOF correctly' {
            {
                Reset-DscLcm

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

    Context '<_.Key> A scheduled tasks exists but it should not' -ForEach $contexts {
        BeforeAll {
            $currentConfig = '{0}Del' -f $_.Value
            $configDir = (Join-Path -Path $TestDrive -ChildPath $currentConfig)
            $configMof = (Join-Path -Path $configDir -ChildPath 'localhost.mof')
        }

        It 'Should compile the MOF without throwing' {
            {
                . $currentConfig `
                    -OutputPath $configDir `
                    -ConfigurationData $configData
            } | Should -Not -Throw
        }

        It 'Should apply the MOF correctly' {
            {
                Reset-DscLcm

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

    Context 'MOF is created in a different timezone to node MOF being applied to' {
        BeforeAll {
            $currentTimeZoneId = Get-TimeZoneId

            $currentConfig = 'ScheduledTaskOnceCrossTimezone'
            $configDir = (Join-Path -Path $TestDrive -ChildPath $currentConfig)
            $configMof = (Join-Path -Path $configDir -ChildPath 'localhost.mof')
        }

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

                Reset-DscLcm

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
            $current = Get-DscConfiguration | Where-Object -FilterScript { $_.ConfigurationName -eq $currentConfig }
            $current.TaskName | Should -Be 'Test task once cross timezone'
            $current.TaskPath | Should -Be '\ComputerManagementDsc\'
            $current.ActionExecutable | Should -Be 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            $current.ScheduleType | Should -Be 'Once'
            $current.RepeatInterval | Should -Be '00:15:00'
            $current.RepetitionDuration | Should -Be '23:00:00'
            $current.ActionWorkingPath | Should -Be (Get-Location).Path
            $current.Enable | Should -BeTrue
            $current.RandomDelay | Should -Be '01:00:00'
            $current.DisallowHardTerminate | Should -BeTrue
            $current.RunOnlyIfIdle | Should -BeFalse
            $current.Priority | Should -Be 9
            $current.RunLevel | Should -Be 'Limited'
            $current.ExecutionTimeLimit | Should -Be '00:00:00'
        }

        AfterAll {
            Set-TimeZoneId -TimeZoneId $currentTimeZoneId
        }
    }

    Context 'When a scheduled task is created and synchronize across time zone is disabled' {
        BeforeAll {
            $currentConfig = 'ScheduledTaskOnceSynchronizeAcrossTimeZoneDisabled'
            $configDir = (Join-Path -Path $TestDrive -ChildPath $currentConfig)
            $configMof = (Join-Path -Path $configDir -ChildPath 'localhost.mof')
        }

        It 'Should compile the MOF without throwing' {
            {
                . $currentConfig `
                    -OutputPath $configDir
            } | Should -Not -Throw
        }

        It 'Should apply the MOF correctly' {
            {
                Reset-DscLcm

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
            $current = Get-DscConfiguration | Where-Object -FilterScript { $_.ConfigurationName -eq $currentConfig }
            $current.TaskName | Should -Be 'Test task sync across time zone disabled'
            $current.TaskPath | Should -Be '\ComputerManagementDsc\'
            $current.ActionExecutable | Should -Be 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            $current.ScheduleType | Should -Be 'Once'
            $current.StartTime | Should -Be (Get-Date -Date '2018-10-01T01:00:00')
            $current.SynchronizeAcrossTimeZone | Should -BeFalse
            $current.ActionWorkingPath | Should -Be (Get-Location).Path
            $current.Enable | Should -BeTrue
        }

        It 'Should have the trigger startBoundary set to ''2018-10-01T01:00:00''' {
            $task = (Get-ScheduledTask -TaskName 'Test task sync across time zone disabled')
            $task.Triggers[0].StartBoundary | Should -Be '2018-10-01T01:00:00'
        }
    }

    Context 'When a scheduled task is created and synchronize across time zone is enabled' {
        BeforeAll {
            $currentConfig = 'ScheduledTaskOnceSynchronizeAcrossTimeZoneEnabled'
            $configDir = (Join-Path -Path $TestDrive -ChildPath $currentConfig)
            $configMof = (Join-Path -Path $configDir -ChildPath 'localhost.mof')
        }

        It 'Should compile the MOF without throwing' {
            {
                . $currentConfig `
                    -OutputPath $configDir
            } | Should -Not -Throw
        }

        It 'Should apply the MOF correctly' {
            {
                Reset-DscLcm

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
            $current = Get-DscConfiguration | Where-Object -FilterScript { $_.ConfigurationName -eq $currentConfig }
            $current.TaskName | Should -Be 'Test task sync across time zone enabled'
            $current.TaskPath | Should -Be '\ComputerManagementDsc\'
            $current.ActionExecutable | Should -Be 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            $current.ScheduleType | Should -Be 'Once'
            $current.StartTime | Should -Be (Get-Date -Date $expectedStartTime)
            $current.SynchronizeAcrossTimeZone | Should -BeTrue
            $current.ActionWorkingPath | Should -Be (Get-Location).Path
            $current.Enable | Should -BeTrue
        }

        It "Should have the trigger startBoundary set to $expectedStartTime" {
            $task = (Get-ScheduledTask -TaskName 'Test task sync across time zone enabled')
            $task.Triggers[0].StartBoundary | Should -Be $expectedStartTime
        }
    }

    Context 'Built-in task needs to be disabled' {
        BeforeAll {
            # Simulate a "built-in" scheduled task
            $action = New-ScheduledTaskAction -Execute 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date)
            $task = New-ScheduledTask -Action $action -Trigger $trigger
            Register-ScheduledTask -InputObject $task -TaskName 'Test task builtin' -TaskPath '\ComputerManagementDsc\' -User 'NT AUTHORITY\SYSTEM'

            $currentConfig = 'ScheduledTaskDisableBuiltIn'
            $configDir = (Join-Path -Path $TestDrive -ChildPath $currentConfig)
            $configMof = (Join-Path -Path $configDir -ChildPath 'localhost.mof')
        }

        It 'Should compile the MOF without throwing' {
            {
                . $currentConfig `
                    -OutputPath $configDir `
                    -ConfigurationData $configData
            } | Should -Not -Throw
        }

        It 'Should apply the MOF correctly' {
            {
                Reset-DscLcm

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
            $current = Get-DscConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $currentConfig
            }
            $current.TaskName | Should -Be 'Test task builtin'
            $current.TaskPath | Should -Be '\ComputerManagementDsc\'
            $current.Enable | Should -BeFalse
        }
    }

    Context 'Built-in task needs to be removed' {
        BeforeAll {
            $currentConfig = 'ScheduledTaskRemoveBuiltIn'
            $configDir = (Join-Path -Path $TestDrive -ChildPath $currentConfig)
            $configMof = (Join-Path -Path $configDir -ChildPath 'localhost.mof')
        }

        It 'Should compile the MOF without throwing' {
            {
                . $currentConfig `
                    -OutputPath $configDir `
                    -ConfigurationData $configData
            } | Should -Not -Throw
        }

        It 'Should apply the MOF correctly' {
            {
                Reset-DscLcm

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
            $current = Get-DscConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $currentConfig
            }
            $current.TaskName | Should -Be 'Test task builtin'
            $current.TaskPath | Should -Be '\ComputerManagementDsc\'
            $current.Ensure | Should -Be 'Absent'
        }
    }
}
