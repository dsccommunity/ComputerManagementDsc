[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param
(
)

#region HEADER
$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'MSFT_ScheduledTask'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

# Unit Test Template Version: 1.2.4
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
    -ResourceType 'Mof' `
    -TestType Unit
#endregion HEADER

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

$VerbosePreference = 'Continue'
# Begin Testing
try
{
    #region Pester Tests

    InModuleScope $script:dscResourceName {
        $script:dscResourceName = 'MSFT_ScheduledTask'

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

        # Function to allow mocking pipeline input
        function Set-ScheduledTask
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

        Describe $script:dscResourceName {
            BeforeAll {
                Mock -CommandName Register-ScheduledTask
                Mock -CommandName Set-ScheduledTask
                Mock -CommandName Unregister-ScheduledTask

                $getTargetResourceParameters = @{
                    TaskName           = 'Test task'
                    TaskPath           = '\Test\'
                }
            }

            Context 'No scheduled task exists, but it should' {
                $testParameters = $getTargetResourceParameters + @{
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration = (New-TimeSpan -Minutes 150).ToString()
                    Verbose            = $true
                }

                Mock -CommandName Get-ScheduledTask -MockWith { return $null }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Ensure | Should -Be 'Absent'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -BeFalse
                }

                It 'Should create the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                }
            }

            Context 'A scheduled task exists, but it should not' {
                $testParameters = $getTargetResourceParameters + @{
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration = (New-TimeSpan -Minutes 15).ToString()
                    Ensure             = 'Absent'
                    Verbose            = $true
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
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -BeFalse
                }

                It 'Should remove the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled Unregister-ScheduledTask
                }
            }

            Context 'A built-in scheduled task exists and is enabled, but it should be disabled' {
                $testParameters = $getTargetResourceParameters + @{
                    Enable   = $false
                    Verbose  = $true
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
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Enable | Should -BeTrue
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -BeFalse
                }

                It 'Should remove the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled Register-ScheduledTask -Exactly -Times 1
                }
            }

            Context 'A built-in scheduled task exists, but it should be absent' {
                $testParameters = $getTargetResourceParameters + @{
                    Ensure   = 'Absent'
                    Verbose  = $true
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
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Enable | Should -BeTrue
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -BeFalse
                }

                It 'Should remove the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled Unregister-ScheduledTask -Exactly -Times 1
                }
            }

            Context 'A scheduled task doesnt exist, and it should not' {
                $testParameters = $getTargetResourceParameters + @{
                    ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType     = 'Once'
                    Ensure           = 'Absent'
                    Verbose          = $true
                }

                Mock -CommandName Get-ScheduledTask

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Ensure | Should -Be 'Absent'
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParameters | Should -BeTrue
                }
            }

            Context 'A scheduled task with Once based repetition exists, but has the wrong settings' {
                $testParameters = $getTargetResourceParameters + @{
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration = (New-TimeSpan -Minutes 150).ToString()
                    Verbose            = $true
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
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -BeFalse
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Set-ScheduledTask -Exactly -Times 1
                }
            }

            Context 'A scheduled task with minutes based repetition exists and has the correct settings' {
                $testParameters = $getTargetResourceParameters + @{
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration = (New-TimeSpan -Minutes 30).ToString()
                    Verbose            = $true
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
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParameters | Should -BeTrue
                }
            }

            Context 'A scheduled task with hourly based repetition exists, but has the wrong settings' {
                $testParameters = $getTargetResourceParameters + @{
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Hours 4).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
                    Verbose            = $true
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
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -BeFalse
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Set-ScheduledTask -Exactly -Times 1
                }
            }

            Context 'A scheduled task with hourly based repetition exists and has the correct settings' {
                $testParameters = $getTargetResourceParameters + @{
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Hours 4).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
                    Verbose            = $true
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
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParameters | Should -BeTrue
                }
            }

            Context 'A scheduled task with daily based repetition exists, but has the wrong settings' {
                $testParameters = $getTargetResourceParameters + @{
                    ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType     = 'Daily'
                    DaysInterval     = 3
                    Verbose          = $true
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
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -BeFalse
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Set-ScheduledTask -Exactly -Times 1
                }
            }

            Context 'A scheduled task with daily based repetition exists and has the correct settings' {
                $testParameters = $getTargetResourceParameters + @{
                    ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType     = 'Daily'
                    DaysInterval     = 3
                    Verbose          = $true
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
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParameters | Should -BeTrue
                }
            }

            Context 'A scheduled task exists and is configured with the wrong execution account' {
                $testParameters = $getTargetResourceParameters + @{
                    ActionExecutable    = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType        = 'Once'
                    RepeatInterval      = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration  = (New-TimeSpan -Hours 8).ToString()
                    ExecuteAsCredential = New-Object System.Management.Automation.PSCredential ('DEMO\RightUser', (ConvertTo-SecureString 'ExamplePassword' -AsPlainText -Force))
                    Verbose             = $true
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
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -BeFalse
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Set-ScheduledTask -Exactly -Times 1
                }
            }

            Context 'A scheduled task exists and is configured with the wrong logon type' {
                $testParameters = $getTargetResourceParameters + @{
                    ActionExecutable    = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType        = 'Once'
                    RepeatInterval      = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration  = (New-TimeSpan -Hours 8).ToString()
                    ExecuteAsCredential = New-Object System.Management.Automation.PSCredential ('DEMO\RightUser', (ConvertTo-SecureString 'ExamplePassword' -AsPlainText -Force))
                    LogonType           = 'S4U'
                    Verbose             = $true
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
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Ensure | Should -Be 'Present'
                    $result.LogonType | Should -Be 'Password'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -BeFalse
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Set-ScheduledTask -Exactly -Times 1
                }
            }

            Context 'A scheduled task exists and is configured with the wrong run level' {
                $testParameters = $getTargetResourceParameters + @{
                    ActionExecutable    = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType        = 'Once'
                    RepeatInterval      = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration  = (New-TimeSpan -Hours 8).ToString()
                    ExecuteAsCredential = New-Object System.Management.Automation.PSCredential ('DEMO\RightUser', (ConvertTo-SecureString 'ExamplePassword' -AsPlainText -Force))
                    RunLevel            = 'Highest'
                    Verbose             = $true
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
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Ensure | Should -Be 'Present'
                    $result.RunLevel | Should -Be 'Limited'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -BeFalse
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Set-ScheduledTask -Exactly -Times 1
                }
            }

            Context 'A scheduled task exists and is configured with the wrong working directory' {
                $testParameters = $getTargetResourceParameters + @{
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ActionWorkingPath  = 'C:\Example'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
                    Verbose            = $true
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
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -BeFalse
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Set-ScheduledTask -Exactly -Times 1
                }
            }

            Context 'A scheduled task exists and is configured with the wrong executable arguments' {
                $testParameters = $getTargetResourceParameters + @{
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ActionArguments    = '-File "C:\something\right.ps1"'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
                    Verbose            = $true
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
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -BeFalse
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Set-ScheduledTask -Exactly -Times 1
                }
            }

            Context 'A scheduled task is enabled and should be disabled' {
                $testParameters = $getTargetResourceParameters + @{
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
                    Enable             = $false
                    Verbose            = $true
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
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -BeFalse
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Set-ScheduledTask -Exactly -Times 1
                }

            }

            Context 'A scheduled task is enabled without an execution time limit and but has an execution time limit set' {
                $testParameters = $getTargetResourceParameters + @{
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
                    ExecutionTimeLimit = (New-TimeSpan -Seconds 0).ToString()
                    Enable             = $true
                    Verbose            = $true
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
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -BeFalse
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Set-ScheduledTask -Exactly -Times 1
                }
            }

            Context 'A scheduled task is enabled and has the correct settings' {
                $testParameters = $getTargetResourceParameters + @{
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
                    Verbose            = $true
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
                                WaitTimeout = "PT$([System.TimeSpan]::Parse($testParameters.IdleWaitTimeout).TotalMinutes)M"
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
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParameters | Should -BeTrue
                }
            }

            Context 'A scheduled task is disabled and has the correct settings' {
                $testParameters = $getTargetResourceParameters + @{
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
                    Enable             = $false
                    Verbose            = $true
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
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParameters | Should -BeTrue
                }
            }

            Context 'A scheduled task is disabled but should be enabled' {
                $testParameters = $getTargetResourceParameters + @{
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
                    Enable             = $true
                    Verbose            = $true
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
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -BeFalse
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Set-ScheduledTask -Exactly -Times 1
                }
            }

            Context 'A Scheduled task exists, is disabled, and the optional parameter enable is not specified' -Fixture {
                $testParameters = $getTargetResourceParameters + @{
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 8).ToString()
                    Verbose            = $true
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
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParameters | Should -BeTrue
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
                $testParameters = $getTargetResourceParameters + @{
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Minutes 20).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 9).ToString()
                    RandomDelay        = (New-TimeSpan -Minutes 4).ToString()
                    IdleWaitTimeout    = (New-TimeSpan -Minutes 5).ToString()
                    IdleDuration       = (New-TimeSpan -Minutes 6).ToString()
                    ExecutionTimeLimit = (New-TimeSpan -Minutes 7).ToString()
                    RestartInterval    = (New-TimeSpan -Minutes 8).ToString()
                    Verbose            = $true
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
                                WaitTimeout = "PT$([System.TimeSpan]::Parse($testParameters.IdleWaitTimeout).TotalMinutes)M"
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
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -BeFalse
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Set-ScheduledTask -Exactly -Times 1
                }
            }

            Context 'A scheduled task exists and is configured with the wrong idle timeout & idle duration parameters' {
                $testParameters = $getTargetResourceParameters + @{
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Minutes 20).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 9).ToString()
                    RandomDelay        = (New-TimeSpan -Minutes 4).ToString()
                    IdleWaitTimeout    = (New-TimeSpan -Minutes 5).ToString()
                    IdleDuration       = (New-TimeSpan -Minutes 6).ToString()
                    ExecutionTimeLimit = (New-TimeSpan -Minutes 7).ToString()
                    RestartInterval    = (New-TimeSpan -Minutes 8).ToString()
                    Verbose            = $true
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
                                WaitTimeout = "PT$([System.TimeSpan]::Parse($testParameters.IdleWaitTimeout).TotalMinutes + 1)M"
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
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -BeFalse
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Set-ScheduledTask -Exactly -Times 1
                }
            }

            Context 'A scheduled task exists and is configured with the wrong duration parameter for an indefinite trigger' {
                $testParameters = $getTargetResourceParameters + @{
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Minutes 20).ToString()
                    RepetitionDuration = 'Indefinitely'
                    Verbose            = $true
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
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -BeFalse
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Set-ScheduledTask -Exactly -Times 1
                }
            }

            Context 'A scheduled task exists and is configured with indefinite repetition duration for a trigger but should be fixed' {
                $testParameters = $getTargetResourceParameters + @{
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Minutes 20).ToString()
                    RepetitionDuration = (New-TimeSpan -Hours 9).ToString()
                    Verbose            = $true
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
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -BeFalse
                }

                It 'Should update the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Set-ScheduledTask -Exactly -Times 1
                }
            }

            Context 'A scheduled task exists and is configured with correctly with an indefinite duration trigger' {
                $testParameters = $getTargetResourceParameters + @{
                    ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType       = 'Once'
                    RepeatInterval     = (New-TimeSpan -Minutes 20).ToString()
                    RepetitionDuration = 'Indefinitely'
                    Verbose            = $true
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
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParameters | Should -BeTrue
                }
            }

            Context 'When a built-in scheduled task exists and is enabled, but it should be disabled and the trigger type is not recognized' {
                $testParameters = $getTargetResourceParameters + @{
                    Enable   = $false
                    Verbose  = $true
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
                                CimClassName = 'MSFT_TaskSessionStateChangeTrigger'
                            }
                        }
                        Settings = [pscustomobject] @{
                            Enabled = $true
                        }
                    }
                }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Enable | Should -BeTrue
                    $result.Ensure | Should -Be 'Present'
                    $result.ScheduleType | Should -BeNullOrEmpty
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -BeFalse
                }

                It 'Should disable the scheduled task in the set method' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled Register-ScheduledTask -Exactly -Times 1
                }
            }

            Context 'When a scheduled task with an OnEvent scheduletype is in desired state' {
                $testParameters = $getTargetResourceParameters + @{
                    ScheduleType      = 'OnEvent'
                    ActionExecutable  = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    EventSubscription = '<QueryList><Query Id="0" Path="System"><Select Path="System">*[System[Provider[@Name=''User32''] and EventID=1600]]</Select></Query></QueryList>'
                    Delay             = '00:01:00'
                    Enable            = $true
                    Verbose           = $true
                }

                Mock -CommandName Get-ScheduledTask -MockWith {
                    @{
                        TaskName = $testParameters.TaskName
                        TaskPath = $testParameters.TaskPath
                        Actions  = [pscustomobject] @{
                            Execute = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                        }
                        Triggers = [pscustomobject] @{
                            Delay = 'PT1M'
                            Subscription = $testParameters.EventSubscription
                            CimClass   = @{
                                CimClassName = 'MSFT_TaskEventTrigger'
                            }
                        }
                        Settings = [pscustomobject] @{
                            Enabled = $true
                        }
                    }
                }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Enable | Should -BeTrue
                    $result.Ensure | Should -Be 'Present'
                    $result.ScheduleType | Should -Be 'OnEvent'
                    $result.EventSubscription | Should -Be $testParameters.EventSubscription
                    $result.Delay | Should -Be $testParameters.Delay
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParameters | Should -BeTrue
                }
            }

            Context 'When a scheduled task with an OnEvent scheduletype needs to be created' {
                $testParameters = $getTargetResourceParameters + @{
                    ScheduleType      = 'OnEvent'
                    ActionExecutable  = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    EventSubscription = '<QueryList><Query Id="0" Path="System"><Select Path="System">*[System[Provider[@Name=''User32''] and EventID=1600]]</Select></Query></QueryList>'
                    Delay             = '00:01:00'
                    Enable            = $true
                    Verbose           = $true
                }

                Mock -CommandName Get-ScheduledTask

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Ensure | Should -Be 'Absent'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -BeFalse
                }

                It 'Should register the new scheduled task' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled Register-ScheduledTask -Exactly -Times 1 -Scope It
                }
            }

            Context 'When a scheduled task with an OnEvent scheduletype needs to be updated' {
                $testParameters = $getTargetResourceParameters + @{
                    ScheduleType      = 'OnEvent'
                    ActionExecutable  = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    EventSubscription = '<QueryList><Query Id="0" Path="System"><Select Path="System">*[System[Provider[@Name=''User32''] and EventID=1600]]</Select></Query></QueryList>'
                    Delay             = '00:05:00'
                    Enable            = $true
                    Verbose           = $true
                }

                Mock -CommandName Get-ScheduledTask -MockWith {
                    @{
                        TaskName = $testParameters.TaskName
                        TaskPath = $testParameters.TaskPath
                        Actions  = [pscustomobject] @{
                            Execute = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                        }
                        Triggers = [pscustomobject] @{
                            Delay = 'PT1M'
                            Subscription = '<QueryList><Query Id="0" Path="System"><Select Path="System">*[System[Provider[@Name=''User32''] and EventID=1601]]</Select></Query></QueryList>'
                            CimClass   = @{
                                CimClassName = 'MSFT_TaskEventTrigger'
                            }
                        }
                        Settings = [pscustomobject] @{
                            Enabled = $true
                        }
                    }
                }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Enable | Should -BeTrue
                    $result.Ensure | Should -Be 'Present'
                    $result.ScheduleType | Should -Be 'OnEvent'
                }

                It 'Should return false from the test method' {
                    Test-TargetResource @testParameters | Should -BeFalse
                }

                It 'Should not call Register-ScheduledTask on an already registered task' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled Register-ScheduledTask -Times 0 -Scope It
                }

                It 'Should call Set-ScheduledTask to update the scheduled task with the new values' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled Set-ScheduledTask -Times 1 -Scope It
                }
            }

            Context 'When a scheduled task with an OnEvent scheduletype is used on combination with unsupported parameters for this scheduletype' {
                $testParameters = $getTargetResourceParameters + @{
                    ScheduleType      = 'OnEvent'
                    ActionExecutable  = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    EventSubscription = '<QueryList><Query Id="0" Path="System"><Select Path="System">*[System[Provider[@Name=''User32''] and EventID=1600]]</Select></Query></QueryList>'
                    RandomDelay       = '01:00:00'
                    Delay             = '00:01:00'
                    Enable            = $true
                    Verbose           = $true
                }

                Mock -CommandName Get-ScheduledTask -MockWith {
                    @{
                        TaskName = $testParameters.TaskName
                        TaskPath = $testParameters.TaskPath
                        Actions  = [pscustomobject] @{
                            Execute = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                        }
                        Triggers = [pscustomobject] @{
                            Delay = 'PT1M'
                            Subscription = $testParameters.EventSubscription
                            CimClass   = @{
                                CimClassName = 'MSFT_TaskEventTrigger'
                            }
                        }
                        Settings = [pscustomobject] @{
                            Enabled = $true
                        }
                    }
                }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Enable | Should -BeTrue
                    $result.Ensure | Should -Be 'Present'
                    $result.ScheduleType | Should -Be 'OnEvent'
                    $result.RandomDelay | Should -Be '00:00:00'
                }

                It 'Should return true from the test method - ignoring the RandomDelay parameter' {
                    Test-TargetResource @testParameters | Should -BeTrue
                }

                $testParameters.EventSubscription = 'InvalidXML'

                It 'When an EventSubscription cannot be parsed as valid XML an error is generated when changing the task' {
                    { Set-TargetResource @testParameters } | Should -Throw
                }
            }

            Context 'When a scheduled task is created using a Built In Service Account' {
                $testParameters = $getTargetResourceParameters + @{
                    ActionExecutable    = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType        = 'Once'
                    RepeatInterval      = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration  = (New-TimeSpan -Hours 8).ToString()
                    BuiltInAccount      = 'NETWORK SERVICE'
                    ExecuteAsCredential = [pscredential]::new('DEMO\WrongUser', (ConvertTo-SecureString 'ExamplePassword' -AsPlainText -Force))
                    Verbose             = $true
                }

                It 'Should Disregard ExecuteAsCredential and Set User to the BuiltInAccount' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Register-ScheduledTask -Times 1 -Scope It -ParameterFilter {
                        $User -ieq ('NT AUTHORITY\' + $testParameters['BuiltInAccount'])
                    }
                }

                $testParameters.Add('LogonType', 'Password')

                It 'Should overwrite LogonType to "ServiceAccount"' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Register-ScheduledTask -Times 1 -Scope It -ParameterFilter {
                        $Inputobject.Principal.LogonType -ieq 'ServiceAccount'
                    }
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
                            UserId = $testParameters.BuiltInAccount
                            LogonType = 'ServiceAccount'
                        }
                    }
                }

                $testParameters.LogonType = 'Password'

                It 'Should return true when BuiltInAccount set even if LogonType parameter different' {
                    Test-TargetResource @testParameters | Should -BeTrue
                }
            }

            Context 'When a scheduled task is created using a Group Managed Service Account' {
                $testParameters = $getTargetResourceParameters + @{
                    ActionExecutable    = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType        = 'Once'
                    RepeatInterval      = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration  = (New-TimeSpan -Hours 8).ToString()
                    ExecuteAsGMSA       = 'DOMAIN\gMSA$'
                    BuiltInAccount      = 'NETWORK SERVICE'
                    ExecuteAsCredential = [pscredential]::new('DEMO\RightUser', (ConvertTo-SecureString 'ExamplePassword' -AsPlainText -Force))
                    Verbose             = $true
                }

                It 'Should throw expected exception' {
                    $errorRecord = Get-InvalidArgumentRecord -Message $LocalizedData.gMSAandCredentialError -ArgumentName 'ExecuteAsGMSA'

                    { Set-TargetResource @testParameters -ErrorVariable duplicateCredential } | Should -Throw $errorRecord
                    $testParameters.Remove('ExecuteAsCredential')
                    { Set-TargetResource @testParameters -ErrorVariable duplicateCredential } | Should -Throw $errorRecord
                }

                $testParameters.Remove('BuiltInAccount')

                It 'Should call Register-ScheduledTask with the name of the Group Managed Service Account' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Register-ScheduledTask -Times 1 -Scope It -ParameterFilter {
                        $User -eq $null -and  $Inputobject.Principal.UserId -eq $testParameters.ExecuteAsGMSA
                    }
                }

                It 'Should set the LogonType to Password when a Group Managed Service Account is used' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Register-ScheduledTask -Times 1 -Scope It -ParameterFilter {
                        $Inputobject.Principal.Logontype -eq 'Password'
                    }
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
                            UserId = 'gMSA$'
                        }
                    }
                }

                It 'Should return true if the task is in desired state and given gMSA user in DOMAIN\User$ format' {
                    Test-TargetResource @testParameters | Should -BeTrue
                }

                $testParameters.ExecuteAsGMSA = 'gMSA$@domain.fqdn'

                It 'Should return true if the task is in desired state and given gMSA user in UPN format' {
                    Test-TargetResource @testParameters | Should -BeTrue
                }
            }

            Context 'When a scheduled task Group Managed Service Account is changed' {
                $testParameters = $getTargetResourceParameters + @{
                    ActionExecutable    = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType        = 'Once'
                    RepeatInterval      = (New-TimeSpan -Minutes 15).ToString()
                    RepetitionDuration  = (New-TimeSpan -Hours 8).ToString()
                    ExecuteAsGMSA       = 'DOMAIN\gMSA$'
                    Verbose             = $true
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
                            UserId = 'update_gMSA$'
                        }
                    }
                }

                It 'Should return false on Test-TargetResource if the task is not in desired state and given gMSA user in DOMAIN\User$ format' {
                    Test-TargetResource @testParameters | Should -BeFalse
                }

                It 'Should call Set-ScheduledTask using the new Group Managed Service Account' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Set-ScheduledTask -Times 1 -Scope It -ParameterFilter {
                        $Inputobject.Principal.UserId -eq $testParameters.ExecuteAsGMSA
                    }
                }

                It 'Should set the LogonType to Password when a Group Managed Service Account is used' {
                    Set-TargetResource @testParameters
                    Assert-MockCalled -CommandName Set-ScheduledTask -Times 1 -Scope It -ParameterFilter {
                        $Inputobject.Principal.Logontype -eq 'Password'
                    }
                }
            }

            Context 'When a scheduled task is created and synchronize across time zone is disabled' {
                $startTimeString           = '2018-10-01T01:00:00'
                $startTimeStringWithOffset = '2018-10-01T01:00:00' + (Get-Date -Format 'zzz')
                $testParameters = $getTargetResourceParameters + @{
                    ActionExecutable          = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    StartTime                 = Get-Date -Date $startTimeString
                    SynchronizeAcrossTimeZone = $false
                    ScheduleType              = 'Once'
                    Verbose                   = $true
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
                                StartBoundary = $startTimeString
                                CimClass      = @{
                                    CimClassName = 'MSFT_TaskTimeTrigger'
                                }
                            }
                        )
                    }
                }

                It 'Should return the start time in DateTime format and SynchronizeAcrossTimeZone with value false' {
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.StartTime | Should -Be (Get-Date -Date $startTimeString)
                    $result.SynchronizeAcrossTimeZone | Should -BeFalse
                }

                It 'Should return true given that startTime is set correctly' {
                    Test-TargetResource @testParameters | Should -BeTrue
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
                                StartBoundary = $startTimeStringWithOffset
                                CimClass      = @{
                                    CimClassName = 'MSFT_TaskTimeTrigger'
                                }
                            }
                        )
                    }
                }

                It 'Should return false given that the task is configured with synchronize across time zone' {
                    Test-TargetResource @testParameters | Should -BeFalse
                }

                Set-TargetResource @testParameters

                It "Should set task trigger StartBoundary to $startTimeString" {
                    Assert-MockCalled -CommandName Set-ScheduledTask -ParameterFilter {
                        $InputObject.Triggers[0].StartBoundary -eq $startTimeString
                    }
                }
            }

            Context 'When a scheduled task is created and synchronize across time zone is enabled' {
                $startTimeString           = '2018-10-01T01:00:00'
                $startTimeStringWithOffset = '2018-10-01T01:00:00' + (Get-Date -Format 'zzz')
                $testParameters = $getTargetResourceParameters + @{
                    ActionExecutable          = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    StartTime                 = Get-Date -Date $startTimeString
                    SynchronizeAcrossTimeZone = $true
                    ScheduleType              = 'Once'
                    Verbose                   = $true
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
                                StartBoundary = $startTimeStringWithOffset
                                CimClass      = @{
                                    CimClassName = 'MSFT_TaskTimeTrigger'
                                }
                            }
                        )
                    }
                }

                It 'Should return the start time in DateTime format and SynchronizeAcrossTimeZone with value true' {
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.StartTime | Should -Be (Get-Date -Date $startTimeStringWithOffset)
                    $result.SynchronizeAcrossTimeZone | Should -BeTrue
                }

                It 'Should return true given that startTime is set correctly' {
                    Test-TargetResource @testParameters | Should -BeTrue
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
                                StartBoundary = $startTimeString
                                CimClass      = @{
                                    CimClassName = 'MSFT_TaskTimeTrigger'
                                }
                            }
                        )
                    }
                }

                It 'Should return false given that the task is configured with synchronize across time zone disabled' {
                    Test-TargetResource @testParameters | Should -BeFalse
                }

                Set-TargetResource @testParameters

                It "Should set task trigger StartBoundary to $startTimeStringWithOffset" {
                    Assert-MockCalled -CommandName Set-ScheduledTask -ParameterFilter {
                        $InputObject.Triggers[0].StartBoundary -eq $startTimeStringWithOffset
                    }
                }
            }

            Context 'When a scheduled task is configured to SynchronizeAcrossTimeZone and the ScheduleType is not Once, Daily or Weekly' {
                $startTimeString              = '2018-10-01T01:00:00'
                $testParameters = $getTargetResourceParameters + @{
                    ActionExecutable          = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    StartTime                 = Get-Date -Date $startTimeString
                    SynchronizeAcrossTimeZone = $true
                    ScheduleType              = 'AtLogon'
                    Verbose                   = $true
                }

                It 'Should throw when Set-TargetResource is called and SynchronizeAcrossTimeZone is used in combination with an unsupported trigger type' {
                    { Set-TargetResource @testParamers } | Should -Throw
                }
            }

            Context 'When a scheduled task is configured with the ScheduleType AtLogon and is in desired state' {
                $startTimeString = '2018-10-01T01:00:00'
                $testParameters = $getTargetResourceParameters + @{
                    ActionExecutable  = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    StartTime         = Get-Date -Date $startTimeString
                    ScheduleType      = 'AtLogon'
                    Delay             = '00:01:00'
                    Enable            = $true
                    Verbose           = $true
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
                                Delay = 'PT1M'
                                StartBoundary = $startTimeString
                                CimClass      = @{
                                    CimClassName = 'MSFT_TaskLogonTrigger'
                                }
                            }
                        )
                        Settings = [pscustomobject] @{
                            Enabled = $testParameters.Enable
                        }
                    }
                }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Enable | Should -Be $testParameters.Enable
                    $result.Ensure | Should -Be 'Present'
                    $result.StartTime | Should -Be (Get-Date -Date $startTimeString)
                    $result.ScheduleType | Should -Be 'AtLogon'
                    $result.Delay | Should -Be $testParameters.Delay
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParameters | Should -BeTrue
                }
            }

            Context 'When a scheduled task is configured with the ScheduleType AtStartup and is in desired state' {
                $testParameters = $getTargetResourceParameters + @{
                    ActionExecutable  = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    ScheduleType      = 'AtStartup'
                    Delay             = '00:01:00'
                    Enable            = $true
                    Verbose           = $true
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
                                Delay = 'PT1M'
                                StartBoundary = ''
                                CimClass      = @{
                                    CimClassName = 'MSFT_TaskBootTrigger'
                                }
                            }
                        )
                        Settings = [pscustomobject] @{
                            Enabled = $testParameters.Enable
                        }
                    }
                }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Enable | Should -Be $testParameters.Enable
                    $result.Ensure | Should -Be 'Present'
                    $result.ScheduleType | Should -Be 'AtStartup'
                    $result.Delay | Should -Be $testParameters.Delay
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParameters | Should -BeTrue
                }
            }

            Context 'When a scheduled task is configured with a description that contains various forms of whitespace but is in the desired state' {
                <#
                    This test verifies issue #258:
                    https://github.com/PowerShell/ComputerManagementDsc/issues/258
                #>
                $testParameters = $getTargetResourceParameters + @{
                    ActionExecutable  = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
                    Description       = "`t`n`r    test description    `t`n`r"
                    ScheduleType      = 'AtStartup'
                    Delay             = '00:01:00'
                    Enable            = $true
                    Verbose           = $true
                }

                Mock -CommandName Get-ScheduledTask -MockWith {
                    @{
                        TaskName    = $testParameters.TaskName
                        TaskPath    = $testParameters.TaskPath
                        Description = 'test description'
                        Actions   = @(
                            [pscustomobject] @{
                                Execute = $testParameters.ActionExecutable
                            }
                        )
                        Triggers  = @(
                            [pscustomobject] @{
                                Delay = 'PT1M'
                                StartBoundary = ''
                                CimClass      = @{
                                    CimClassName = 'MSFT_TaskBootTrigger'
                                }
                            }
                        )
                        Settings = [pscustomobject] @{
                            Enabled = $testParameters.Enable
                        }
                    }
                }

                It 'Should return the correct values from Get-TargetResource' {
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Description | Should -Be 'test description'
                    $result.Enable | Should -Be $testParameters.Enable
                    $result.Ensure | Should -Be 'Present'
                    $result.ScheduleType | Should -Be 'AtStartup'
                    $result.Delay | Should -Be $testParameters.Delay
                }

                It 'Should return true from the test method' {
                    Test-TargetResource @testParameters | Should -BeTrue
                }
            }
        }

        Describe 'MSFT_ScheduledTask\Test-DateStringContainsTimeZone' {
            Context 'When the date string contains a date without a timezone' {
                It 'Should return $false' {
                    Test-DateStringContainsTimeZone -DateString '2018-10-01T01:00:00' | Should -BeFalse
                }
            }

            Context 'When the date string contains a date with a timezone' {
                It 'Should return $true' {
                    Test-DateStringContainsTimeZone -DateString ('2018-10-01T01:00:00' + (Get-Date -Format 'zzz')) | Should -BeTrue
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
