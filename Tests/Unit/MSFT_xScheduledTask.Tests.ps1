[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param(
)

$script:DSCModuleName      = 'xComputerManagement'
$script:DSCResourceName    = 'MSFT_xScheduledTask'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit
#endregion HEADER

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

$VerbosePreference = 'Continue'
# Begin Testing
try
{
    #region Pester Tests

    InModuleScope $script:DSCResourceName {
        $script:DSCResourceName = 'MSFT_xScheduledTask'

        Describe $script:DSCResourceName {
            BeforeAll {
                Mock -CommandName Register-ScheduledTask
                Mock -CommandName Set-ScheduledTask
                Mock -CommandName Unregister-ScheduledTask
            }

            Context 'No scheduled task exists, but it should' {
                $testParams = @{
                    TaskName = 'Test task'
                    TaskPath = '\Test\'
                    ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType = 'Once'
                    RepeatInterval = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration = (New-TimeSpan -Minutes 150).ToString()
                    Verbose = $True
                }

                Mock -CommandName Get-ScheduledTask { return $null }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should Be 'Absent'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParams | Should Be $false
                }

                It 'Should create the scheduled task in the set method' {
                    Set-TargetResource @testParams
                }
            }

            Context 'A scheduled task exists, but it should not' {
                $testParams = @{
                    TaskName = 'Test task'
                    TaskPath = '\Test\'
                    ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType = 'Once'
                    RepeatInterval = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration = (New-TimeSpan -Minutes 15).ToString()
                    Ensure = 'Absent'
                    Verbose = $True
                }

                Mock -CommandName Get-ScheduledTask { return @{
                        TaskName = $testParams.TaskName
                        TaskPath = $testParams.TaskPath
                        Actions = @(@{
                                Execute = $testParams.ActionExecutable
                            })
                        Triggers = @(@{
                                Repetition = @{
                                    Duration = "PT$([System.TimeSpan]::Parse($testParams.RepetitionDuration).TotalMinutes)M"
                                    Interval = "PT$([System.TimeSpan]::Parse($testParams.RepeatInterval).TotalMinutes)M"
                                }
                                CimClass = @{
                                    CimClassName = 'MSFT_TaskTimeTrigger'
                                }
                            })
                        Principal = @{
                            UserId = 'SYSTEM'
                        }
                    } }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParams | Should Be $false
                }

                It 'Should remove the scheduled task in the set method' {
                    Set-TargetResource @testParams
                    Assert-MockCalled Unregister-ScheduledTask
                }
            }

            Context 'A scheduled task doesnt exist, and it should not' {
                $testParams = @{
                    TaskName = 'Test task'
                    TaskPath = '\Test\'
                    ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType = 'Once'
                    Ensure = 'Absent'
                    Verbose = $True
                }

                Mock -CommandName Get-ScheduledTask { return $null }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should Be 'Absent'
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParams | Should Be $true
                }
            }

            Context 'A scheduled task with Once based repetition exists, but has the wrong settings' {
                $testParams = @{
                    TaskName = 'Test task'
                    TaskPath = '\Test\'
                    ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType = 'Once'
                    RepeatInterval = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration = (New-TimeSpan -Minutes 150).ToString()
                    Verbose = $True
                }

                Mock -CommandName Get-ScheduledTask { return @{
                        TaskName = $testParams.TaskName
                        TaskPath = $testParams.TaskPath
                        Actions = @(@{
                                Execute = $testParams.ActionExecutable
                            })
                        Triggers = @(@{
                                Repetition = @{
                                    Duration = ''
                                    Interval = "PT$(([System.TimeSpan]::Parse($testParams.RepeatInterval).TotalMinutes) + 1)M"
                                }
                                CimClass = @{
                                    CimClassName = 'MSFT_TaskTimeTrigger'
                                }
                            })
                        Principal = @{
                            UserId = 'SYSTEM'
                        }
                    } }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParams | Should Be $false
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName Unregister-ScheduledTask -Times 1
                    Assert-Mockcalled -CommandName Register-ScheduledTask -Times 1
                }
            }

            Context 'A scheduled task with minutes based repetition exists and has the correct settings' {
                $testParams = @{
                    TaskName = 'Test task'
                    TaskPath = '\Test\'
                    ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType = 'Once'
                    RepeatInterval = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration = (New-TimeSpan -Minutes 30).ToString()
                    Verbose = $True
                }

                Mock -CommandName Get-ScheduledTask { return @{
                        TaskName = $testParams.TaskName
                        TaskPath = $testParams.TaskPath
                        Actions = @(@{
                                Execute = $testParams.ActionExecutable
                            })
                        Triggers = @(@{
                                Repetition = @{
                                    Duration = "PT$([System.TimeSpan]::Parse($testParams.RepetitionDuration).TotalMinutes)M"
                                    Interval = "PT$([System.TimeSpan]::Parse($testParams.RepeatInterval).TotalMinutes)M"
                                }
                                CimClass = @{
                                    CimClassName = 'MSFT_TaskTimeTrigger'
                                }
                            })
                        Principal = @{
                            UserId = 'SYSTEM'
                        }
                    } }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should Be 'Present'
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParams | Should Be $true
                }
            }

            Context 'A scheduled task with hourly based repetition exists, but has the wrong settings' {
                $testParams = @{
                    TaskName = 'Test task'
                    TaskPath = '\Test\'
                    ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType = 'Once'
                    RepeatInterval = (New-TimeSpan -Hours 4).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
                    Verbose = $True
                }

                Mock -CommandName Get-ScheduledTask { return @{
                        TaskName = $testParams.TaskName
                        TaskPath = $testParams.TaskPath
                        Actions = @(@{
                                Execute = $testParams.ActionExecutable
                            })
                        Triggers = @(@{
                                Repetition = @{
                                    Duration = "PT$(([System.TimeSpan]::Parse($testParams.RepetitionDuration).TotalHours))H"
                                    Interval = "PT$(([System.TimeSpan]::Parse($testParams.RepeatInterval).TotalHours) + 1)H"
                                }
                                CimClass = @{
                                    CimClassName = 'MSFT_TaskTimeTrigger'
                                }
                            })
                        Principal = @{
                            UserId = 'SYSTEM'
                        }
                    } }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParams | Should Be $false
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName Unregister-ScheduledTask -Times 1
                    Assert-Mockcalled -CommandName Register-ScheduledTask -Times 1
                }
            }

            Context 'A scheduled task with hourly based repetition exists and has the correct settings' {
                $testParams = @{
                    TaskName = 'Test task'
                    TaskPath = '\Test\'
                    ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType = 'Once'
                    RepeatInterval = (New-TimeSpan -Hours 4).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
                    Verbose = $True
                }

                Mock -CommandName Get-ScheduledTask { return @{
                        TaskName = $testParams.TaskName
                        TaskPath = $testParams.TaskPath
                        Actions = @(@{
                                Execute = $testParams.ActionExecutable
                            })
                        Triggers = @(@{
                                Repetition = @{
                                    Duration = "PT$([System.TimeSpan]::Parse($testParams.RepetitionDuration).TotalHours)H"
                                    Interval = "PT$([System.TimeSpan]::Parse($testParams.RepeatInterval).TotalHours)H"
                                }
                                CimClass = @{
                                    CimClassName = 'MSFT_TaskTimeTrigger'
                                }
                            })
                        Principal = @{
                            UserId = 'SYSTEM'
                        }
                    } }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should Be 'Present'
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParams | Should Be $true
                }
            }

            Context 'A scheduled task with daily based repetition exists, but has the wrong settings' {
                $testParams = @{
                    TaskName = 'Test task'
                    TaskPath = '\Test\'
                    ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType = 'Daily'
                    DaysInterval = 3
                    Verbose = $True
                }

                Mock -CommandName Get-ScheduledTask { return @{
                        TaskName = $testParams.TaskName
                        TaskPath = $testParams.TaskPath
                        Actions = @(@{
                                Execute = $testParams.ActionExecutable
                            })
                        Triggers = @(@{
                                Repetition = @{
                                    Duration = $null
                                    Interval = "P$(($testParams.DaysInterval) + 1)D"
                                }
                                CimClass = @{
                                    CimClassName = 'MSFT_TaskDailyTrigger'
                                }
                            })
                        Principal = @{
                            UserId = 'SYSTEM'
                        }
                    } }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParams | Should Be $false
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName Unregister-ScheduledTask -Times 1
                    Assert-Mockcalled -CommandName Register-ScheduledTask -Times 1
                }
            }

            Context 'A scheduled task with daily based repetition exists and has the correct settings' {
                $testParams = @{
                    TaskName = 'Test task'
                    TaskPath = '\Test\'
                    ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType = 'Daily'
                    DaysInterval = 3
                    Verbose = $True
                }

                Mock -CommandName Get-ScheduledTask { return @{
                        TaskName = $testParams.TaskName
                        TaskPath = $testParams.TaskPath
                        Actions = @(@{
                                Execute = $testParams.ActionExecutable
                            })
                        Triggers = @(@{
                                DaysInterval = $testParams.DaysInterval
                                CimClass = @{
                                    CimClassName = 'MSFT_TaskDailyTrigger'
                                }
                            })
                        Principal = @{
                            UserId = 'SYSTEM'
                        }
                    } }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should Be 'Present'
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParams | Should Be $true
                }
            }

            Context 'A scheduled task exists and is configured with the wrong execution account' {
                $testParams = @{
                    TaskName = 'Test task'
                    TaskPath = '\Test\'
                    ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType = 'Once'
                    RepeatInterval = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
                    ExecuteAsCredential = New-Object System.Management.Automation.PSCredential ('DEMO\RightUser', (ConvertTo-SecureString 'ExamplePassword' -AsPlainText -Force))
                    Verbose = $True
                }

                Mock -CommandName Get-ScheduledTask { return @{
                        TaskName = $testParams.TaskName
                        TaskPath = $testParams.TaskPath
                        Actions = @(@{
                                Execute = $testParams.ActionExecutable
                            })
                        Triggers = @(@{
                                Repetition = @{
                                    Duration = "PT$([System.TimeSpan]::Parse($testParams.RepetitionDuration).TotalHours)H"
                                    Interval = "PT$([System.TimeSpan]::Parse($testParams.RepeatInterval).TotalMinutes)M"
                                }
                                CimClass = @{
                                    CimClassName = 'MSFT_TaskTimeTrigger'
                                }
                            })
                        Principal = @{
                            UserId = 'WrongUser'
                        }
                    } }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParams | Should Be $false
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName Unregister-ScheduledTask -Times 1
                    Assert-Mockcalled -CommandName Register-ScheduledTask -Times 1
                }
            }

            Context 'A scheduled task exists and is configured with the wrong working directory' {
                $testParams = @{
                    TaskName = 'Test task'
                    TaskPath = '\Test\'
                    ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ActionWorkingPath = 'C:\Example'
                    ScheduleType = 'Once'
                    RepeatInterval = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
                    Verbose = $True
                }

                Mock -CommandName Get-ScheduledTask { return @{
                        TaskName = $testParams.TaskName
                        TaskPath = $testParams.TaskPath
                        Actions = @(@{
                                Execute = $testParams.ActionExecutable
                                WorkingDirectory = 'C:\Wrong'
                            })
                        Triggers = @(@{
                                Repetition = @{
                                    Duration = $null
                                    Interval = "PT$([System.TimeSpan]::Parse($testParams.RepeatInterval).TotalMinutes)M"
                                }
                                CimClass = @{
                                    CimClassName = 'MSFT_TaskTimeTrigger'
                                }
                            })
                        Principal = @{
                            UserId = 'SYSTEM'
                        }
                    } }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParams | Should Be $false
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName Unregister-ScheduledTask -Times 1
                    Assert-Mockcalled -CommandName Register-ScheduledTask -Times 1
                }
            }

            Context 'A scheduled task exists and is configured with the wrong executable arguments' {
                $testParams = @{
                    TaskName = 'Test task'
                    TaskPath = '\Test\'
                    ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ActionArguments = '-File "C:\something\right.ps1"'
                    ScheduleType = 'Once'
                    RepeatInterval = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
                    Verbose = $True
                }

                Mock -CommandName Get-ScheduledTask { return @{
                        TaskName = $testParams.TaskName
                        TaskPath = $testParams.TaskPath
                        Actions = @(@{
                                Execute = $testParams.ActionExecutable
                                Arguments = '-File "C:\something\wrong.ps1"'
                            })
                        Triggers = @(@{
                                Repetition = @{
                                    Duration = "PT$([System.TimeSpan]::Parse($testParams.RepetitionDuration).TotalHours)H"
                                    Interval = "PT$([System.TimeSpan]::Parse($testParams.RepeatInterval).TotalMinutes)M"
                                }
                                CimClass = @{
                                    CimClassName = 'MSFT_TaskTimeTrigger'
                                }
                            })
                        Principal = @{
                            UserId = 'SYSTEM'
                        }
                    } }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParams | Should Be $false
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName Unregister-ScheduledTask -Times 1
                    Assert-Mockcalled -CommandName Register-ScheduledTask -Times 1
                }
            }

            Context 'A scheduled task is enabled and should be disabled' {
                $testParams = @{
                    TaskName = 'Test task'
                    TaskPath = '\Test\'
                    ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType = 'Once'
                    RepeatInterval = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
                    Enable = $false
                    Verbose = $True
                }

                Mock -CommandName Get-ScheduledTask { return @{
                        TaskName = $testParams.TaskName
                        TaskPath = $testParams.TaskPath
                        Actions = @(@{
                                Execute = $testParams.ActionExecutable
                                Arguments = $testParams.Arguments
                            })
                        Triggers = @(@{
                                Repetition = @{
                                    Duration = "PT$([System.TimeSpan]::Parse($testParams.RepetitionDuration).TotalHours)H"
                                    Interval = "PT$([System.TimeSpan]::Parse($testParams.RepeatInterval).TotalMinutes)M"
                                }
                                CimClass = @{
                                    CimClassName = 'MSFT_TaskTimeTrigger'
                                }
                            })
                        Settings = @(@{
                                Enabled = $true
                            })
                        Principal = @{
                            UserId = 'SYSTEM'
                        }
                    } }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParams | Should Be $false
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName Unregister-ScheduledTask -Times 1
                    Assert-Mockcalled -CommandName Register-ScheduledTask -Times 1
                }

            }

            Context 'A scheduled task is enabled and has the correct settings' {
                $testParams = @{
                    TaskName = 'Test task'
                    TaskPath = '\Test\'
                    ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType = 'Once'
                    RepeatInterval = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
                    RandomDelay = (New-TimeSpan -Minutes 4).ToString()
                    IdleWaitTimeout = (New-TimeSpan -Minutes 5).ToString()
                    IdleDuration = (New-TimeSpan -Minutes 6).ToString()
                    ExecutionTimeLimit = (New-TimeSpan -Minutes 7).ToString()
                    RestartInterval = (New-TimeSpan -Minutes 8).ToString()
                    Enable = $true
                    Verbose = $True
                }

                Mock -CommandName Get-ScheduledTask { return @{
                        TaskName = $testParams.TaskName
                        TaskPath = $testParams.TaskPath
                        Actions = @(@{
                                Execute = $testParams.ActionExecutable
                                Arguments = $testParams.Arguments
                            })
                        Triggers = @(@{
                                Repetition = @{
                                    Duration = "PT$([System.TimeSpan]::Parse($testParams.RepetitionDuration).TotalHours)H"
                                    Interval = "PT$([System.TimeSpan]::Parse($testParams.RepeatInterval).TotalMinutes)M"
                                }
                                RandomDelay = "PT$([System.TimeSpan]::Parse($testParams.RandomDelay).TotalMinutes)M"
                                CimClass = @{
                                    CimClassName = 'MSFT_TaskTimeTrigger'
                                }
                            })
                        Settings = @(@{
                                Enabled = $true
                                IdleSettings = @{
                                    IdleWaitTimeout = "PT$([System.TimeSpan]::Parse($testParams.IdleWaitTimeout).TotalMinutes)M"
                                    IdleDuration = "PT$([System.TimeSpan]::Parse($testParams.IdleDuration).TotalMinutes)M"
                                }
                                ExecutionTimeLimit = "PT$([System.TimeSpan]::Parse($testParams.ExecutionTimeLimit).TotalMinutes)M"
                                RestartInterval = "PT$([System.TimeSpan]::Parse($testParams.RestartInterval).TotalMinutes)M"
                            })
                        Principal = @{
                            UserId = 'SYSTEM'
                        }
                    } }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should Be 'Present'
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParams | Should Be $true
                }
            }

            Context 'A scheduled task is disabled and has the correct settings' {
                $testParams = @{
                    TaskName = 'Test task'
                    TaskPath = '\Test\'
                    ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType = 'Once'
                    RepeatInterval = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
                    Enable = $false
                    Verbose = $True
                }

                Mock -CommandName Get-ScheduledTask { return @{
                        TaskName = $testParams.TaskName
                        TaskPath = $testParams.TaskPath
                        Actions = @(@{
                                Execute = $testParams.ActionExecutable
                                Arguments = $testParams.Arguments
                            })
                        Triggers = @(@{
                                Repetition = @{
                                    Duration = "PT$([System.TimeSpan]::Parse($testParams.RepetitionDuration).TotalHours)H"
                                    Interval = "PT$([System.TimeSpan]::Parse($testParams.RepeatInterval).TotalMinutes)M"
                                }
                                CimClass = @{
                                    CimClassName = 'MSFT_TaskTimeTrigger'
                                }
                            })
                        Settings = @(@{
                                Enabled = $false
                            })
                        Principal = @{
                            UserId = 'SYSTEM'
                        }
                    } }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should Be 'Present'
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParams | Should Be $true
                }
            }

            Context 'A scheduled task is disabled but should be enabled' {
                $testParams = @{
                    TaskName = 'Test task'
                    TaskPath = '\Test\'
                    ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType = 'Once'
                    RepeatInterval = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
                    Enable = $true
                    Verbose = $True
                }

                Mock -CommandName Get-ScheduledTask { return @{
                        TaskName = $testParams.TaskName
                        TaskPath = $testParams.TaskPath
                        Actions = @(@{
                                Execute = $testParams.ActionExecutable
                                Arguments = $testParams.Arguments
                            })
                        Triggers = @(@{
                                Repetition = @{
                                    Duration = "PT$([System.TimeSpan]::Parse($testParams.RepetitionDuration).TotalHours)H"
                                    Interval = "PT$([System.TimeSpan]::Parse($testParams.RepeatInterval).TotalMinutes)M"
                                }
                                CimClass = @{
                                    CimClassName = 'MSFT_TaskTimeTrigger'
                                }
                            })
                        Settings = @(@{
                                Enabled = $false
                            })
                        Principal = @{
                            UserId = 'SYSTEM'
                        }
                    } }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParams | Should Be $false
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName Unregister-ScheduledTask -Times 1
                    Assert-Mockcalled -CommandName Register-ScheduledTask -Times 1
                }
            }

            Context 'A Scheduled task exists, is disabled, and the optional parameter enable is not specified' -Fixture {
                $testParams = @{
                    TaskName = 'Test task'
                    TaskPath = '\Test\'
                    ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType = 'Once'
                    RepeatInterval = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
                    Verbose = $True
                }

                Mock -CommandName Get-ScheduledTask { return @{
                        TaskName = $testParams.TaskName
                        TaskPath = $testParams.TaskPath
                        Actions = @(@{
                                Execute = $testParams.ActionExecutable
                                Arguments = $testParams.Arguments
                            })
                        Triggers = @(@{
                                Repetition = @{
                                    Duration = "PT$([System.TimeSpan]::Parse($testParams.RepetitionDuration).TotalHours)H"
                                    Interval = "PT$([System.TimeSpan]::Parse($testParams.RepeatInterval).TotalMinutes)M"
                                }
                                CimClass = @{
                                    CimClassName = 'MSFT_TaskTimeTrigger'
                                }
                            })
                        Settings = @(@{
                                Enabled = $false
                            })
                        Principal = @{
                            UserId = 'SYSTEM'
                        }
                    } }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should Be 'Present'
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParams | Should Be $true
                }
            }

            Context 'A scheduled task path is root or custom' -Fixture {
                It 'Should return backslash' {
                    ConvertTo-NormalizedTaskPath -TaskPath '\'| Should Be '\'
                }

                It 'Should add backslash at the end' {
                    ConvertTo-NormalizedTaskPath -TaskPath '\Test'| Should Be '\Test\'
                }

                It 'Should add backslash at the beginning' {
                    ConvertTo-NormalizedTaskPath -TaskPath 'Test\'| Should Be '\Test\'
                }

                It 'Should add backslash at the beginning and at the end' {
                    ConvertTo-NormalizedTaskPath -TaskPath 'Test'| Should Be '\Test\'
                }

                It 'Should not add backslash' {
                    ConvertTo-NormalizedTaskPath -TaskPath '\Test\'| Should Be '\Test\'
                }
            }

            Context 'A scheduled task exists and is configured with the wrong interval, duration & random delay parameters' {
                $testParams = @{
                    TaskName = 'Test task'
                    TaskPath = '\Test\'
                    ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType = 'Once'
                    RepeatInterval = (New-TimeSpan -Minutes 20).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 9).ToString()
                    RandomDelay = (New-TimeSpan -Minutes 4).ToString()
                    IdleWaitTimeout = (New-TimeSpan -Minutes 5).ToString()
                    IdleDuration = (New-TimeSpan -Minutes 6).ToString()
                    ExecutionTimeLimit = (New-TimeSpan -Minutes 7).ToString()
                    RestartInterval = (New-TimeSpan -Minutes 8).ToString()
                    Verbose = $True
                }

                Mock -CommandName Get-ScheduledTask { return @{
                        TaskName = $testParams.TaskName
                        TaskPath = $testParams.TaskPath
                        Actions = @(@{
                                Execute = $testParams.ActionExecutable
                                Arguments = $testParams.Arguments
                            })
                        Triggers = @(@{
                                Repetition = @{
                                    Duration = "PT$([System.TimeSpan]::Parse($testParams.RepetitionDuration).TotalHours + 1)H"
                                    Interval = "PT$([System.TimeSpan]::Parse($testParams.RepeatInterval).TotalMinutes + 1)M"
                                }
                                RandomDelay = "PT$([System.TimeSpan]::Parse($testParams.RandomDelay).TotalMinutes + 1)M"
                                CimClass = @{
                                    CimClassName = 'MSFT_TaskTimeTrigger'
                                }
                            })
                        Settings = @{
                            IdleSettings = @{
                                IdleWaitTimeout = "PT$([System.TimeSpan]::Parse($testParams.IdleWaitTimeout).TotalMinutes)M"
                                IdleDuration = "PT$([System.TimeSpan]::Parse($testParams.IdleDuration).TotalMinutes)M"
                            }
                            ExecutionTimeLimit = "PT$([System.TimeSpan]::Parse($testParams.ExecutionTimeLimit).TotalMinutes)M"
                            RestartInterval = "PT$([System.TimeSpan]::Parse($testParams.RestartInterval).TotalMinutes)M"
                        }
                        Principal = @{
                            UserId = 'SYSTEM'
                        }
                    } }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParams | Should Be $false
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName Unregister-ScheduledTask -Times 1
                    Assert-Mockcalled -CommandName Register-ScheduledTask -Times 1
                }
            }

            Context 'A scheduled task exists and is configured with the wrong idle timeout & idle duration parameters' {
                $testParams = @{
                    TaskName = 'Test task'
                    TaskPath = '\Test\'
                    ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType = 'Once'
                    RepeatInterval = (New-TimeSpan -Minutes 20).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 9).ToString()
                    RandomDelay = (New-TimeSpan -Minutes 4).ToString()
                    IdleWaitTimeout = (New-TimeSpan -Minutes 5).ToString()
                    IdleDuration = (New-TimeSpan -Minutes 6).ToString()
                    ExecutionTimeLimit = (New-TimeSpan -Minutes 7).ToString()
                    RestartInterval = (New-TimeSpan -Minutes 8).ToString()
                    Verbose = $True
                }

                Mock -CommandName Get-ScheduledTask { return @{
                        TaskName = $testParams.TaskName
                        TaskPath = $testParams.TaskPath
                        Actions = @(@{
                                Execute = $testParams.ActionExecutable
                                Arguments = $testParams.Arguments
                            })
                        Triggers = @(@{
                                Repetition = @{
                                    Duration = "PT$([System.TimeSpan]::Parse($testParams.RepetitionDuration).TotalHours)H"
                                    Interval = "PT$([System.TimeSpan]::Parse($testParams.RepeatInterval).TotalMinutes)M"
                                }
                                RandomDelay = "PT$([System.TimeSpan]::Parse($testParams.RandomDelay).TotalMinutes)M"
                                CimClass = @{
                                    CimClassName = 'MSFT_TaskTimeTrigger'
                                }
                            })
                        Settings = @{
                            IdleSettings = @{
                                IdleWaitTimeout = "PT$([System.TimeSpan]::Parse($testParams.IdleWaitTimeout).TotalMinutes + 1)M"
                                IdleDuration = "PT$([System.TimeSpan]::Parse($testParams.IdleDuration).TotalMinutes + 1)M"
                            }
                            ExecutionTimeLimit = "PT$([System.TimeSpan]::Parse($testParams.ExecutionTimeLimit).TotalMinutes)M"
                            RestartInterval = "PT$([System.TimeSpan]::Parse($testParams.RestartInterval).TotalMinutes)M"
                        }
                        Principal = @{
                            UserId = 'SYSTEM'
                        }
                    } }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParams | Should Be $false
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName Unregister-ScheduledTask -Times 1
                    Assert-Mockcalled -CommandName Register-ScheduledTask -Times 1
                }
            }

            Context 'A scheduled task exists and is configured with the wrong duration parameter for an indefinite trigger' {
                $testParams = @{
                    TaskName = 'Test task'
                    TaskPath = '\Test\'
                    ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType = 'Once'
                    RepeatInterval = (New-TimeSpan -Minutes 20).ToString()
                    RepetitionDuration = 'Indefinitely'
                    Verbose = $True
                }

                Mock -CommandName Get-ScheduledTask { return @{
                        TaskName = $testParams.TaskName
                        TaskPath = $testParams.TaskPath
                        Actions = @(@{
                                Execute = $testParams.ActionExecutable
                                Arguments = $testParams.Arguments
                            })
                        Triggers = @(@{
                                Repetition = @{
                                    Duration = "PT4H"
                                    Interval = "PT$([System.TimeSpan]::Parse($testParams.RepeatInterval).TotalMinutes)M"
                                }
                                CimClass = @{
                                    CimClassName = 'MSFT_TaskTimeTrigger'
                                }
                            })
                        Principal = @{
                            UserId = 'SYSTEM'
                        }
                    } }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParams | Should Be $false
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName Unregister-ScheduledTask -Times 1
                    Assert-Mockcalled -CommandName Register-ScheduledTask -Times 1
                }
            }

            Context 'A scheduled task exists and is configured with indefinite repetition duration for a trigger but should be fixed' {
                $testParams = @{
                    TaskName = 'Test task'
                    TaskPath = '\Test\'
                    ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType = 'Once'
                    RepeatInterval = (New-TimeSpan -Minutes 20).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 9).ToString()
                    Verbose = $True
                }

                Mock -CommandName Get-ScheduledTask { return @{
                        TaskName = $testParams.TaskName
                        TaskPath = $testParams.TaskPath
                        Actions = @(@{
                                Execute = $testParams.ActionExecutable
                                Arguments = $testParams.Arguments
                            })
                        Triggers = @(@{
                                Repetition = @{
                                    Duration = ""
                                    Interval = "PT$([System.TimeSpan]::Parse($testParams.RepeatInterval).TotalMinutes)M"
                                }
                                CimClass = @{
                                    CimClassName = 'MSFT_TaskTimeTrigger'
                                }
                            })
                        Principal = @{
                            UserId = 'SYSTEM'
                        }
                    } }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParams | Should Be $false
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName Unregister-ScheduledTask -Times 1
                    Assert-Mockcalled -CommandName Register-ScheduledTask -Times 1
                }
            }

            Context 'A scheduled task exists and is configured with correctly with an indefinite duration trigger' {
                $testParams = @{
                    TaskName = 'Test task'
                    TaskPath = '\Test\'
                    ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType = 'Once'
                    RepeatInterval = (New-TimeSpan -Minutes 20).ToString()
                    RepetitionDuration = 'Indefinitely'
                    Verbose = $True
                }

                Mock -CommandName Get-ScheduledTask { return @{
                        TaskName = $testParams.TaskName
                        TaskPath = $testParams.TaskPath
                        Actions = @(@{
                                Execute = $testParams.ActionExecutable
                                Arguments = $testParams.Arguments
                            })
                        Triggers = @(@{
                                Repetition = @{
                                    Duration = ""
                                    Interval = "PT$([System.TimeSpan]::Parse($testParams.RepeatInterval).TotalMinutes)M"
                                }
                                CimClass = @{
                                    CimClassName = 'MSFT_TaskTimeTrigger'
                                }
                            })
                        Principal = @{
                            UserId = 'SYSTEM'
                        }
                    } }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should Be 'Present'
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParams | Should Be $true
                }
            }
        }
    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
