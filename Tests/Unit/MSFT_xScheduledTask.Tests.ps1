[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param
(
)

$script:DSCModuleName = 'xComputerManagement'
$script:DSCResourceName = 'MSFT_xScheduledTask'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\xComputerManagement'
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
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

        # Function to allow mocking pipeline input
        function Register-ScheduledTask
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

        Describe $script:DSCResourceName {
            BeforeAll {
                Mock -CommandName Register-ScheduledTask
                Mock -CommandName Set-ScheduledTask
                Mock -CommandName Unregister-ScheduledTask
            }

            Context 'No scheduled task exists, but it should' {
                $testParameters = @{
                    TaskName           = 'Test task'
                    TaskPath           = '\Test\'
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration = (New-TimeSpan -Minutes 150).ToString()
                    Verbose            = $True
                }

                Mock -CommandName Get-ScheduledTask -MockWith { return $null }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Absent'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -Be $false
                }

                It 'Should create the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                }
            }

            Context 'A scheduled task exists, but it should not' {
                $testParameters = @{
                    TaskName           = 'Test task'
                    TaskPath           = '\Test\'
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration = (New-TimeSpan -Minutes 15).ToString()
                    Ensure             = 'Absent'
                    Verbose            = $True
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
                        Principal = @{
                            UserId = 'SYSTEM'
                        }
                    } }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -Be $false
                }

                It 'Should remove the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled Unregister-ScheduledTask
                }
            }

            Context 'A built-in scheduled task exists and is enabled, but it should be disabled' {
                $testParameters = @{
                    TaskName = 'Test task'
                    TaskPath = '\Test\'
                    Enable   = $false
                    Verbose  = $True
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
                                Duration = "PT15M"
                                Interval = "PT15M"
                            }
                            CimClass   = @{
                                CimClassName = 'MSFT_TaskTimeTrigger'
                            }
                        }
                        Settings = [pscustomobject] @{
                            Enabled = $true
                        }
                    } }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParameters
                    $result.Enable | Should -Be $true
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -Be $false
                }

                It 'Should remove the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled Register-ScheduledTask -Exactly -Times 1
                }
            }

            Context 'A built-in scheduled task exists, but it should be absent' {
                $testParameters = @{
                    TaskName = 'Test task'
                    TaskPath = '\Test\'
                    Ensure   = 'Absent'
                    Verbose  = $True
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
                                    Duration = "PT15M"
                                    Interval = "PT15M"
                                }
                                CimClass   = @{
                                    CimClassName = 'MSFT_TaskTimeTrigger'
                                }
                            }
                        )
                        Settings = [pscustomobject] @{
                            Enabled = $true
                        }
                    }
                }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParameters
                    $result.Enable | Should -Be $true
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -Be $false
                }

                It 'Should remove the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled Unregister-ScheduledTask -Exactly -Times 1
                }
            }

            Context 'A scheduled task doesnt exist, and it should not' {
                $testParameters = @{
                    TaskName         = 'Test task'
                    TaskPath         = '\Test\'
                    ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType     = 'Once'
                    Ensure           = 'Absent'
                    Verbose          = $True
                }

                Mock -CommandName Get-ScheduledTask

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Absent'
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParameters | Should -Be $true
                }
            }

            Context 'A scheduled task with Once based repetition exists, but has the wrong settings' {
                $testParameters = @{
                    TaskName           = 'Test task'
                    TaskPath           = '\Test\'
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration = (New-TimeSpan -Minutes 150).ToString()
                    Verbose            = $True
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
                                }
                                CimClass   = @{
                                    CimClassName = 'MSFT_TaskTimeTrigger'
                                }
                            }
                        )
                        Principal = [pscustomobject] @{
                            UserId = 'SYSTEM'
                        }
                    }
                }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -Be $false
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Unregister-ScheduledTask -Exactly -Times 1
                    Assert-Mockcalled -CommandName Register-ScheduledTask -Exactly -Times 1
                }
            }

            Context 'A scheduled task with minutes based repetition exists and has the correct settings' {
                $testParameters = @{
                    TaskName           = 'Test task'
                    TaskPath           = '\Test\'
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration = (New-TimeSpan -Minutes 30).ToString()
                    Verbose            = $True
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
                                }
                                CimClass   = @{
                                    CimClassName = 'MSFT_TaskTimeTrigger'
                                }
                            }
                        )
                        Principal = [pscustomobject] @{
                            UserId = 'SYSTEM'
                        }
                    }
                }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParameters | Should -Be $true
                }
            }

            Context 'A scheduled task with hourly based repetition exists, but has the wrong settings' {
                $testParameters = @{
                    TaskName           = 'Test task'
                    TaskPath           = '\Test\'
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Hours 4).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
                    Verbose            = $True
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
                                }
                                CimClass   = @{
                                    CimClassName = 'MSFT_TaskTimeTrigger'
                                }
                            }
                        )
                        Principal = [pscustomobject] @{
                            UserId = 'SYSTEM'
                        }
                    }
                }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -Be $false
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Unregister-ScheduledTask -Exactly -Times 1
                    Assert-Mockcalled -CommandName Register-ScheduledTask -Exactly -Times 1
                }
            }

            Context 'A scheduled task with hourly based repetition exists and has the correct settings' {
                $testParameters = @{
                    TaskName           = 'Test task'
                    TaskPath           = '\Test\'
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Hours 4).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
                    Verbose            = $True
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
                                }
                                CimClass   = @{
                                    CimClassName = 'MSFT_TaskTimeTrigger'
                                }
                            }
                        )
                        Principal = [pscustomobject] @{
                            UserId = 'SYSTEM'
                        }
                    }
                }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParameters | Should -Be $true
                }
            }

            Context 'A scheduled task with daily based repetition exists, but has the wrong settings' {
                $testParameters = @{
                    TaskName         = 'Test task'
                    TaskPath         = '\Test\'
                    ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType     = 'Daily'
                    DaysInterval     = 3
                    Verbose          = $True
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
                        Principal = [pscustomobject] @{
                            UserId = 'SYSTEM'
                        }
                    }
                }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -Be $false
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Unregister-ScheduledTask -Exactly -Times 1
                    Assert-Mockcalled -CommandName Register-ScheduledTask -Exactly -Times 1
                }
            }

            Context 'A scheduled task with daily based repetition exists and has the correct settings' {
                $testParameters = @{
                    TaskName         = 'Test task'
                    TaskPath         = '\Test\'
                    ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType     = 'Daily'
                    DaysInterval     = 3
                    Verbose          = $True
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
                        Principal = [pscustomobject] @{
                            UserId = 'SYSTEM'
                        }
                    }
                }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParameters | Should -Be $true
                }
            }

            Context 'A scheduled task exists and is configured with the wrong execution account' {
                $testParameters = @{
                    TaskName            = 'Test task'
                    TaskPath            = '\Test\'
                    ActionExecutable    = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType        = 'Once'
                    RepeatInterval      = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration  = (New-TimeSpan -Hours 8).ToString()
                    ExecuteAsCredential = New-Object System.Management.Automation.PSCredential ('DEMO\RightUser', (ConvertTo-SecureString 'ExamplePassword' -AsPlainText -Force))
                    Verbose             = $True
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
                        Principal = [pscustomobject] @{
                            UserId = 'WrongUser'
                        }
                    }
                }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -Be $false
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Unregister-ScheduledTask -Exactly -Times 1
                    Assert-Mockcalled -CommandName Register-ScheduledTask -Exactly -Times 1
                }
            }

            Context 'A scheduled task exists and is configured with the wrong logon type' {
                $testParameters = @{
                    TaskName            = 'Test task'
                    TaskPath            = '\Test\'
                    ActionExecutable    = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType        = 'Once'
                    RepeatInterval      = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration  = (New-TimeSpan -Hours 8).ToString()
                    ExecuteAsCredential = New-Object System.Management.Automation.PSCredential ('DEMO\RightUser', (ConvertTo-SecureString 'ExamplePassword' -AsPlainText -Force))
                    LogonType           = 'S4U'
                    Verbose             = $True
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
                        Principal = [pscustomobject] @{
                            UserId    = 'DEMO\RightUser'
                            LogonType = 'Password'
                        }
                    }
                }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'
                    $result.LogonType | Should -Be 'Password'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -Be $false
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Unregister-ScheduledTask -Exactly -Times 1
                    Assert-Mockcalled -CommandName Register-ScheduledTask -Exactly -Times 1
                }
            }

            Context 'A scheduled task exists and is configured with the wrong run level' {
                $testParameters = @{
                    TaskName            = 'Test task'
                    TaskPath            = '\Test\'
                    ActionExecutable    = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType        = 'Once'
                    RepeatInterval      = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration  = (New-TimeSpan -Hours 8).ToString()
                    ExecuteAsCredential = New-Object System.Management.Automation.PSCredential ('DEMO\RightUser', (ConvertTo-SecureString 'ExamplePassword' -AsPlainText -Force))
                    RunLevel            = 'Highest'
                    Verbose             = $True
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
                        Principal = [pscustomobject] @{
                            UserId   = 'DEMO\RightUser'
                            RunLevel = 'Limited'
                        }
                    }
                }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'
                    $result.RunLevel | Should -Be 'Limited'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -Be $false
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Unregister-ScheduledTask -Exactly -Times 1
                    Assert-Mockcalled -CommandName Register-ScheduledTask -Exactly -Times 1
                }
            }

            Context 'A scheduled task exists and is configured with the wrong working directory' {
                $testParameters = @{
                    TaskName           = 'Test task'
                    TaskPath           = '\Test\'
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ActionWorkingPath  = 'C:\Example'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
                    Verbose            = $True
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
                        Principal = [pscustomobject] @{
                            UserId = 'SYSTEM'
                        }
                    }
                }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -Be $false
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Unregister-ScheduledTask -Exactly -Times 1
                    Assert-Mockcalled -CommandName Register-ScheduledTask -Exactly -Times 1
                }
            }

            Context 'A scheduled task exists and is configured with the wrong executable arguments' {
                $testParameters = @{
                    TaskName           = 'Test task'
                    TaskPath           = '\Test\'
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ActionArguments    = '-File "C:\something\right.ps1"'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
                    Verbose            = $True
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
                        Principal = [pscustomobject] @{
                            UserId = 'SYSTEM'
                        }
                    }
                }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -Be $false
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Unregister-ScheduledTask -Exactly -Times 1
                    Assert-Mockcalled -CommandName Register-ScheduledTask -Exactly -Times 1
                }
            }

            Context 'A scheduled task is enabled and should be disabled' {
                $testParameters = @{
                    TaskName           = 'Test task'
                    TaskPath           = '\Test\'
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
                    Enable             = $false
                    Verbose            = $True
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
                            Enabled = $true
                        }
                        Principal = [pscustomobject] @{
                            UserId = 'SYSTEM'
                        }
                    }
                }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -Be $false
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Unregister-ScheduledTask -Exactly -Times 1
                    Assert-Mockcalled -CommandName Register-ScheduledTask -Exactly -Times 1
                }

            }

            Context 'A scheduled task is enabled without an execution time limit and but has an execution time limit set' {
                $testParameters = @{
                    TaskName           = 'Test task'
                    TaskPath           = '\Test\'
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
                    ExecutionTimeLimit = (New-TimeSpan -Seconds 0).ToString()
                    Enable             = $true
                    Verbose            = $True
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
                            Enabled            = $true
                            ExecutionTimeLimit = "PT$([System.TimeSpan]::Parse($testParameters.RepeatInterval).TotalSeconds + 60)S"
                        }
                        Principal = [pscustomobject] @{
                            UserId = 'SYSTEM'
                        }
                    }
                }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -Be $false
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Unregister-ScheduledTask -Exactly -Times 1
                    Assert-Mockcalled -CommandName Register-ScheduledTask -Exactly -Times 1
                }
            }

            Context 'A scheduled task is enabled and has the correct settings' {
                $testParameters = @{
                    TaskName           = 'Test task'
                    TaskPath           = '\Test\'
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
                    RandomDelay        = (New-TimeSpan -Minutes 4).ToString()
                    IdleWaitTimeout    = (New-TimeSpan -Minutes 5).ToString()
                    IdleDuration       = (New-TimeSpan -Minutes 6).ToString()
                    ExecutionTimeLimit = (New-TimeSpan -Minutes 7).ToString()
                    RestartInterval    = (New-TimeSpan -Minutes 8).ToString()
                    Enable             = $true
                    Verbose            = $True
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
                                IdleWaitTimeout = "PT$([System.TimeSpan]::Parse($testParameters.IdleWaitTimeout).TotalMinutes)M"
                                IdleDuration    = "PT$([System.TimeSpan]::Parse($testParameters.IdleDuration).TotalMinutes)M"
                            }
                            ExecutionTimeLimit = "PT$([System.TimeSpan]::Parse($testParameters.ExecutionTimeLimit).TotalMinutes)M"
                            RestartInterval    = "PT$([System.TimeSpan]::Parse($testParameters.RestartInterval).TotalMinutes)M"
                        }
                        Principal = [pscustomobject] @{
                            UserId = 'SYSTEM'
                        }
                    }
                }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParameters | Should -Be $true
                }
            }

            Context 'A scheduled task is disabled and has the correct settings' {
                $testParameters = @{
                    TaskName           = 'Test task'
                    TaskPath           = '\Test\'
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
                    Enable             = $false
                    Verbose            = $True
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
                            Enabled = $false
                        }
                        Principal = [pscustomobject] @{
                            UserId = 'SYSTEM'
                        }
                    }
                }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParameters | Should -Be $true
                }
            }

            Context 'A scheduled task is disabled but should be enabled' {
                $testParameters = @{
                    TaskName           = 'Test task'
                    TaskPath           = '\Test\'
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
                    Enable             = $true
                    Verbose            = $True
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
                            Enabled = $false
                        }
                        Principal = [pscustomobject] @{
                            UserId = 'SYSTEM'
                        }
                    }
                }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -Be $false
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Unregister-ScheduledTask -Exactly -Times 1
                    Assert-Mockcalled -CommandName Register-ScheduledTask -Exactly -Times 1
                }
            }

            Context 'A Scheduled task exists, is disabled, and the optional parameter enable is not specified' -Fixture {
                $testParameters = @{
                    TaskName           = 'Test task'
                    TaskPath           = '\Test\'
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
                    Verbose            = $True
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
                            Enabled = $false
                        }
                        Principal = [pscustomobject] @{
                            UserId = 'SYSTEM'
                        }
                    }
                }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParameters | Should -Be $true
                }
            }

            Context 'A scheduled task path is root or custom' -Fixture {
                It 'Should return backslash' {
                    ConvertTo-NormalizedTaskPath -TaskPath '\'| Should -Be '\'
                }

                It 'Should add backslash at the end' {
                    ConvertTo-NormalizedTaskPath -TaskPath '\Test'| Should -Be '\Test\'
                }

                It 'Should add backslash at the beginning' {
                    ConvertTo-NormalizedTaskPath -TaskPath 'Test\'| Should -Be '\Test\'
                }

                It 'Should add backslash at the beginning and at the end' {
                    ConvertTo-NormalizedTaskPath -TaskPath 'Test'| Should -Be '\Test\'
                }

                It 'Should not add backslash' {
                    ConvertTo-NormalizedTaskPath -TaskPath '\Test\'| Should -Be '\Test\'
                }
            }

            Context 'A scheduled task exists and is configured with the wrong interval, duration & random delay parameters' {
                $testParameters = @{
                    TaskName           = 'Test task'
                    TaskPath           = '\Test\'
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Minutes 20).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 9).ToString()
                    RandomDelay        = (New-TimeSpan -Minutes 4).ToString()
                    IdleWaitTimeout    = (New-TimeSpan -Minutes 5).ToString()
                    IdleDuration       = (New-TimeSpan -Minutes 6).ToString()
                    ExecutionTimeLimit = (New-TimeSpan -Minutes 7).ToString()
                    RestartInterval    = (New-TimeSpan -Minutes 8).ToString()
                    Verbose            = $True
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
                                IdleWaitTimeout = "PT$([System.TimeSpan]::Parse($testParameters.IdleWaitTimeout).TotalMinutes)M"
                                IdleDuration    = "PT$([System.TimeSpan]::Parse($testParameters.IdleDuration).TotalMinutes)M"
                            }
                            ExecutionTimeLimit = "PT$([System.TimeSpan]::Parse($testParameters.ExecutionTimeLimit).TotalMinutes)M"
                            RestartInterval    = "PT$([System.TimeSpan]::Parse($testParameters.RestartInterval).TotalMinutes)M"
                        }
                        Principal = [pscustomobject] @{
                            UserId = 'SYSTEM'
                        }
                    }
                }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -Be $false
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Unregister-ScheduledTask -Exactly -Times 1
                    Assert-Mockcalled -CommandName Register-ScheduledTask -Exactly -Times 1
                }
            }

            Context 'A scheduled task exists and is configured with the wrong idle timeout & idle duration parameters' {
                $testParameters = @{
                    TaskName           = 'Test task'
                    TaskPath           = '\Test\'
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Minutes 20).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 9).ToString()
                    RandomDelay        = (New-TimeSpan -Minutes 4).ToString()
                    IdleWaitTimeout    = (New-TimeSpan -Minutes 5).ToString()
                    IdleDuration       = (New-TimeSpan -Minutes 6).ToString()
                    ExecutionTimeLimit = (New-TimeSpan -Minutes 7).ToString()
                    RestartInterval    = (New-TimeSpan -Minutes 8).ToString()
                    Verbose            = $True
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
                                IdleWaitTimeout = "PT$([System.TimeSpan]::Parse($testParameters.IdleWaitTimeout).TotalMinutes + 1)M"
                                IdleDuration    = "PT$([System.TimeSpan]::Parse($testParameters.IdleDuration).TotalMinutes + 1)M"
                            }
                            ExecutionTimeLimit = "PT$([System.TimeSpan]::Parse($testParameters.ExecutionTimeLimit).TotalMinutes)M"
                            RestartInterval    = "PT$([System.TimeSpan]::Parse($testParameters.RestartInterval).TotalMinutes)M"
                        }
                        Principal = [pscustomobject] @{
                            UserId = 'SYSTEM'
                        }
                    }
                }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -Be $false
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Unregister-ScheduledTask -Exactly -Times 1
                    Assert-Mockcalled -CommandName Register-ScheduledTask -Exactly -Times 1
                }
            }

            Context 'A scheduled task exists and is configured with the wrong duration parameter for an indefinite trigger' {
                $testParameters = @{
                    TaskName           = 'Test task'
                    TaskPath           = '\Test\'
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Minutes 20).ToString()
                    RepetitionDuration = 'Indefinitely'
                    Verbose            = $True
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
                        Principal = [pscustomobject] @{
                            UserId = 'SYSTEM'
                        }
                    }
                }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -Be $false
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Unregister-ScheduledTask -Exactly -Times 1
                    Assert-Mockcalled -CommandName Register-ScheduledTask -Exactly -Times 1
                }
            }

            Context 'A scheduled task exists and is configured with indefinite repetition duration for a trigger but should be fixed' {
                $testParameters = @{
                    TaskName           = 'Test task'
                    TaskPath           = '\Test\'
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Minutes 20).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 9).ToString()
                    Verbose            = $True
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
                        Principal = [pscustomobject] @{
                            UserId = 'SYSTEM'
                        }
                    }
                }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -Be $false
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Unregister-ScheduledTask -Exactly -Times 1
                    Assert-Mockcalled -CommandName Register-ScheduledTask -Exactly -Times 1
                }
            }

            Context 'A scheduled task exists and is configured with correctly with an indefinite duration trigger' {
                $testParameters = @{
                    TaskName           = 'Test task'
                    TaskPath           = '\Test\'
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Minutes 20).ToString()
                    RepetitionDuration = 'Indefinitely'
                    Verbose            = $True
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
                        Principal = [pscustomobject] @{
                            UserId = 'SYSTEM'
                        }
                    }
                }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParameters | Should -Be $true
                }
            }

            Context 'When a built-in scheduled task exists and is enabled, but it should be disabled and the trigger type is not recognized' {
                $testParameters = @{
                    TaskName = 'Test task'
                    TaskPath = '\Test\'
                    Enable   = $false
                    Verbose  = $True
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
                                Duration = "PT15M"
                                Interval = "PT15M"
                            }
                            CimClass   = @{
                                CimClassName = 'MSFT_TaskEventTrigger'
                            }
                        }
                        Settings = [pscustomobject] @{
                            Enabled = $true
                        }
                    } }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @testParameters
                    $result.Enable | Should -Be $true
                    $result.Ensure | Should -Be 'Present'
                    $result.ScheduleType | Should -BeNullOrEmpty
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -Be $false
                }

                It 'Should disable the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled Register-ScheduledTask -Exactly -Times 1
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
