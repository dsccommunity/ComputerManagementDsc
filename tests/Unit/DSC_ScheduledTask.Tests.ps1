<#
    .SYNOPSIS
        Unit test for DSC_ScheduledTask DSC resource.

    .NOTES
#>

# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '')]
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
    $script:dscModuleName = 'ComputerManagementDsc'
    $script:dscResourceName = 'DSC_ScheduledTask'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName

    InModuleScope -ScriptBlock {
        # Function to allow mocking pipeline input
        function script:Register-ScheduledTask
        {
            param
            (
                [Parameter()]
                [switch]
                $Force,

                [Parameter(ValueFromPipeline = $true)]
                $InputObject,

                [Parameter()]
                [System.String]
                $Password,

                [Parameter()]
                [System.String]
                $User,

                [Parameter()]
                [System.String]
                $TaskName,

                [Parameter()]
                [System.String]
                $TaskPath
            )
        }

        # Function to allow mocking pipeline input
        function script:Set-ScheduledTask
        {
            param
            (
                [Parameter()]
                [switch]
                $Force,

                [Parameter(ValueFromPipeline = $true)]
                $InputObject,

                [Parameter()]
                [System.String]
                $Password,

                [Parameter()]
                [System.String]
                $User
            )
        }
    }
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

Describe 'DSC_ScheduledTask' {
    BeforeAll {
        Mock -CommandName Disable-ScheduledTask
        Mock -CommandName Register-ScheduledTask
        Mock -CommandName Set-ScheduledTask
        Mock -CommandName Unregister-ScheduledTask

        $getTargetResourceParameters = @{
            TaskName = 'Test task'
            TaskPath = '\Test\'
        }

        InModuleScope -Parameters @{
            getTargetResourceParameters = $getTargetResourceParameters
        } -ScriptBlock {
            $script:getTargetResourceParameters = $getTargetResourceParameters
        }
    }

    BeforeEach {
        InModuleScope -Parameters @{
            testParameters = $testParameters
        } -ScriptBlock {
            $script:testParameters = $testParameters
        }
    }

    Context 'No scheduled task exists, but it should' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                ScheduleType       = 'Once'
                RepeatInterval     = (New-TimeSpan -Minutes 15).ToString()
                RepetitionDuration = (New-TimeSpan -Minutes 150).ToString()
            }

            Mock -CommandName Get-ScheduledTask -MockWith { return $null }
        }


        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Ensure | Should -Be 'Absent'
            }
        }

        It 'Should return false from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeFalse
            }
        }

        It 'Should create the scheduled task in the set method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters
            }

            Assert-MockCalled Register-ScheduledTask -Exactly -Times 1 -Scope It
        }
    }

    Context 'A scheduled task exists, but it should not' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                ScheduleType       = 'Once'
                RepeatInterval     = (New-TimeSpan -Minutes 15).ToString()
                RepetitionDuration = (New-TimeSpan -Minutes 15).ToString()
                Ensure             = 'Absent'
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName  = $testParameters.TaskName
                    TaskPath  = $testParameters.TaskPath
                    Actions   = @(@{
                            Execute = $testParameters.ActionExecutable
                        })
                    Triggers  = @(@{
                            Repetition = @{
                                Duration = "PT$([System.TimeSpan]::Parse($testParameters.RepetitionDuration).TotalMinutes)M"
                                Interval = "PT$([System.TimeSpan]::Parse($testParameters.RepeatInterval).TotalMinutes)M"
                            }
                            CimClass   = @{
                                CimClassName = 'MSFT_TaskTimeTrigger'
                            }
                        })
                    Settings  = [pscustomobject] @{
                        Enabled           = $true
                        MultipleInstances = 'IgnoreNew'
                    }
                    Principal = @{
                        UserId = 'SYSTEM'
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Ensure | Should -Be 'Present'
            }
        }

        It 'Should return false from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeFalse
            }
        }

        It 'Should remove the scheduled task in the set method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters
            }

            Assert-MockCalled Unregister-ScheduledTask -Exactly -Times 1 -Scope It
        }
    }

    Context 'A built-in scheduled task exists and is enabled, but it should be disabled' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                Enable = $false
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName = $testParameters.TaskName
                    TaskPath = $testParameters.TaskPath
                    Actions  = [pscustomobject] @{
                        Execute = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    }
                    Triggers = [pscustomobject] @{
                        Repetition = @{
                            Duration = 'PT15M'
                            Interval = 'PT15M'
                        }
                        CimClass   = @{
                            CimClassName = 'MSFT_TaskTimeTrigger'
                        }
                    }
                    Settings = [pscustomobject] @{
                        Enabled           = $true
                        MultipleInstances = 'StopExisting'
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Enable | Should -BeTrue
                $result.Ensure | Should -Be 'Present'
            }
        }

        It 'Should return false from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeFalse
            }
        }

        It 'Should remove the scheduled task in the set method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters
            }

            if ($PSVersionTable.PSVersion -gt [System.Version]'5.0.0.0')
            {
                Assert-MockCalled Disable-ScheduledTask -Exactly -Times 1
            }
            else
            {
                Assert-MockCalled Register-ScheduledTask -Exactly -Times 1
            }

        }
    }

    Context 'A built-in scheduled task exists, but it should be absent' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                Ensure = 'Absent'
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName = $testParameters.TaskName
                    TaskPath = $testParameters.TaskPath
                    Actions  = @(
                        [pscustomobject] @{
                            Execute = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                        }
                    )
                    Triggers = @(
                        [pscustomobject] @{
                            Repetition = @{
                                Duration = 'PT15M'
                                Interval = 'PT15M'
                            }
                            CimClass   = @{
                                CimClassName = 'MSFT_TaskTimeTrigger'
                            }
                        }
                    )
                    Settings = [pscustomobject] @{
                        Enabled           = $true
                        MultipleInstances = 'StopExisting'
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Enable | Should -BeTrue
                $result.Ensure | Should -Be 'Present'
            }
        }

        It 'Should return false from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeFalse
            }
        }

        It 'Should remove the scheduled task in the set method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters
            }

            Assert-MockCalled Unregister-ScheduledTask -Exactly -Times 1
        }
    }

    Context 'A scheduled task doesnt exist, and it should not' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                ScheduleType     = 'Once'
                Ensure           = 'Absent'
            }

            Mock -CommandName Get-ScheduledTask
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Ensure | Should -Be 'Absent'
            }
        }

        It 'Should return true from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeTrue
            }
        }
    }

    Context 'A scheduled task with Once based repetition exists, but has the wrong settings' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                ScheduleType       = 'Once'
                RepeatInterval     = (New-TimeSpan -Minutes 15).ToString()
                RepetitionDuration = (New-TimeSpan -Minutes 150).ToString()
                StopAtDurationEnd  = $true
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName  = $testParameters.TaskName
                    TaskPath  = $testParameters.TaskPath
                    Actions   = @(
                        [pscustomobject] @{
                            Execute = $testParameters.ActionExecutable
                        }
                    )
                    Triggers  = @(
                        [pscustomobject] @{
                            Repetition = @{
                                Duration = ''
                                Interval = "PT$(([System.TimeSpan]::Parse($testParameters.RepeatInterval).TotalMinutes) + 1)M"
                                StopAtDurationEnd = -not $testParameters.StopAtDurationEnd
                            }
                            CimClass   = @{
                                CimClassName = 'MSFT_TaskTimeTrigger'
                            }
                        }
                    )
                    Settings  = [pscustomobject] @{
                        Enabled           = $true
                        MultipleInstances = 'IgnoreNew'
                    }
                    Principal = [pscustomobject] @{
                        UserId = 'SYSTEM'
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Ensure | Should -Be 'Present'
            }
        }

        It 'Should return false from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeFalse
            }
        }

        It 'Should update the scheduled task in the set method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters
            }

            Assert-MockCalled -CommandName Set-ScheduledTask -Exactly -Times 1 -Scope It
        }

        It 'Should throw expected exception if repeat duration is less than interval' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($LocalizedData.RepetitionDurationLessThanIntervalError -f $testParameters.RepetitionDuration, $testParameters.RepeatInterval) `
                    -ArgumentName 'RepeatInterval'

                $testParameters.RepetitionDuration = (New-TimeSpan -Minutes 10).ToString()
                { Set-TargetResource @testParameters } | Should -Throw $errorRecord
            }
        }
    }

    Context 'A scheduled task with minutes based repetition exists and has the correct settings' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                ScheduleType       = 'Once'
                RepeatInterval     = (New-TimeSpan -Minutes 15).ToString()
                RepetitionDuration = (New-TimeSpan -Minutes 30).ToString()
                StopAtDurationEnd  = $true
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName  = $testParameters.TaskName
                    TaskPath  = $testParameters.TaskPath
                    Actions   = @(
                        [pscustomobject] @{
                            Execute = $testParameters.ActionExecutable
                        }
                    )
                    Triggers  = @(
                        [pscustomobject] @{
                            Repetition = @{
                                Duration = "PT$([System.TimeSpan]::Parse($testParameters.RepetitionDuration).TotalMinutes)M"
                                Interval = "PT$([System.TimeSpan]::Parse($testParameters.RepeatInterval).TotalMinutes)M"
                                StopAtDurationEnd = $testParameters.StopAtDurationEnd
                            }
                            CimClass   = @{
                                CimClassName = 'MSFT_TaskTimeTrigger'
                            }
                        }
                    )
                    Settings  = [pscustomobject] @{
                        Enabled           = $true
                        MultipleInstances = 'IgnoreNew'
                    }
                    Principal = [pscustomobject] @{
                        UserId = 'SYSTEM'
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Ensure | Should -Be 'Present'
            }
        }

        It 'Should return true from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeTrue
            }
        }
    }

    Context 'A scheduled task with hourly based repetition exists, but has the wrong settings' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                ScheduleType       = 'Once'
                RepeatInterval     = (New-TimeSpan -Hours 4).ToString()
                RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
                StopAtDurationEnd  = $true
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName  = $testParameters.TaskName
                    TaskPath  = $testParameters.TaskPath
                    Actions   = @(
                        [pscustomobject] @{
                            Execute = $testParameters.ActionExecutable
                        }
                    )
                    Triggers  = @(
                        [pscustomobject] @{
                            Repetition = @{
                                Duration = "PT$(([System.TimeSpan]::Parse($testParameters.RepetitionDuration).TotalHours))H"
                                Interval = "PT$(([System.TimeSpan]::Parse($testParameters.RepeatInterval).TotalHours) + 1)H"
                                StopAtDurationEnd = -not $testParameters.StopAtDurationEnd
                            }
                            CimClass   = @{
                                CimClassName = 'MSFT_TaskTimeTrigger'
                            }
                        }
                    )
                    Settings  = [pscustomobject] @{
                        Enabled           = $true
                        MultipleInstances = 'IgnoreNew'
                    }
                    Principal = [pscustomobject] @{
                        UserId = 'SYSTEM'
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Ensure | Should -Be 'Present'
            }
        }

        It 'Should return false from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeFalse
            }
        }

        It 'Should update the scheduled task in the set method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters
            }

            Assert-MockCalled -CommandName Set-ScheduledTask -Exactly -Times 1 -Scope It
        }

        It 'Should throw expected exception if repeat duration is less than interval' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($LocalizedData.RepetitionDurationLessThanIntervalError -f $testParameters.RepetitionDuration, $testParameters.RepeatInterval) `
                    -ArgumentName 'RepeatInterval'

                $testParameters.RepetitionDuration = (New-TimeSpan -Hours 2).ToString()
                { Set-TargetResource @testParameters } | Should -Throw $errorRecord
            }
        }
    }

    Context 'A scheduled task with hourly based repetition exists and has the correct settings' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                ScheduleType       = 'Once'
                RepeatInterval     = (New-TimeSpan -Hours 4).ToString()
                RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
                StopAtDurationEnd  = $true
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName  = $testParameters.TaskName
                    TaskPath  = $testParameters.TaskPath
                    Actions   = @(
                        [pscustomobject] @{
                            Execute = $testParameters.ActionExecutable
                        }
                    )
                    Triggers  = @(
                        [pscustomobject] @{
                            Repetition = @{
                                Duration = "PT$([System.TimeSpan]::Parse($testParameters.RepetitionDuration).TotalHours)H"
                                Interval = "PT$([System.TimeSpan]::Parse($testParameters.RepeatInterval).TotalHours)H"
                                StopAtDurationEnd = $testParameters.StopAtDurationEnd
                            }
                            CimClass   = @{
                                CimClassName = 'MSFT_TaskTimeTrigger'
                            }
                        }
                    )
                    Settings  = [pscustomobject] @{
                        Enabled           = $true
                        MultipleInstances = 'IgnoreNew'
                    }
                    Principal = [pscustomobject] @{
                        UserId = 'SYSTEM'
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Ensure | Should -Be 'Present'
            }
        }

        It 'Should return true from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeTrue
            }
        }
    }

    Context 'A scheduled task with daily based repetition exists, but has the wrong settings' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                ScheduleType     = 'Daily'
                DaysInterval     = 3
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName  = $testParameters.TaskName
                    TaskPath  = $testParameters.TaskPath
                    Actions   = @(
                        [pscustomobject] @{
                            Execute = $testParameters.ActionExecutable
                        }
                    )
                    Triggers  = @(
                        [pscustomobject] @{
                            Repetition = @{
                                Duration = $null
                                Interval = "P$(($testParameters.DaysInterval) + 1)D"
                            }
                            CimClass   = @{
                                CimClassName = 'MSFT_TaskDailyTrigger'
                            }
                        }
                    )
                    Settings  = [pscustomobject] @{
                        Enabled           = $true
                        MultipleInstances = 'IgnoreNew'
                    }
                    Principal = [pscustomobject] @{
                        UserId = 'SYSTEM'
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Ensure | Should -Be 'Present'
            }
        }

        It 'Should return false from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeFalse
            }
        }

        It 'Should update the scheduled task in the set method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters
            }

            Assert-MockCalled -CommandName Set-ScheduledTask -Exactly -Times 1 -Scope It
        }

        It 'Should throw expected exception if days interval is not defined' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($LocalizedData.DaysIntervalError -f $testParameters.DaysInterval) `
                    -ArgumentName 'DaysInterval'

                $testParameters.Remove('DaysInterval')
                { Set-TargetResource @testParameters } | Should -Throw $errorRecord
            }
        }
    }

    Context 'A scheduled task with daily based repetition exists and has the correct settings' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                ScheduleType     = 'Daily'
                DaysInterval     = 3
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName  = $testParameters.TaskName
                    TaskPath  = $testParameters.TaskPath
                    Actions   = @(
                        [pscustomobject] @{
                            Execute = $testParameters.ActionExecutable
                        }
                    )
                    Triggers  = @(
                        [pscustomobject] @{
                            DaysInterval = $testParameters.DaysInterval
                            CimClass     = @{
                                CimClassName = 'MSFT_TaskDailyTrigger'
                            }
                        }
                    )
                    Settings  = [pscustomobject] @{
                        Enabled           = $true
                        MultipleInstances = 'IgnoreNew'
                    }
                    Principal = [pscustomobject] @{
                        UserId = 'SYSTEM'
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Ensure | Should -Be 'Present'
            }
        }

        It 'Should return true from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeTrue
            }
        }
    }

    Context 'A scheduled task exists and is configured with the wrong execution account' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable    = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                ScheduleType        = 'Once'
                RepeatInterval      = (New-TimeSpan -Minutes 15).ToString()
                RepetitionDuration  = (New-TimeSpan -Hours 8).ToString()
                ExecuteAsCredential = New-Object System.Management.Automation.PSCredential ('DEMO\RightUser', (ConvertTo-SecureString 'ExamplePassword' -AsPlainText -Force))
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName  = $testParameters.TaskName
                    TaskPath  = $testParameters.TaskPath
                    Actions   = @(
                        [pscustomobject] @{
                            Execute = $testParameters.ActionExecutable
                        }
                    )
                    Triggers  = @(
                        [pscustomobject] @{
                            Repetition = @{
                                Duration = "PT$([System.TimeSpan]::Parse($testParameters.RepetitionDuration).TotalHours)H"
                                Interval = "PT$([System.TimeSpan]::Parse($testParameters.RepeatInterval).TotalMinutes)M"
                            }
                            CimClass   = @{
                                CimClassName = 'MSFT_TaskTimeTrigger'
                            }
                        }
                    )
                    Settings  = [pscustomobject] @{
                        Enabled           = $true
                        MultipleInstances = 'IgnoreNew'
                    }
                    Principal = [pscustomobject] @{
                        UserId = 'WrongUser'
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Ensure | Should -Be 'Present'
            }
        }

        It 'Should return false from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeFalse
            }
        }

        It 'Should update the scheduled task in the set method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters
            }

            Assert-MockCalled -CommandName Set-ScheduledTask -Exactly -Times 1 -Scope It
        }
    }

    Context 'A scheduled task exists and is configured with the wrong logon type' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable    = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                ScheduleType        = 'Once'
                RepeatInterval      = (New-TimeSpan -Minutes 15).ToString()
                RepetitionDuration  = (New-TimeSpan -Hours 8).ToString()
                ExecuteAsCredential = New-Object System.Management.Automation.PSCredential ('DEMO\RightUser', (ConvertTo-SecureString 'ExamplePassword' -AsPlainText -Force))
                LogonType           = 'S4U'
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName  = $testParameters.TaskName
                    TaskPath  = $testParameters.TaskPath
                    Actions   = [pscustomobject] @(
                        @{
                            Execute = $testParameters.ActionExecutable
                        }
                    )
                    Triggers  = @(
                        [pscustomobject] @{
                            Repetition = @{
                                Duration = "PT$([System.TimeSpan]::Parse($testParameters.RepetitionDuration).TotalHours)H"
                                Interval = "PT$([System.TimeSpan]::Parse($testParameters.RepeatInterval).TotalMinutes)M"
                            }
                            CimClass   = @{
                                CimClassName = 'MSFT_TaskTimeTrigger'
                            }
                        }
                    )
                    Settings  = [pscustomobject] @{
                        Enabled           = $true
                        MultipleInstances = 'IgnoreNew'
                    }
                    Principal = [pscustomobject] @{
                        UserId    = 'DEMO\RightUser'
                        LogonType = 'Password'
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Ensure | Should -Be 'Present'
                $result.LogonType | Should -Be 'Password'
            }
        }

        It 'Should return false from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeFalse
            }
        }

        It 'Should update the scheduled task in the set method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters
            }

            Assert-MockCalled -CommandName Set-ScheduledTask -Exactly -Times 1 -Scope It
        }
    }

    Context 'A scheduled task exists and is configured with the wrong run level' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable    = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                ScheduleType        = 'Once'
                RepeatInterval      = (New-TimeSpan -Minutes 15).ToString()
                RepetitionDuration  = (New-TimeSpan -Hours 8).ToString()
                ExecuteAsCredential = New-Object System.Management.Automation.PSCredential ('DEMO\RightUser', (ConvertTo-SecureString 'ExamplePassword' -AsPlainText -Force))
                RunLevel            = 'Highest'
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName  = $testParameters.TaskName
                    TaskPath  = $testParameters.TaskPath
                    Actions   = @(
                        [pscustomobject] @{
                            Execute = $testParameters.ActionExecutable
                        }
                    )
                    Triggers  = @(
                        [pscustomobject] @{
                            Repetition = @{
                                Duration = "PT$([System.TimeSpan]::Parse($testParameters.RepetitionDuration).TotalHours)H"
                                Interval = "PT$([System.TimeSpan]::Parse($testParameters.RepeatInterval).TotalMinutes)M"
                            }
                            CimClass   = @{
                                CimClassName = 'MSFT_TaskTimeTrigger'
                            }
                        }
                    )
                    Settings  = [pscustomobject] @{
                        Enabled           = $true
                        MultipleInstances = 'IgnoreNew'
                    }
                    Principal = [pscustomobject] @{
                        UserId   = 'DEMO\RightUser'
                        RunLevel = 'Limited'
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Ensure | Should -Be 'Present'
                $result.RunLevel | Should -Be 'Limited'
            }
        }

        It 'Should return false from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeFalse
            }
        }

        It 'Should update the scheduled task in the set method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters
            }

            Assert-MockCalled -CommandName Set-ScheduledTask -Exactly -Times 1 -Scope It
        }
    }

    Context 'A scheduled task exists and is configured with the wrong working directory' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                ActionWorkingPath  = 'C:\Example'
                ScheduleType       = 'Once'
                RepeatInterval     = (New-TimeSpan -Minutes 15).ToString()
                RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName  = $testParameters.TaskName
                    TaskPath  = $testParameters.TaskPath
                    Actions   = @(
                        [pscustomobject] @{
                            Execute          = $testParameters.ActionExecutable
                            WorkingDirectory = 'C:\Wrong'
                        }
                    )
                    Triggers  = @(
                        [pscustomobject] @{
                            Repetition = @{
                                Duration = $null
                                Interval = "PT$([System.TimeSpan]::Parse($testParameters.RepeatInterval).TotalMinutes)M"
                            }
                            CimClass   = @{
                                CimClassName = 'MSFT_TaskTimeTrigger'
                            }
                        }
                    )
                    Settings  = [pscustomobject] @{
                        Enabled           = $true
                        MultipleInstances = 'IgnoreNew'
                    }
                    Principal = [pscustomobject] @{
                        UserId = 'SYSTEM'
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Ensure | Should -Be 'Present'
            }
        }

        It 'Should return false from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeFalse
            }
        }

        It 'Should update the scheduled task in the set method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters
            }

            Assert-MockCalled -CommandName Set-ScheduledTask -Exactly -Times 1 -Scope It
        }
    }

    Context 'A scheduled task exists and is configured with the wrong executable arguments' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                ActionArguments    = '-File "C:\something\right.ps1"'
                ScheduleType       = 'Once'
                RepeatInterval     = (New-TimeSpan -Minutes 15).ToString()
                RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName  = $testParameters.TaskName
                    TaskPath  = $testParameters.TaskPath
                    Actions   = @(
                        [pscustomobject] @{
                            Execute   = $testParameters.ActionExecutable
                            Arguments = '-File "C:\something\wrong.ps1"'
                        }
                    )
                    Triggers  = @(
                        [pscustomobject] @{
                            Repetition = @{
                                Duration = "PT$([System.TimeSpan]::Parse($testParameters.RepetitionDuration).TotalHours)H"
                                Interval = "PT$([System.TimeSpan]::Parse($testParameters.RepeatInterval).TotalMinutes)M"
                            }
                            CimClass   = @{
                                CimClassName = 'MSFT_TaskTimeTrigger'
                            }
                        }
                    )
                    Settings  = [pscustomobject] @{
                        Enabled           = $true
                        MultipleInstances = 'IgnoreNew'
                    }
                    Principal = [pscustomobject] @{
                        UserId = 'SYSTEM'
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Ensure | Should -Be 'Present'
            }
        }

        It 'Should return false from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeFalse
            }
        }

        It 'Should update the scheduled task in the set method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters
            }

            Assert-MockCalled -CommandName Set-ScheduledTask -Exactly -Times 1 -Scope It
        }
    }

    Context 'A scheduled task is enabled and should be disabled' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                ScheduleType       = 'Once'
                RepeatInterval     = (New-TimeSpan -Minutes 15).ToString()
                RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
                Enable             = $false
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName  = $testParameters.TaskName
                    TaskPath  = $testParameters.TaskPath
                    Actions   = @(
                        [pscustomobject] @{
                            Execute   = $testParameters.ActionExecutable
                            Arguments = $testParameters.Arguments
                        }
                    )
                    Triggers  = @(
                        [pscustomobject] @{
                            Repetition = @{
                                Duration = "PT$([System.TimeSpan]::Parse($testParameters.RepetitionDuration).TotalHours)H"
                                Interval = "PT$([System.TimeSpan]::Parse($testParameters.RepeatInterval).TotalMinutes)M"
                            }
                            CimClass   = @{
                                CimClassName = 'MSFT_TaskTimeTrigger'
                            }
                        }
                    )
                    Settings  = [pscustomobject] @{
                        Enabled           = $true
                        MultipleInstances = 'IgnoreNew'
                    }
                    Principal = [pscustomobject] @{
                        UserId = 'SYSTEM'
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Ensure | Should -Be 'Present'
            }
        }

        It 'Should return false from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeFalse
            }
        }

        It 'Should update the scheduled task in the set method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters
            }

            Assert-MockCalled -CommandName Set-ScheduledTask -Exactly -Times 1 -Scope It
        }

    }

    Context 'A scheduled task is enabled without an execution time limit and but has an execution time limit set' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable          = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                ScheduleType              = 'Once'
                RepeatInterval            = (New-TimeSpan -Minutes 15).ToString()
                RepetitionDuration        = (New-TimeSpan -Hours 8).ToString()
                ExecutionTimeLimit        = (New-TimeSpan -Seconds 0).ToString()
                TriggerExecutionTimeLimit = (New-TimeSpan -Seconds 0).ToString()
                Enable                    = $true
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName  = $testParameters.TaskName
                    TaskPath  = $testParameters.TaskPath
                    Actions   = @(
                        [pscustomobject] @{
                            Execute   = $testParameters.ActionExecutable
                            Arguments = $testParameters.Arguments
                        }
                    )
                    Triggers  = @(
                        [pscustomobject] @{
                            ExecutionTimeLimit = "PT$([System.TimeSpan]::Parse($testParameters.RepeatInterval).TotalSeconds + 60)S"
                            Repetition = @{
                                Duration = "PT$([System.TimeSpan]::Parse($testParameters.RepetitionDuration).TotalHours)H"
                                Interval = "PT$([System.TimeSpan]::Parse($testParameters.RepeatInterval).TotalMinutes)M"
                            }
                            CimClass   = @{
                                CimClassName = 'MSFT_TaskTimeTrigger'
                            }
                        }
                    )
                    Settings  = [pscustomobject] @{
                        Enabled            = $true
                        ExecutionTimeLimit = "PT$([System.TimeSpan]::Parse($testParameters.RepeatInterval).TotalSeconds + 60)S"
                        MultipleInstances  = 'IgnoreNew'
                    }
                    Principal = [pscustomobject] @{
                        UserId = 'SYSTEM'
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Ensure | Should -Be 'Present'
            }
        }

        It 'Should return false from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeFalse
            }
        }

        It 'Should update the scheduled task in the set method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters
            }

            Assert-MockCalled -CommandName Set-ScheduledTask -Exactly -Times 1 -Scope It
        }
    }

    Context 'A scheduled task is enabled and has the correct settings' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable          = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                ScheduleType              = 'Once'
                RepeatInterval            = (New-TimeSpan -Minutes 15).ToString()
                RepetitionDuration        = (New-TimeSpan -Hours 8).ToString()
                RandomDelay               = (New-TimeSpan -Minutes 4).ToString()
                IdleWaitTimeout           = (New-TimeSpan -Minutes 5).ToString()
                IdleDuration              = (New-TimeSpan -Minutes 6).ToString()
                ExecutionTimeLimit        = (New-TimeSpan -Minutes 7).ToString()
                RestartInterval           = (New-TimeSpan -Minutes 8).ToString()
                TriggerExecutionTimeLimit = (New-TimeSpan -Minutes 9).ToString()
                Enable             = $true
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName  = $testParameters.TaskName
                    TaskPath  = $testParameters.TaskPath
                    Actions   = @(
                        [pscustomobject] @{
                            Execute   = $testParameters.ActionExecutable
                            Arguments = $testParameters.Arguments
                        }
                    )
                    Triggers  = @(
                        [pscustomobject] @{
                            ExecutionTimeLimit = "PT$([System.TimeSpan]::Parse($testParameters.TriggerExecutionTimeLimit).TotalMinutes)M"
                            Repetition  = @{
                                Duration = "PT$([System.TimeSpan]::Parse($testParameters.RepetitionDuration).TotalHours)H"
                                Interval = "PT$([System.TimeSpan]::Parse($testParameters.RepeatInterval).TotalMinutes)M"
                            }
                            RandomDelay = "PT$([System.TimeSpan]::Parse($testParameters.RandomDelay).TotalMinutes)M"
                            CimClass    = @{
                                CimClassName = 'MSFT_TaskTimeTrigger'
                            }
                        }
                    )
                    Settings  = [pscustomobject] @{
                        Enabled            = $true
                        IdleSettings       = @{
                            WaitTimeout  = "PT$([System.TimeSpan]::Parse($testParameters.IdleWaitTimeout).TotalMinutes)M"
                            IdleDuration = "PT$([System.TimeSpan]::Parse($testParameters.IdleDuration).TotalMinutes)M"
                        }
                        ExecutionTimeLimit = "PT$([System.TimeSpan]::Parse($testParameters.ExecutionTimeLimit).TotalMinutes)M"
                        RestartInterval    = "PT$([System.TimeSpan]::Parse($testParameters.RestartInterval).TotalMinutes)M"
                        MultipleInstances  = 'IgnoreNew'
                    }
                    Principal = [pscustomobject] @{
                        UserId = 'SYSTEM'
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Ensure | Should -Be 'Present'
            }
        }

        It 'Should return true from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeTrue
            }
        }
    }

    Context 'A scheduled task is disabled and has the correct settings' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                ScheduleType       = 'Once'
                RepeatInterval     = (New-TimeSpan -Minutes 15).ToString()
                RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
                Enable             = $false
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName  = $testParameters.TaskName
                    TaskPath  = $testParameters.TaskPath
                    Actions   = @(
                        [pscustomobject] @{
                            Execute   = $testParameters.ActionExecutable
                            Arguments = $testParameters.Arguments
                        }
                    )
                    Triggers  = @(
                        [pscustomobject] @{
                            Repetition = @{
                                Duration = "PT$([System.TimeSpan]::Parse($testParameters.RepetitionDuration).TotalHours)H"
                                Interval = "PT$([System.TimeSpan]::Parse($testParameters.RepeatInterval).TotalMinutes)M"
                            }
                            CimClass   = @{
                                CimClassName = 'MSFT_TaskTimeTrigger'
                            }
                        }
                    )
                    Settings  = [pscustomobject] @{
                        Enabled           = $false
                        MultipleInstances = 'IgnoreNew'
                    }
                    Principal = [pscustomobject] @{
                        UserId = 'SYSTEM'
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Ensure | Should -Be 'Present'
            }
        }

        It 'Should return true from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeTrue
            }
        }
    }

    Context 'A scheduled task is disabled but should be enabled' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                ScheduleType       = 'Once'
                RepeatInterval     = (New-TimeSpan -Minutes 15).ToString()
                RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
                Enable             = $true
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName  = $testParameters.TaskName
                    TaskPath  = $testParameters.TaskPath
                    Actions   = @(
                        [pscustomobject] @{
                            Execute   = $testParameters.ActionExecutable
                            Arguments = $testParameters.Arguments
                        }
                    )
                    Triggers  = @(
                        [pscustomobject] @{
                            Repetition = @{
                                Duration = "PT$([System.TimeSpan]::Parse($testParameters.RepetitionDuration).TotalHours)H"
                                Interval = "PT$([System.TimeSpan]::Parse($testParameters.RepeatInterval).TotalMinutes)M"
                            }
                            CimClass   = @{
                                CimClassName = 'MSFT_TaskTimeTrigger'
                            }
                        }
                    )
                    Settings  = [pscustomobject] @{
                        Enabled           = $false
                        MultipleInstances = 'IgnoreNew'
                    }
                    Principal = [pscustomobject] @{
                        UserId = 'SYSTEM'
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Ensure | Should -Be 'Present'
            }
        }

        It 'Should return false from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeFalse
            }
        }

        It 'Should update the scheduled task in the set method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters
            }

            Assert-MockCalled -CommandName Set-ScheduledTask -Exactly -Times 1 -Scope It
        }
    }

    Context 'A Scheduled task exists, is disabled, and the optional parameter enable is not specified' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                ScheduleType       = 'Once'
                RepeatInterval     = (New-TimeSpan -Minutes 15).ToString()
                RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName  = $testParameters.TaskName
                    TaskPath  = $testParameters.TaskPath
                    Actions   = @(
                        [pscustomobject] @{
                            Execute   = $testParameters.ActionExecutable
                            Arguments = $testParameters.Arguments
                        }
                    )
                    Triggers  = @(
                        [pscustomobject] @{
                            Repetition = @{
                                Duration = "PT$([System.TimeSpan]::Parse($testParameters.RepetitionDuration).TotalHours)H"
                                Interval = "PT$([System.TimeSpan]::Parse($testParameters.RepeatInterval).TotalMinutes)M"
                            }
                            CimClass   = @{
                                CimClassName = 'MSFT_TaskTimeTrigger'
                            }
                        }
                    )
                    Settings  = [pscustomobject] @{
                        Enabled           = $false
                        MultipleInstances = 'IgnoreNew'
                    }
                    Principal = [pscustomobject] @{
                        UserId = 'SYSTEM'
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Ensure | Should -Be 'Present'
            }
        }

        It 'Should return true from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeTrue
            }
        }
    }

    Context 'A scheduled task exists and is configured with the wrong interval, duration & random delay parameters' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable          = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                ScheduleType              = 'Once'
                RepeatInterval            = (New-TimeSpan -Minutes 20).ToString()
                RepetitionDuration        = (New-TimeSpan -Hours 9).ToString()
                RandomDelay               = (New-TimeSpan -Minutes 4).ToString()
                IdleWaitTimeout           = (New-TimeSpan -Minutes 5).ToString()
                IdleDuration              = (New-TimeSpan -Minutes 6).ToString()
                ExecutionTimeLimit        = (New-TimeSpan -Minutes 7).ToString()
                RestartInterval           = (New-TimeSpan -Minutes 8).ToString()
                TriggerExecutionTimeLimit = (New-TimeSpan -Minutes 9).ToString()
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName  = $testParameters.TaskName
                    TaskPath  = $testParameters.TaskPath
                    Actions   = @(
                        [pscustomobject] @{
                            Execute   = $testParameters.ActionExecutable
                            Arguments = $testParameters.Arguments
                        }
                    )
                    Triggers  = @(
                        [pscustomobject] @{
                            ExecutionTimeLimit = "PT$([System.TimeSpan]::Parse($testParameters.TriggerExecutionTimeLimit).TotalMinutes)M"
                            Repetition  = @{
                                Duration = "PT$([System.TimeSpan]::Parse($testParameters.RepetitionDuration).TotalHours + 1)H"
                                Interval = "PT$([System.TimeSpan]::Parse($testParameters.RepeatInterval).TotalMinutes + 1)M"
                            }
                            RandomDelay = "PT$([System.TimeSpan]::Parse($testParameters.RandomDelay).TotalMinutes + 1)M"
                            CimClass    = @{
                                CimClassName = 'MSFT_TaskTimeTrigger'
                            }
                        }
                    )
                    Settings  = [pscustomobject] @{
                        IdleSettings       = @{
                            WaitTimeout  = "PT$([System.TimeSpan]::Parse($testParameters.IdleWaitTimeout).TotalMinutes)M"
                            IdleDuration = "PT$([System.TimeSpan]::Parse($testParameters.IdleDuration).TotalMinutes)M"
                        }
                        ExecutionTimeLimit = "PT$([System.TimeSpan]::Parse($testParameters.ExecutionTimeLimit).TotalMinutes)M"
                        RestartInterval    = "PT$([System.TimeSpan]::Parse($testParameters.RestartInterval).TotalMinutes)M"
                        MultipleInstances  = 'IgnoreNew'
                    }
                    Principal = [pscustomobject] @{
                        UserId = 'SYSTEM'
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Ensure | Should -Be 'Present'
            }
        }

        It 'Should return false from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeFalse
            }
        }

        It 'Should update the scheduled task in the set method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters
            }

            Assert-MockCalled -CommandName Set-ScheduledTask -Exactly -Times 1 -Scope It
        }
    }

    Context 'A scheduled task exists and is configured with the wrong idle timeout & idle duration parameters' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable          = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                ScheduleType              = 'Once'
                RepeatInterval            = (New-TimeSpan -Minutes 20).ToString()
                RepetitionDuration        = (New-TimeSpan -Hours 9).ToString()
                RandomDelay               = (New-TimeSpan -Minutes 4).ToString()
                IdleWaitTimeout           = (New-TimeSpan -Minutes 5).ToString()
                IdleDuration              = (New-TimeSpan -Minutes 6).ToString()
                ExecutionTimeLimit        = (New-TimeSpan -Minutes 7).ToString()
                RestartInterval           = (New-TimeSpan -Minutes 8).ToString()
                TriggerExecutionTimeLimit = (New-TimeSpan -Minutes 9).ToString()
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName  = $testParameters.TaskName
                    TaskPath  = $testParameters.TaskPath
                    Actions   = @(
                        [pscustomobject] @{
                            Execute   = $testParameters.ActionExecutable
                            Arguments = $testParameters.Arguments
                        }
                    )
                    Triggers  = @(
                        [pscustomobject] @{
                            ExecutionTimeLimit = "PT$([System.TimeSpan]::Parse($testParameters.TriggerExecutionTimeLimit).TotalMinutes)M"
                            Repetition  = @{
                                Duration = "PT$([System.TimeSpan]::Parse($testParameters.RepetitionDuration).TotalHours)H"
                                Interval = "PT$([System.TimeSpan]::Parse($testParameters.RepeatInterval).TotalMinutes)M"
                            }
                            RandomDelay = "PT$([System.TimeSpan]::Parse($testParameters.RandomDelay).TotalMinutes)M"
                            CimClass    = @{
                                CimClassName = 'MSFT_TaskTimeTrigger'
                            }
                        }
                    )
                    Settings  = [pscustomobject] @{
                        IdleSettings       = @{
                            WaitTimeout  = "PT$([System.TimeSpan]::Parse($testParameters.IdleWaitTimeout).TotalMinutes + 1)M"
                            IdleDuration = "PT$([System.TimeSpan]::Parse($testParameters.IdleDuration).TotalMinutes + 1)M"
                        }
                        ExecutionTimeLimit = "PT$([System.TimeSpan]::Parse($testParameters.ExecutionTimeLimit).TotalMinutes)M"
                        RestartInterval    = "PT$([System.TimeSpan]::Parse($testParameters.RestartInterval).TotalMinutes)M"
                        MultipleInstances  = 'IgnoreNew'
                    }
                    Principal = [pscustomobject] @{
                        UserId = 'SYSTEM'
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Ensure | Should -Be 'Present'
            }
        }

        It 'Should return false from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeFalse
            }
        }

        It 'Should update the scheduled task in the set method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters
            }

            Assert-MockCalled -CommandName Set-ScheduledTask -Exactly -Times 1 -Scope It
        }
    }

    Context 'A scheduled task exists and is configured with the wrong duration parameter for an indefinite trigger' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                ScheduleType       = 'Once'
                RepeatInterval     = (New-TimeSpan -Minutes 20).ToString()
                RepetitionDuration = 'Indefinitely'
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName  = $testParameters.TaskName
                    TaskPath  = $testParameters.TaskPath
                    Actions   = @(
                        [pscustomobject] @{
                            Execute   = $testParameters.ActionExecutable
                            Arguments = $testParameters.Arguments
                        }
                    )
                    Triggers  = @(
                        [pscustomobject] @{
                            Repetition = @{
                                Duration = 'PT4H'
                                Interval = "PT$([System.TimeSpan]::Parse($testParameters.RepeatInterval).TotalMinutes)M"
                            }
                            CimClass   = @{
                                CimClassName = 'MSFT_TaskTimeTrigger'
                            }
                        }
                    )
                    Settings  = [pscustomobject] @{
                        Enabled           = $true
                        MultipleInstances = 'IgnoreNew'
                    }
                    Principal = [pscustomobject] @{
                        UserId = 'SYSTEM'
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Ensure | Should -Be 'Present'
            }
        }

        It 'Should return false from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeFalse
            }
        }

        It 'Should update the scheduled task in the set method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters
            }

            Assert-MockCalled -CommandName Set-ScheduledTask -Exactly -Times 1 -Scope It
        }
    }

    Context 'A scheduled task exists and is configured with indefinite repetition duration for a trigger but should be fixed' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                ScheduleType       = 'Once'
                RepeatInterval     = (New-TimeSpan -Minutes 20).ToString()
                RepetitionDuration = (New-TimeSpan -Hours 9).ToString()
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName  = $testParameters.TaskName
                    TaskPath  = $testParameters.TaskPath
                    Actions   = @(
                        [pscustomobject] @{
                            Execute   = $testParameters.ActionExecutable
                            Arguments = $testParameters.Arguments
                        }
                    )
                    Triggers  = @(
                        [pscustomobject] @{
                            Repetition = @{
                                Duration = ''
                                Interval = "PT$([System.TimeSpan]::Parse($testParameters.RepeatInterval).TotalMinutes)M"
                            }
                            CimClass   = @{
                                CimClassName = 'MSFT_TaskTimeTrigger'
                            }
                        }
                    )
                    Settings  = [pscustomobject] @{
                        Enabled           = $true
                        MultipleInstances = 'IgnoreNew'
                    }
                    Principal = [pscustomobject] @{
                        UserId = 'SYSTEM'
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Ensure | Should -Be 'Present'
            }
        }

        It 'Should return false from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeFalse
            }
        }

        It 'Should update the scheduled task in the set method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters
            }

            Assert-MockCalled -CommandName Set-ScheduledTask -Exactly -Times 1 -Scope It
        }
    }

    Context 'A scheduled task exists and is configured with correctly with an indefinite duration trigger' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                ScheduleType       = 'Once'
                RepeatInterval     = (New-TimeSpan -Minutes 20).ToString()
                RepetitionDuration = 'Indefinitely'
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName  = $testParameters.TaskName
                    TaskPath  = $testParameters.TaskPath
                    Actions   = @(
                        [pscustomobject] @{
                            Execute   = $testParameters.ActionExecutable
                            Arguments = $testParameters.Arguments
                        }
                    )
                    Triggers  = @(
                        [pscustomobject] @{
                            Repetition = @{
                                Duration = ''
                                Interval = "PT$([System.TimeSpan]::Parse($testParameters.RepeatInterval).TotalMinutes)M"
                            }
                            CimClass   = @{
                                CimClassName = 'MSFT_TaskTimeTrigger'
                            }
                        }
                    )
                    Settings  = [pscustomobject] @{
                        Enabled           = $true
                        MultipleInstances = 'IgnoreNew'
                    }
                    Principal = [pscustomobject] @{
                        UserId = 'SYSTEM'
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Ensure | Should -Be 'Present'
            }
        }

        It 'Should return true from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeTrue
            }
        }
    }

    Context 'When a built-in scheduled task exists and is enabled, but it should be disabled and the trigger type is not recognized' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                Enable = $false
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName = $testParameters.TaskName
                    TaskPath = $testParameters.TaskPath
                    Actions  = [pscustomobject] @{
                        Execute = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    }
                    Triggers = [pscustomobject] @{
                        Repetition = @{
                            Duration = 'PT15M'
                            Interval = 'PT15M'
                        }
                        CimClass   = @{
                            CimClassName = 'MSFT_TaskUnknownFutureTrigger'
                        }
                    }
                    Settings = [pscustomobject] @{
                        Enabled           = $true
                        MultipleInstances = 'StopExisting'
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Enable | Should -BeTrue
                $result.Ensure | Should -Be 'Present'
                $result.ScheduleType | Should -BeNullOrEmpty
            }
        }

        It 'Should return false from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeFalse
            }
        }

        It 'Should disable the scheduled task in the set method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters
            }

            if ($PSVersionTable.PSEdition -gt [System.Version]'5.0.0.0')
            {
                Assert-MockCalled Disable-ScheduledTask -Exactly -Times 1
            }
            else
            {
                Assert-MockCalled Register-ScheduledTask -Exactly -Times 1
            }
        }
    }

    Context 'When a scheduled task with an OnEvent scheduletype is in desired state' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ScheduleType      = 'OnEvent'
                ActionExecutable  = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                EventSubscription = '<QueryList><Query Id="0" Path="System"><Select Path="System">*[System[Provider[@Name=''User32''] and EventID=1600]]</Select></Query></QueryList>'
                EventValueQueries = [Microsoft.Management.Infrastructure.CimInstance[]] (
                    ConvertTo-CimInstance -Hashtable @{
                        Service          = "Event/EventData/Data[@Name='param1']"
                        DependsOnService = "Event/EventData/Data[@Name='param2']"
                        ErrorCode        = "Event/EventData/Data[@Name='param3']"
                    }
                )
                Delay             = '00:01:00'
                Enable            = $true
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName = $testParameters.TaskName
                    TaskPath = $testParameters.TaskPath
                    Actions  = [pscustomobject] @{
                        Execute = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    }
                    Triggers = [pscustomobject] @{
                        Delay        = 'PT1M'
                        Subscription = $testParameters.EventSubscription
                        ValueQueries = @(
                            $testParameters.EventValueQueries | ForEach-Object {
                                New-CimInstance -ClassName MSFT_TaskNamedValue `
                                    -Namespace Root/Microsoft/Windows/TaskScheduler:MSFT_TaskNamedValue `
                                    -Property @{
                                    Name  = $_.Key
                                    Value = $_.Value
                                } `
                                    -ClientOnly
                            }
                        )
                        CimClass     = @{
                            CimClassName = 'MSFT_TaskEventTrigger'
                        }
                    }
                    Settings = [pscustomobject] @{
                        Enabled           = $true
                        MultipleInstances = 'StopExisting'
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Enable | Should -BeTrue
                $result.Ensure | Should -Be 'Present'
                $result.ScheduleType | Should -Be $testParameters.ScheduleType
                $result.EventSubscription | Should -Be $testParameters.EventSubscription
                Test-DscParameterState -CurrentValues $result.EventValueQueries -DesiredValues $testParameters.EventValueQueries | Should -BeTrue
                $result.Delay | Should -Be $testParameters.Delay
            }
        }

        It 'Should return true from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeTrue
            }
        }
    }

    Context 'When a scheduled task with an OnEvent scheduletype needs to be created' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ScheduleType      = 'OnEvent'
                ActionExecutable  = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                EventSubscription = '<QueryList><Query Id="0" Path="System"><Select Path="System">*[System[Provider[@Name=''User32''] and EventID=1600]]</Select></Query></QueryList>'
                EventValueQueries = [Microsoft.Management.Infrastructure.CimInstance[]] (
                    ConvertTo-CimInstance -Hashtable @{
                        Service          = "Event/EventData/Data[@Name='param1']"
                        DependsOnService = "Event/EventData/Data[@Name='param2']"
                        ErrorCode        = "Event/EventData/Data[@Name='param3']"
                    }
                )
                Delay             = '00:01:00'
                Enable            = $true
            }

            Mock -CommandName Get-ScheduledTask
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Ensure | Should -Be 'Absent'
            }
        }

        It 'Should return false from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeFalse
            }
        }

        It 'Should register the new scheduled task' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters
            }

            Assert-MockCalled Register-ScheduledTask -Exactly -Times 1 -Scope It
        }
    }

    Context 'When a scheduled task with an OnEvent scheduletype needs to be updated' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ScheduleType      = 'OnEvent'
                ActionExecutable  = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                EventSubscription = '<QueryList><Query Id="0" Path="System"><Select Path="System">*[System[Provider[@Name=''User32''] and EventID=1600]]</Select></Query></QueryList>'
                EventValueQueries = [Microsoft.Management.Infrastructure.CimInstance[]] (
                    ConvertTo-CimInstance -Hashtable @{
                        Service          = "Event/EventData/Data[@Name='param1']"
                        DependsOnService = "Event/EventData/Data[@Name='param2']"
                        ErrorCode        = "Event/EventData/Data[@Name='param3']"
                    }
                )
                Delay             = '00:05:00'
                Enable            = $true
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName = $testParameters.TaskName
                    TaskPath = $testParameters.TaskPath
                    Actions  = [pscustomobject] @{
                        Execute = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    }
                    Triggers = [pscustomobject] @{
                        Delay        = 'PT1M'
                        Subscription = '<QueryList><Query Id="0" Path="System"><Select Path="System">*[System[Provider[@Name=''User32''] and EventID=1601]]</Select></Query></QueryList>'
                        ValueQueries = @(
                            $testParameters.EventValueQueries | Select-Object -SkipLast 1 | ForEach-Object {
                                New-CimInstance -ClassName MSFT_TaskNamedValue `
                                    -Namespace Root/Microsoft/Windows/TaskScheduler:MSFT_TaskNamedValue `
                                    -Property @{
                                    Name  = $_.Key
                                    Value = $_.Value
                                } `
                                    -ClientOnly
                            }
                        )
                        CimClass     = @{
                            CimClassName = 'MSFT_TaskEventTrigger'
                        }
                    }
                    Settings = [pscustomobject] @{
                        Enabled           = $true
                        MultipleInstances = 'StopExisting'
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Enable | Should -BeTrue
                $result.Ensure | Should -Be 'Present'
                $result.ScheduleType | Should -Be $testParameters.ScheduleType
            }
        }

        It 'Should return false from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeFalse
            }
        }

        It 'Should not call Register-ScheduledTask on an already registered task' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters
            }

            Assert-MockCalled Register-ScheduledTask -Exactly -Times 0 -Scope It
        }

        It 'Should call Set-ScheduledTask to update the scheduled task with the new values' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters
            }

            Assert-MockCalled Set-ScheduledTask -Exactly -Times 1 -Scope It
        }
    }

    Context 'When a scheduled task with an OnEvent scheduletype is used on combination with unsupported parameters for this scheduletype' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ScheduleType      = 'OnEvent'
                ActionExecutable  = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                EventSubscription = '<QueryList><Query Id="0" Path="System"><Select Path="System">*[System[Provider[@Name=''User32''] and EventID=1600]]</Select></Query></QueryList>'
                RandomDelay       = '01:00:00'
                Delay             = '00:01:00'
                Enable            = $true
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName = $testParameters.TaskName
                    TaskPath = $testParameters.TaskPath
                    Actions  = [pscustomobject] @{
                        Execute = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    }
                    Triggers = [pscustomobject] @{
                        Delay        = 'PT1M'
                        Subscription = $testParameters.EventSubscription
                        CimClass     = @{
                            CimClassName = 'MSFT_TaskEventTrigger'
                        }
                    }
                    Settings = [pscustomobject] @{
                        Enabled           = $true
                        MultipleInstances = 'StopExisting'
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Enable | Should -BeTrue
                $result.Ensure | Should -Be 'Present'
                $result.ScheduleType | Should -Be $testParameters.ScheduleType
                $result.RandomDelay | Should -Be '00:00:00'
            }
        }

        It 'Should return true from the test method - ignoring the RandomDelay parameter' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeTrue
            }
        }


        It 'When an EventSubscription cannot be parsed as valid XML an error is generated when changing the task' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidArgumentRecord -Message $LocalizedData.OnEventSubscriptionError -ArgumentName 'EventSubscription'

                $testParameters.EventSubscription = 'InvalidXML'
                { Set-TargetResource @testParameters } | Should -Throw $errorRecord
            }
        }
    }

    Context 'When a scheduled task is created using a Built In Service Account' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable    = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                ScheduleType        = 'Once'
                RepeatInterval      = (New-TimeSpan -Minutes 15).ToString()
                RepetitionDuration  = (New-TimeSpan -Hours 8).ToString()
                BuiltInAccount      = 'NETWORK SERVICE'
                ExecuteAsCredential = [pscredential]::new('DEMO\WrongUser', (ConvertTo-SecureString 'ExamplePassword' -AsPlainText -Force))
            }
        }

        It 'Should Disregard ExecuteAsCredential and Set User to the BuiltInAccount' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters
            }

            Assert-MockCalled -CommandName Register-ScheduledTask -Exactly -Times 1 -Scope It -ParameterFilter {
                $User -ieq ('NT AUTHORITY\' + $testParameters['BuiltInAccount'])
            }
        }


        It 'Should Disregard User and Set User to the BuiltInAccount' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParameters.Add('User', 'WrongUser')

                Set-TargetResource @testParameters
                Assert-MockCalled -CommandName Register-ScheduledTask -Times 1 -Scope It -ParameterFilter {
                    $User -ieq ('NT AUTHORITY\' + $testParameters['BuiltInAccount'])
                }
            }
        }


        It 'Should overwrite LogonType to "ServiceAccount"' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParameters.Add('LogonType', 'Password')

                Set-TargetResource @testParameters
                Assert-MockCalled -CommandName Register-ScheduledTask -Times 1 -Scope It -ParameterFilter {
                    $Inputobject.Principal.LogonType -ieq 'ServiceAccount'
                }
            }
        }

        Context 'When LogonType parameter different' {
            BeforeAll {
                Mock -CommandName Get-ScheduledTask -MockWith {
                    @{
                        Description     = '+'
                        TaskName        = $testParameters.TaskName
                        TaskPath        = $testParameters.TaskPath
                        Actions         = @(
                            [pscustomobject] @{
                                Execute = $testParameters.ActionExecutable
                            }
                        )
                        ActionArguments = '-File "C:\something\right.ps1"'
                        Triggers        = @(
                            [pscustomobject] @{
                                Repetition = @{
                                    Duration = "PT$([System.TimeSpan]::Parse($testParameters.RepetitionDuration).TotalHours)H"
                                    Interval = "PT$([System.TimeSpan]::Parse($testParameters.RepeatInterval).TotalMinutes)M"
                                }
                                CimClass   = @{
                                    CimClassName = 'MSFT_TaskTimeTrigger'
                                }
                            }
                        )
                        Settings        = [pscustomobject] @{
                            Enabled           = $true
                            MultipleInstances = 'IgnoreNew'
                        }
                        Principal       = [pscustomobject] @{
                            UserId    = $testParameters.BuiltInAccount
                            LogonType = 'ServiceAccount'
                        }
                    }
                }
            }


            It 'Should return true when BuiltInAccount set' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters.LogonType = 'Password'
                    Test-TargetResource @testParameters | Should -BeTrue
                }
            }
        }
    }

    Context 'When a scheduled task is created using a Group Managed Service Account' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable    = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                ScheduleType        = 'Once'
                RepeatInterval      = (New-TimeSpan -Minutes 15).ToString()
                RepetitionDuration  = (New-TimeSpan -Hours 8).ToString()
                ExecuteAsGMSA       = 'DOMAIN\gMSA$'
                BuiltInAccount      = 'NETWORK SERVICE'
                ExecuteAsCredential = [pscredential]::new('DEMO\RightUser', (ConvertTo-SecureString 'ExamplePassword' -AsPlainText -Force))
            }
        }

        It 'Should throw expected exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidArgumentRecord -Message $LocalizedData.gMSAandCredentialError -ArgumentName 'ExecuteAsGMSA'

                { Set-TargetResource @testParameters -ErrorVariable duplicateCredential } | Should -Throw $errorRecord
                $testParameters.Remove('ExecuteAsCredential')
                { Set-TargetResource @testParameters -ErrorVariable duplicateCredential } | Should -Throw $errorRecord
            }
        }


        It 'Should call Register-ScheduledTask with the name of the Group Managed Service Account' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParameters.Remove('BuiltInAccount')
                Set-TargetResource @testParameters
            }

            Assert-MockCalled -CommandName Register-ScheduledTask -Exactly -Times 1 -Scope It -ParameterFilter {
                $User -eq $null -and $Inputobject.Principal.UserId -eq $testParameters.ExecuteAsGMSA
            }
        }

        It 'Should set the LogonType to Password when a Group Managed Service Account is used' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters
            }

            Assert-MockCalled -CommandName Register-ScheduledTask -Exactly -Times 1 -Scope It -ParameterFilter {
                $Inputobject.Principal.Logontype -eq 'Password'
            }
        }

        Context 'When checking the gMSA user format' {
            BeforeAll {
                Mock -CommandName Get-ScheduledTask -MockWith {
                    @{
                        TaskName  = $testParameters.TaskName
                        TaskPath  = $testParameters.TaskPath
                        Actions   = @(
                            [pscustomobject] @{
                                Execute = $testParameters.ActionExecutable
                            }
                        )
                        Triggers  = @(
                            [pscustomobject] @{
                                Repetition = @{
                                    Duration = "PT$([System.TimeSpan]::Parse($testParameters.RepetitionDuration).TotalHours)H"
                                    Interval = "PT$([System.TimeSpan]::Parse($testParameters.RepeatInterval).TotalMinutes)M"
                                }
                                CimClass   = @{
                                    CimClassName = 'MSFT_TaskTimeTrigger'
                                }
                            }
                        )
                        Settings  = [pscustomobject] @{
                            Enabled           = $true
                            MultipleInstances = 'IgnoreNew'
                        }
                        Principal = [pscustomobject] @{
                            UserId = 'gMSA$'
                        }
                    }
                }
            }

            It 'Should return true if the task is in desired state and given gMSA user in DOMAIN\User$ format' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    Test-TargetResource @testParameters | Should -BeTrue
                }
            }


            It 'Should return true if the task is in desired state and given gMSA user in UPN format' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters.ExecuteAsGMSA = 'gMSA$@domain.fqdn'
                    Test-TargetResource @testParameters | Should -BeTrue
                }
            }
        }
    }

    Context 'When a scheduled task Group Managed Service Account is changed' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                ScheduleType       = 'Once'
                RepeatInterval     = (New-TimeSpan -Minutes 15).ToString()
                RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
                ExecuteAsGMSA      = 'DOMAIN\gMSA$'
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName  = $testParameters.TaskName
                    TaskPath  = $testParameters.TaskPath
                    Actions   = @(
                        [pscustomobject] @{
                            Execute = $testParameters.ActionExecutable
                        }
                    )
                    Triggers  = @(
                        [pscustomobject] @{
                            Repetition = @{
                                Duration = "PT$([System.TimeSpan]::Parse($testParameters.RepetitionDuration).TotalHours)H"
                                Interval = "PT$([System.TimeSpan]::Parse($testParameters.RepeatInterval).TotalMinutes)M"
                            }
                            CimClass   = @{
                                CimClassName = 'MSFT_TaskTimeTrigger'
                            }
                        }
                    )
                    Settings  = [pscustomobject] @{
                        Enabled           = $true
                        MultipleInstances = 'IgnoreNew'
                    }
                    Principal = [pscustomobject] @{
                        UserId = 'update_gMSA$'
                    }
                }
            }
        }

        It 'Should return false on Test-TargetResource if the task is not in desired state and given gMSA user in DOMAIN\User$ format' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeFalse
            }
        }

        It 'Should call Set-ScheduledTask using the new Group Managed Service Account' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters
            }

            Assert-MockCalled -CommandName Set-ScheduledTask -Exactly -Times 1 -Scope It -ParameterFilter {
                $Inputobject.Principal.UserId -eq $testParameters.ExecuteAsGMSA
            }
        }

        It 'Should set the LogonType to Password when a Group Managed Service Account is used' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters
            }

            Assert-MockCalled -CommandName Set-ScheduledTask -Exactly -Times 1 -Scope It -ParameterFilter {
                $Inputobject.Principal.Logontype -eq 'Password'
            }
        }
    }

    Context 'When a scheduled task is created and synchronize across time zone is disabled' {
        BeforeAll {
            $startTimeString = '2018-10-01T01:00:00'
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable          = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                StartTime                 = Get-Date -Date $startTimeString
                SynchronizeAcrossTimeZone = $false
                ScheduleType              = 'Once'
            }

            $startTimeStringWithOffset = '2018-10-01T01:00:00' + (Get-Date -Format 'zzz')

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName = $testParameters.TaskName
                    TaskPath = $testParameters.TaskPath
                    Actions  = @(
                        [pscustomobject] @{
                            Execute = $testParameters.ActionExecutable
                        }
                    )
                    Triggers = @(
                        [pscustomobject] @{
                            StartBoundary = $startTimeString
                            CimClass      = @{
                                CimClassName = 'MSFT_TaskTimeTrigger'
                            }
                        }
                    )
                    Settings = [pscustomobject] @{
                        Enabled           = $true
                        MultipleInstances = 'IgnoreNew'
                    }
                }
            }
        }

        It 'Should return the start time in DateTime format and SynchronizeAcrossTimeZone with value false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.StartTime | Should -Be (Get-Date -Date $testParameters.StartTime)
                $result.SynchronizeAcrossTimeZone | Should -BeFalse
            }
        }

        It 'Should return true given that startTime is set correctly' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeTrue
            }
        }

        Context 'When task is configured across time zone' {
            BeforeAll {
                Mock -CommandName Get-ScheduledTask -MockWith {
                    @{
                        TaskName = $testParameters.TaskName
                        TaskPath = $testParameters.TaskPath
                        Actions  = @(
                            [pscustomobject] @{
                                Execute = $testParameters.ActionExecutable
                            }
                        )
                        Triggers = @(
                            [pscustomobject] @{
                                StartBoundary = $startTimeStringWithOffset
                                CimClass      = @{
                                    CimClassName = 'MSFT_TaskTimeTrigger'
                                }
                            }
                        )
                        Settings = [pscustomobject] @{
                            Enabled           = $true
                            MultipleInstances = 'IgnoreNew'
                        }
                    }
                }
            }

            It 'Should return false given that the task is configured with synchronize across time zone' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    Test-TargetResource @testParameters | Should -BeFalse
                }
            }


            It "Should set task trigger StartBoundary to $startTimeString" {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    Set-TargetResource @testParameters
                }

                Assert-MockCalled -CommandName Set-ScheduledTask -ParameterFilter {
                    $InputObject.Triggers[0].StartBoundary -eq $startTimeString
                }
            }
        }
    }

    Context 'When a scheduled task is created and synchronize across time zone is enabled' {
        BeforeDiscovery {
            $startTimeStringWithOffset = '2018-10-01T01:00:00' + (Get-Date -Format 'zzz')
        }

        BeforeAll {
            $startTimeString = '2018-10-01T01:00:00'
            $startTimeStringWithOffset = '2018-10-01T01:00:00' + (Get-Date -Format 'zzz')
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable          = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                StartTime                 = Get-Date -Date $startTimeString
                SynchronizeAcrossTimeZone = $true
                ScheduleType              = 'Once'
            }

            InModuleScope -Parameters @{
                startTimeStringWithOffset = $startTimeStringWithOffset
            } -ScriptBlock {
                $script:startTimeStringWithOffset = $startTimeStringWithOffset
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName = $testParameters.TaskName
                    TaskPath = $testParameters.TaskPath
                    Actions  = @(
                        [pscustomobject] @{
                            Execute = $testParameters.ActionExecutable
                        }
                    )
                    Triggers = @(
                        [pscustomobject] @{
                            StartBoundary = $startTimeStringWithOffset
                            CimClass      = @{
                                CimClassName = 'MSFT_TaskTimeTrigger'
                            }
                        }
                    )
                    Settings = [pscustomobject] @{
                        Enabled           = $true
                        MultipleInstances = 'IgnoreNew'
                    }
                }
            }
        }

        It 'Should return the start time in DateTime format and SynchronizeAcrossTimeZone with value true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.StartTime | Should -Be (Get-Date -Date $startTimeStringWithOffset)
                $result.SynchronizeAcrossTimeZone | Should -BeTrue
            }
        }

        It 'Should return true given that startTime is set correctly' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeTrue
            }
        }

        Context 'When configured with synchronize across time zone disabled' {
            BeforeAll {
                Mock -CommandName Get-ScheduledTask -MockWith {
                    @{
                        TaskName = $testParameters.TaskName
                        TaskPath = $testParameters.TaskPath
                        Actions  = @(
                            [pscustomobject] @{
                                Execute = $testParameters.ActionExecutable
                            }
                        )
                        Triggers = @(
                            [pscustomobject] @{
                                StartBoundary = $startTimeString
                                CimClass      = @{
                                    CimClassName = 'MSFT_TaskTimeTrigger'
                                }
                            }
                        )
                        Settings = [pscustomobject] @{
                            Enabled           = $true
                            MultipleInstances = 'IgnoreNew'
                        }
                    }
                }
            }

            It 'Should return false given that the task is configured with synchronize across time zone disabled' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    Test-TargetResource @testParameters | Should -BeFalse
                }
            }

            It "Should set task trigger StartBoundary to $startTimeStringWithOffset" {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    Set-TargetResource @testParameters
                }

                Assert-MockCalled -CommandName Set-ScheduledTask -ParameterFilter {
                    $InputObject.Triggers[0].StartBoundary -eq $startTimeStringWithOffset
                }
            }
        }
    }

    Context 'When a scheduled task is configured to SynchronizeAcrossTimeZone and the ScheduleType is not Once, Daily or Weekly' {
        BeforeAll {
            $startTimeString = '2018-10-01T01:00:00'
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable          = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                StartTime                 = Get-Date -Date $startTimeString
                SynchronizeAcrossTimeZone = $true
                ScheduleType              = 'AtLogon'
            }
        }

        It 'Should throw when Set-TargetResource is called and SynchronizeAcrossTimeZone is used in combination with an unsupported trigger type' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidArgumentRecord -Message $LocalizedData.SynchronizeAcrossTimeZoneInvalidScheduleType -ArgumentName 'SynchronizeAcrossTimeZone'

                { Set-TargetResource @testParameters } | Should -Throw $errorRecord
            }
        }
    }

    Context 'When a scheduled task is configured with the ScheduleType AtLogon and is in desired state' {
        BeforeAll {
            $startTimeString = '2018-10-01T01:00:00'
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable  = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                StartTime         = Get-Date -Date $startTimeString
                ScheduleType      = 'AtLogon'
                User              = 'MockedUser'
                Delay             = '00:01:00'
                Enable            = $true
                MultipleInstances = 'StopExisting'
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName = $testParameters.TaskName
                    TaskPath = $testParameters.TaskPath
                    Actions  = @(
                        [pscustomobject] @{
                            Execute = $testParameters.ActionExecutable
                        }
                    )
                    Triggers = @(
                        [pscustomobject] @{
                            UserId        = $testParameters.User
                            Delay         = 'PT1M'
                            StartBoundary = $startTimeString
                            CimClass      = @{
                                CimClassName = 'MSFT_TaskLogonTrigger'
                            }
                        }
                    )
                    Settings = [pscustomobject] @{
                        Enabled           = $testParameters.Enable
                        MultipleInstances = $testParameters.MultipleInstances
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Enable | Should -Be $testParameters.Enable
                $result.Ensure | Should -Be 'Present'
                $result.StartTime | Should -Be (Get-Date -Date $testParameters.StartTime)
                $result.ScheduleType | Should -Be $testParameters.ScheduleType
                $result.User | Should -Be $testParameters.User
                $result.Delay | Should -Be $testParameters.Delay
            }
        }

        It 'Should return true from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeTrue
            }
        }
    }

    Context 'When scheduling a task to trigger at user logon' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ScheduleType     = 'AtLogon'
                User             = 'MockedUser'
                ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                LogonType        = 'Password'
            }

            Mock -CommandName New-ScheduledTaskTrigger -MockWith {
                $cimInstance = New-CIMInstance -ClassName 'MSFT_TaskLogonTrigger' -Namespace 'root\Microsoft\Windows\TaskScheduler' -Property @{
                    # Fill the CIM instance with the properties we expect to be used by the resource.
                    UserId = $testParameters.User
                    Delay  = ''
                } -ClientOnly

                <#
                            Must add the TypeName property to the CIM instance for the array .PSObject.PSTypeNames
                            to have the correct name for it to be recognized by the New-ScheduledTask command.
                        #>
                $cimInstance | Add-Member -TypeName 'Microsoft.Management.Infrastructure.CimInstance#MSFT_TaskTrigger'

                return $cimInstance
            }

            Mock -CommandName New-ScheduledTask -MockWith {
                <#
                            Mock an object with properties that are used by the resource
                            for the newly created scheduled task.
                        #>
                return [PSCustomObject] @{
                    Triggers = @(
                        @{
                            StartBoundary = '2018-09-27T18:45:08+02:00'
                        }
                    )
                }
            }
        }

        It "Should correctly configure the task with 'AtLogon' ScheduleType and the specified user" {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters
            }

            Assert-MockCalled -CommandName New-ScheduledTaskTrigger -ParameterFilter {
                $AtLogon -eq $true -and $User -eq $testParameters.User
            } -Exactly -Times 1 -Scope It

            Assert-MockCalled -CommandName New-ScheduledTask -Exactly -Times 1 -Scope It
        }
    }

    Context 'When a scheduled task is configured with the ScheduleType AtStartup and is in desired state' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                ScheduleType     = 'AtStartup'
                Delay            = '00:01:00'
                Enable           = $true
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName = $testParameters.TaskName
                    TaskPath = $testParameters.TaskPath
                    Actions  = @(
                        [pscustomobject] @{
                            Execute = $testParameters.ActionExecutable
                        }
                    )
                    Triggers = @(
                        [pscustomobject] @{
                            Delay         = 'PT1M'
                            StartBoundary = ''
                            CimClass      = @{
                                CimClassName = 'MSFT_TaskBootTrigger'
                            }
                        }
                    )
                    Settings = [pscustomobject] @{
                        Enabled           = $testParameters.Enable
                        MultipleInstances = 'StopExisting'
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Enable | Should -Be $testParameters.Enable
                $result.Ensure | Should -Be 'Present'
                $result.ScheduleType | Should -Be $testParameters.ScheduleType
                $result.Delay | Should -Be $testParameters.Delay
            }
        }

        It 'Should return true from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeTrue
            }
        }
    }

    Context 'When a scheduled task is configured with the ScheduleType AtStartup and needs to be created' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                ScheduleType     = 'AtStartup'
                Delay            = '00:01:00'
                Enable           = $true
            }

            Mock -CommandName Get-ScheduledTask
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Ensure | Should -Be 'Absent'
            }
        }

        It 'Should return false from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeFalse
            }
        }

        It 'Should register the new scheduled task' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters
            }

            Assert-MockCalled Register-ScheduledTask -Exactly -Times 1 -Scope It
        }
    }

    Context 'When a scheduled task is configured with the ScheduleType OnIdle and is in desired state' {
        BeforeAll {
            $startTimeString = '2018-10-01T01:00:00'
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable  = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                StartTime         = Get-Date -Date $startTimeString
                ScheduleType      = 'OnIdle'
                Enable            = $true
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName = $testParameters.TaskName
                    TaskPath = $testParameters.TaskPath
                    Actions  = @(
                        [pscustomobject] @{
                            Execute = $testParameters.ActionExecutable
                        }
                    )
                    Triggers = @(
                        [pscustomobject] @{
                            StartBoundary = $startTimeString
                            CimClass      = @{
                                CimClassName = 'MSFT_TaskIdleTrigger'
                            }
                        }
                    )
                    Settings = [pscustomobject] @{
                        Enabled           = $testParameters.Enable
                        MultipleInstances = 'StopExisting'
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Enable | Should -Be $testParameters.Enable
                $result.Ensure | Should -Be 'Present'
                $result.StartTime | Should -Be (Get-Date -Date $testParameters.StartTime)
                $result.ScheduleType | Should -Be $testParameters.ScheduleType
            }
        }

        It 'Should return true from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeTrue
            }
        }
    }

    Context 'When a scheduled task is configured with the ScheduleType OnIdle and needs to be created' {
        BeforeAll {
            $startTimeString = '2018-10-01T01:00:00'
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable  = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                StartTime         = Get-Date -Date $startTimeString
                ScheduleType      = 'OnIdle'
                Enable            = $true
            }

            Mock -CommandName Get-ScheduledTask
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Ensure | Should -Be 'Absent'
            }
        }

        It 'Should return false from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeFalse
            }
        }

        It 'Should register the new scheduled task' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters
            }

            Assert-MockCalled Register-ScheduledTask -Exactly -Times 1 -Scope It
        }
    }

    Context 'When a scheduled task with an OnIdle scheduletype is used on combination with unsupported parameters for this scheduletype' {
        BeforeAll {
            $testParameters = $getTargetResourceParameters + @{
                ScheduleType      = 'OnIdle'
                ActionExecutable  = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                RandomDelay       = '01:00:00'
                Delay             = '00:01:00'
                Enable            = $true
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName = $testParameters.TaskName
                    TaskPath = $testParameters.TaskPath
                    Actions  = [pscustomobject] @{
                        Execute = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    }
                    Triggers = [pscustomobject] @{
                        CimClass     = @{
                            CimClassName = 'MSFT_TaskIdleTrigger'
                        }
                    }
                    Settings = [pscustomobject] @{
                        Enabled           = $true
                        MultipleInstances = 'StopExisting'
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Enable | Should -BeTrue
                $result.Ensure | Should -Be 'Present'
                $result.ScheduleType | Should -Be $testParameters.ScheduleType
            }
        }

        It 'Should return true from the test method - ignoring the RandomDelay and Delay parameters' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeTrue
            }
        }
    }

    Context 'When a scheduled task is configured with the ScheduleType AtCreation and is in desired state' {
        BeforeAll {
            $startTimeString = '2018-10-01T01:00:00'
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable  = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                StartTime         = Get-Date -Date $startTimeString
                ScheduleType      = 'AtCreation'
                Delay             = '00:01:00'
                Enable            = $true
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName = $testParameters.TaskName
                    TaskPath = $testParameters.TaskPath
                    Actions  = @(
                        [pscustomobject] @{
                            Execute = $testParameters.ActionExecutable
                        }
                    )
                    Triggers = @(
                        [pscustomobject] @{
                            Delay        = 'PT1M'
                            StartBoundary = $startTimeString
                            CimClass      = @{
                                CimClassName = 'MSFT_TaskRegistrationTrigger'
                            }
                        }
                    )
                    Settings = [pscustomobject] @{
                        Enabled           = $testParameters.Enable
                        MultipleInstances = 'StopExisting'
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Enable | Should -Be $testParameters.Enable
                $result.Ensure | Should -Be 'Present'
                $result.StartTime | Should -Be (Get-Date -Date $testParameters.StartTime)
                $result.ScheduleType | Should -Be $testParameters.ScheduleType
                $result.Delay | Should -Be $testParameters.Delay
            }
        }

        It 'Should return true from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeTrue
            }
        }
    }

    Context 'When a scheduled task is configured with the ScheduleType AtCreation and needs to be created' {
        BeforeAll {
            $startTimeString = '2018-10-01T01:00:00'
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable  = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                StartTime         = Get-Date -Date $startTimeString
                ScheduleType      = 'AtCreation'
                Delay             = '00:01:00'
                Enable            = $true
            }

            Mock -CommandName Get-ScheduledTask
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Ensure | Should -Be 'Absent'
            }
        }

        It 'Should return false from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeFalse
            }
        }

        It 'Should register the new scheduled task' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters
            }

            Assert-MockCalled Register-ScheduledTask -Exactly -Times 1 -Scope It
        }
    }

    Context 'When a scheduled task is configured with the ScheduleType OnSessionState and is in desired state' {
        BeforeAll {
            $startTimeString = '2018-10-01T01:00:00'
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable  = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                StartTime         = Get-Date -Date $startTimeString
                ScheduleType      = 'OnSessionState'
                StateChange       = 'OnConnectionFromLocalComputer'
                User              = 'MockedUser'
                Delay             = '00:01:00'
                Enable            = $true
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName = $testParameters.TaskName
                    TaskPath = $testParameters.TaskPath
                    Actions  = @(
                        [pscustomobject] @{
                            Execute = $testParameters.ActionExecutable
                        }
                    )
                    Triggers = @(
                        [pscustomobject] @{
                            Delay         = 'PT1M'
                            StateChange   = [ScheduledTask.StateChange]$testParameters.StateChange
                            UserId        = $testParameters.User
                            StartBoundary = $startTimeString
                            CimClass      = @{
                                CimClassName = 'MSFT_TaskSessionStateChangeTrigger'
                            }
                        }
                    )
                    Settings = [pscustomobject] @{
                        Enabled           = $testParameters.Enable
                        MultipleInstances = 'StopExisting'
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Enable | Should -Be $testParameters.Enable
                $result.Ensure | Should -Be 'Present'
                $result.StartTime | Should -Be (Get-Date -Date $testParameters.StartTime)
                $result.ScheduleType | Should -Be $testParameters.ScheduleType
                $result.User | Should -Be $testParameters.User
                $result.StateChange | Should -Be $testParameters.StateChange
                $result.Delay | Should -Be $testParameters.Delay
            }
        }

        It 'Should return true from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeTrue
            }
        }
    }

    Context 'When a scheduled task is configured with the ScheduleType OnSessionState and needs to be created' {
        BeforeAll {
            $startTimeString = '2018-10-01T01:00:00'
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable  = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                StartTime         = Get-Date -Date $startTimeString
                ScheduleType      = 'OnSessionState'
                StateChange       = 'OnConnectionFromLocalComputer'
                User              = 'MockedUser'
                Delay             = '00:01:00'
                Enable            = $true
            }

            Mock -CommandName Get-ScheduledTask
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Ensure | Should -Be 'Absent'
            }
        }

        It 'Should return false from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeFalse
            }
        }

        It 'Should register the new scheduled task' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-TargetResource @testParameters
            }

            Assert-MockCalled Register-ScheduledTask -Exactly -Times 1 -Scope It
        }

        It 'Should throw expected exception if session state change is not defined' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidArgumentRecord -Message $LocalizedData.OnSessionStateChangeError -ArgumentName 'StateChange'

                $testParameters.Remove('StateChange')
                { Set-TargetResource @testParameters } | Should -Throw $errorRecord
            }
        }
    }

    Context 'When a scheduled task is configured with a description that contains various forms of whitespace but is in the desired state' {
        BeforeAll {
            <#
                This test verifies issue #258:
                https://github.com/dsccommunity/ComputerManagementDsc/issues/258
            #>
            $testParameters = $getTargetResourceParameters + @{
                ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                Description      = "`t`n`r    test description    `t`n`r"
                ScheduleType     = 'AtStartup'
                Delay            = '00:01:00'
                Enable           = $true
            }

            Mock -CommandName Get-ScheduledTask -MockWith {
                @{
                    TaskName    = $testParameters.TaskName
                    TaskPath    = $testParameters.TaskPath
                    Description = 'test description'
                    Actions     = @(
                        [pscustomobject] @{
                            Execute = $testParameters.ActionExecutable
                        }
                    )
                    Triggers    = @(
                        [pscustomobject] @{
                            Delay         = 'PT1M'
                            StartBoundary = ''
                            CimClass      = @{
                                CimClassName = 'MSFT_TaskBootTrigger'
                            }
                        }
                    )
                    Settings    = [pscustomobject] @{
                        Enabled           = $testParameters.Enable
                        MultipleInstances = 'IgnoreNew'
                    }
                }
            }
        }

        It 'Should return the correct values from Get-TargetResource' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @getTargetResourceParameters
                $result.Description | Should -Be 'test description'
                $result.Enable | Should -Be $testParameters.Enable
                $result.Ensure | Should -Be 'Present'
                $result.ScheduleType | Should -Be $testParameters.ScheduleType
                $result.Delay | Should -Be $testParameters.Delay
            }
        }

        It 'Should return true from the test method' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TargetResource @testParameters | Should -BeTrue
            }
        }
    }
}

Describe 'DSC_ScheduledTask\Test-DateStringContainsTimeZone'  -Tag 'Private' {
    Context 'When the date string contains a date without a timezone' {
        It 'Should return $false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-DateStringContainsTimeZone -DateString '2018-10-01T01:00:00' | Should -BeFalse
            }
        }
    }

    Context 'When the date string contains a date with a timezone' {
        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-DateStringContainsTimeZone -DateString ('2018-10-01T01:00:00' + (Get-Date -Format 'zzz')) | Should -BeTrue
            }
        }
    }
}

Describe 'DSC_ScheduledTask\Set-DomainNameInAccountName' -Tag 'Private' {
    Context 'When the account name does not have a domain name and force is not set' {
        It 'Should return NewDomain\Users' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-DomainNameInAccountName -AccountName 'Users' -DomainName 'NewDomain' | Should -BeExactly 'NewDomain\Users'
            }
        }
    }

    Context 'When the account name has an empty domain and force is not set' {
        It 'Should return NewDomain\Users' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-DomainNameInAccountName -AccountName '\Users' -DomainName 'NewDomain' | Should -BeExactly 'NewDomain\Users'
            }
        }
    }

    Context 'When the account name has a domain name and force is not set' {
        It 'Should return ExistingDomain\Users' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-DomainNameInAccountName -AccountName 'ExistingDomain\Users' -DomainName 'NewDomain' | Should -BeExactly 'ExistingDomain\Users'
            }
        }
    }

    Context 'When the account name has a domain name and force is set' {
        It 'Should return NewDomain\Users' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-DomainNameInAccountName -AccountName 'ExistingDomain\Users' -DomainName 'NewDomain' -Force | Should -BeExactly 'NewDomain\Users'
            }
        }
    }

    Context 'When the account name does not have a domain name and force is set' {
        It 'Should return NewDomain\Users' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Set-DomainNameInAccountName -AccountName 'Users' -DomainName 'NewDomain' -Force | Should -BeExactly 'NewDomain\Users'
            }
        }
    }
}

Describe 'DSC_ScheduledTask\ConvertTo-NormalizedTaskPath' -Tag 'Private' {
    Context 'A scheduled task path is root or custom' {
        It 'Should return backslash' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                ConvertTo-NormalizedTaskPath -TaskPath '\' | Should -Be '\'
            }
        }

        It 'Should add backslash at the end' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                ConvertTo-NormalizedTaskPath -TaskPath '\Test' | Should -Be '\Test\'
            }
        }

        It 'Should add backslash at the beginning' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                ConvertTo-NormalizedTaskPath -TaskPath 'Test\' | Should -Be '\Test\'
            }
        }

        It 'Should add backslash at the beginning and at the end' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                ConvertTo-NormalizedTaskPath -TaskPath 'Test' | Should -Be '\Test\'
            }
        }

        It 'Should not add backslash' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                ConvertTo-NormalizedTaskPath -TaskPath '\Test\' | Should -Be '\Test\'
            }
        }
    }
}
