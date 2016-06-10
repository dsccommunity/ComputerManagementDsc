[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param(
)

$Global:DSCModuleName      = 'xComputerManagement'
$Global:DSCResourceName    = 'MSFT_xScheduledTask'

#region HEADER
# Unit Test Template Version: 1.1.0
[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Unit 

# Begin Testing
try
{
    #region Pester Tests

    InModuleScope $Global:DSCResourceName {

        Describe $Global:DSCResourceName {
            
            Mock Register-ScheduledTask { }
            Mock Set-ScheduledTask { }
            Mock Unregister-ScheduledTask { }
            
            Context "No scheduled task exists, but it should" {
                $testParams = @{
                    TaskName = "Test task"
                    ActionExecutable = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
                    ScheduleType = "Minutes"
                    RepeatInterval = 15
                }
                
                Mock Get-ScheduledTask { return $null }

                It "should return absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                }
                
                It "should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }
                
                It "should create the scheduled task in the set method" {
                    Set-TargetResource @testParams
                }
            }
            
            Context "A scheduled task exists, but it shouldn't" {
                $testParams = @{
                    TaskName = "Test task"
                    ActionExecutable = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
                    ScheduleType = "Minutes"
                    RepeatInterval = 15
                    Ensure = "Absent"
                }
                
                Mock Get-ScheduledTask { return @{
                    Name = $testParams.TaskName
                    Path = $testParams.TaskPath
                    Actions = @(@{
                        Execute = $testParams.ActionExecutable
                    })
                    Triggers = @(@{
                        Repetition = @{
                            Duration = $null
                            Interval = "PT$($testParams.RepeatInterval)M"
                        }
                    })
                    Principal = @{
                        UserId = "SYSTEM"
                    }
                } }
                
                It "should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present"
                }
                
                It "should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }
                
                It "should remove the scheduled task in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Unregister-ScheduledTask
                }
            }
            
            Context "A scheduled task doesnt exist, and it shouldn't" {
                $testParams = @{
                    TaskName = "Test task"
                    ActionExecutable = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
                    ScheduleType = "Minutes"
                    RepeatInterval = 15
                    Ensure = "Absent"
                }
                
                Mock Get-ScheduledTask { return $null }
                
                It "should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                }
                
                It "should return true from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }
            }
            
            Context "A scheduled task with minutes based repetition exists, but has the wrong settings" {
                $testParams = @{
                    TaskName = "Test task"
                    ActionExecutable = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
                    ScheduleType = "Minutes"
                    RepeatInterval = 15
                }
                
                Mock Get-ScheduledTask { return @{
                    Name = $testParams.TaskName
                    Path = $testParams.TaskPath
                    Actions = @(@{
                        Execute = $testParams.ActionExecutable
                    })
                    Triggers = @(@{
                        Repetition = @{
                            Duration = $null
                            Interval = "PT$(($testParams.RepeatInterval) + 1)M"
                        }
                    })
                    Principal = @{
                        UserId = "SYSTEM"
                    }
                } }
                
                It "should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present"
                }
                
                It "should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }
                
                It "should update the scheduled task in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-ScheduledTask
                }
            }
            
            Context "A scheduled task with minutes based repetition exists and has the correct settings" {
                $testParams = @{
                    TaskName = "Test task"
                    ActionExecutable = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
                    ScheduleType = "Minutes"
                    RepeatInterval = 15
                }
                
                Mock Get-ScheduledTask { return @{
                    Name = $testParams.TaskName
                    Path = $testParams.TaskPath
                    Actions = @(@{
                        Execute = $testParams.ActionExecutable
                    })
                    Triggers = @(@{
                        Repetition = @{
                            Duration = $null
                            Interval = "PT$($testParams.RepeatInterval)M"
                        }
                    })
                    Principal = @{
                        UserId = "SYSTEM"
                    }
                } }
                
                It "should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present"
                }
                
                It "should return true from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }
            }
            
            Context "A scheduled task with hourly based repetition exists, but has the wrong settings" {
                $testParams = @{
                    TaskName = "Test task"
                    ActionExecutable = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
                    ScheduleType = "Hourly"
                    RepeatInterval = 4
                }
                
                Mock Get-ScheduledTask { return @{
                    Name = $testParams.TaskName
                    Path = $testParams.TaskPath
                    Actions = @(@{
                        Execute = $testParams.ActionExecutable
                    })
                    Triggers = @(@{
                        Repetition = @{
                            Duration = $null
                            Interval = "PT$(($testParams.RepeatInterval) + 1)H"
                        }
                    })
                    Principal = @{
                        UserId = "SYSTEM"
                    }
                } }
                
                It "should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present"
                }
                
                It "should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }
                
                It "should update the scheduled task in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-ScheduledTask
                }
            }
            
            Context "A scheduled task with hourly based repetition exists and has the correct settings" {
                $testParams = @{
                    TaskName = "Test task"
                    ActionExecutable = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
                    ScheduleType = "Hourly"
                    RepeatInterval = 4
                }
                
                Mock Get-ScheduledTask { return @{
                    Name = $testParams.TaskName
                    Path = $testParams.TaskPath
                    Actions = @(@{
                        Execute = $testParams.ActionExecutable
                    })
                    Triggers = @(@{
                        Repetition = @{
                            Duration = $null
                            Interval = "PT$($testParams.RepeatInterval)H"
                        }
                    })
                    Principal = @{
                        UserId = "SYSTEM"
                    }
                } }
                
                It "should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present"
                }
                
                It "should return true from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }
            }
            
            Context "A scheduled task with daily based repetition exists, but has the wrong settings" {
                $testParams = @{
                    TaskName = "Test task"
                    ActionExecutable = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
                    ScheduleType = "Daily"
                    RepeatInterval = 3
                }
                
                Mock Get-ScheduledTask { return @{
                    Name = $testParams.TaskName
                    Path = $testParams.TaskPath
                    Actions = @(@{
                        Execute = $testParams.ActionExecutable
                    })
                    Triggers = @(@{
                        Repetition = @{
                            Duration = $null
                            Interval = "P$(($testParams.RepeatInterval) + 1)D"
                        }
                    })
                    Principal = @{
                        UserId = "SYSTEM"
                    }
                } }
                
                It "should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present"
                }
                
                It "should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }
                
                It "should update the scheduled task in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-ScheduledTask
                }
            }
            
            Context "A scheduled task with daily based repetition exists and has the correct settings" {
                $testParams = @{
                    TaskName = "Test task"
                    ActionExecutable = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
                    ScheduleType = "Daily"
                    RepeatInterval = 3
                }
                
                Mock Get-ScheduledTask { return @{
                    Name = $testParams.TaskName
                    Path = $testParams.TaskPath
                    Actions = @(@{
                        Execute = $testParams.ActionExecutable
                    })
                    Triggers = @(@{
                        Repetition = @{
                            Duration = $null
                            Interval = "P$($testParams.RepeatInterval)D"
                        }
                    })
                    Principal = @{
                        UserId = "SYSTEM"
                    }
                } }
                
                It "should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present"
                }
                
                It "should return true from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }
            }
            
            Context "A scheduled task exists and is configured with the wrong execution account" {
                $testParams = @{
                    TaskName = "Test task"
                    ActionExecutable = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
                    ScheduleType = "Minutes"
                    RepeatInterval = 15
                    ExecuteAsCredential = New-Object System.Management.Automation.PSCredential ("DEMO\RightUser", (ConvertTo-SecureString "ExamplePassword" -AsPlainText -Force))
                }
                
                Mock Get-ScheduledTask { return @{
                    Name = $testParams.TaskName
                    Path = $testParams.TaskPath
                    Actions = @(@{
                        Execute = $testParams.ActionExecutable
                    })
                    Triggers = @(@{
                        Repetition = @{
                            Duration = $null
                            Interval = "PT$($testParams.RepeatInterval)M"
                        }
                    })
                    Principal = @{
                        UserId = "WrongUser"
                    }
                } }
                
                It "should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present"
                }
                
                It "should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }
                
                It "should update the scheduled task in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-ScheduledTask
                }
            }
            
            Context "A scheduled task exists and is configured with the wrong working directory" {
                $testParams = @{
                    TaskName = "Test task"
                    ActionExecutable = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
                    ActionWorkingPath = "C:\Example"
                    ScheduleType = "Minutes"
                    RepeatInterval = 15
                }
                
                Mock Get-ScheduledTask { return @{
                    Name = $testParams.TaskName
                    Path = $testParams.TaskPath
                    Actions = @(@{
                        Execute = $testParams.ActionExecutable
                        WorkingDirectory = "C:\Wrong"
                    })
                    Triggers = @(@{
                        Repetition = @{
                            Duration = $null
                            Interval = "PT$($testParams.RepeatInterval)M"
                        }
                    })
                    Principal = @{
                        UserId = "SYSTEM"
                    }
                } }
                
                It "should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present"
                }
                
                It "should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }
                
                It "should update the scheduled task in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-ScheduledTask
                }
            }
            
            Context "A scheduled task exists and is configured with the wrong executable arguments" {
                $testParams = @{
                    TaskName = "Test task"
                    ActionExecutable = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
                    ActionArguments = "-File `"C:\something\right.ps1`""
                    ScheduleType = "Minutes"
                    RepeatInterval = 15
                }
                
                Mock Get-ScheduledTask { return @{
                    Name = $testParams.TaskName
                    Path = $testParams.TaskPath
                    Actions = @(@{
                        Execute = $testParams.ActionExecutable
                        Arguments = "-File `"C:\something\wrong.ps1`""
                    })
                    Triggers = @(@{
                        Repetition = @{
                            Duration = $null
                            Interval = "PT$($testParams.RepeatInterval)M"
                        }
                    })
                    Principal = @{
                        UserId = "SYSTEM"
                    }
                } }
                
                It "should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present"
                }
                
                It "should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }
                
                It "should update the scheduled task in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-ScheduledTask
                }
            }
            
            Context "A scheduled task is enabled and should be disabled" {
                $testParams = @{
                    TaskName = "Test task"
                    ActionExecutable = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
                    ScheduleType = "Minutes"
                    RepeatInterval = 15
                    Enable = $false
                }
                
                Mock Get-ScheduledTask { return @{
                    Name = $testParams.TaskName
                    Path = $testParams.TaskPath
                    Actions = @(@{
                        Execute = $testParams.ActionExecutable
                        Arguments = $testParams.Arguments
                    })
                    Triggers = @(@{
                        Repetition = @{
                            Duration = $null
                            Interval = "PT$($testParams.RepeatInterval)M"
                        }
                    })
                    Settings = @(@{
                        Enabled = $true
                    })
                    Principal = @{
                        UserId = "SYSTEM"
                    }
                    } }
                
                It "should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present"
                }
                
                It "should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }
                
                It "should update the scheduled task in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-ScheduledTask
                }
            
            }
            
            Context "A scheduled task is enabled and has the correct settings" {
                $testParams = @{
                    TaskName = "Test task"
                    ActionExecutable = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
                    ScheduleType = "Minutes"
                    RepeatInterval = 15
                    Enable = $true
                }
                
                Mock Get-ScheduledTask { return @{
                    Name = $testParams.TaskName
                    Path = $testParams.TaskPath
                    Actions = @(@{
                        Execute = $testParams.ActionExecutable
                        Arguments = $testParams.Arguments
                    })
                    Triggers = @(@{
                        Repetition = @{
                            Duration = $null
                            Interval = "PT$($testParams.RepeatInterval)M"
                        }
                    })
                    Settings = @(@{
                        Enabled = $true
                    })
                    Principal = @{
                        UserId = "SYSTEM"
                    }
                } }
                
                It "should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present"
                }
                
                It "should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }
            }
            
            Context "A scheduled task is disabled and has the correct settings" {
                $testParams = @{
                    TaskName = "Test task"
                    ActionExecutable = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
                    ScheduleType = "Minutes"
                    RepeatInterval = 15
                    Enable = $false
                }
                
                Mock Get-ScheduledTask { return @{
                    Name = $testParams.TaskName
                    Path = $testParams.TaskPath
                    Actions = @(@{
                        Execute = $testParams.ActionExecutable
                        Arguments = $testParams.Arguments
                    })
                    Triggers = @(@{
                        Repetition = @{
                            Duration = $null
                            Interval = "PT$($testParams.RepeatInterval)M"
                        }
                    })
                    Settings = @(@{
                        Enabled = $false
                    })
                    Principal = @{
                        UserId = "SYSTEM"
                    }
                } }
                
                It "should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present"
                }
                
                It "should return true from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }
            }
            
            Context "A scheduled task is disabled but should be enabled" {
                $testParams = @{
                    TaskName = "Test task"
                    ActionExecutable = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
                    ScheduleType = "Minutes"
                    RepeatInterval = 15
                    Enable = $true
                }
                
                Mock Get-ScheduledTask { return @{
                    Name = $testParams.TaskName
                    Path = $testParams.TaskPath
                    Actions = @(@{
                        Execute = $testParams.ActionExecutable
                        Arguments = $testParams.Arguments
                    })
                    Triggers = @(@{
                        Repetition = @{
                            Duration = $null
                            Interval = "PT$($testParams.RepeatInterval)M"
                        }
                    })
                    Settings = @(@{
                        Enabled = $false
                    })
                    Principal = @{
                        UserId = "SYSTEM"
                    }
                } }
                
                It "should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present"
                }
                
                It "should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }
                
                It "should update the scheduled task in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Set-ScheduledTask
                }
            }
            
            Context "A Scheduled task exists, is disabled, and the optional parameter enable is not specified" -Fixture {
                $testParams = @{
                    TaskName = "Test task"
                    ActionExecutable = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
                    ScheduleType = "Minutes"
                    RepeatInterval = 15
                }
                
                Mock Get-ScheduledTask { return @{
                    Name = $testParams.TaskName
                    Path = $testParams.TaskPath
                    Actions = @(@{
                        Execute = $testParams.ActionExecutable
                        Arguments = $testParams.Arguments
                    })
                    Triggers = @(@{
                        Repetition = @{
                            Duration = $null
                            Interval = "PT$($testParams.RepeatInterval)M"
                        }
                    })
                    Settings = @(@{
                        Enabled = $false
                    })
                    Principal = @{
                        UserId = "SYSTEM"
                    }
                } }
                
                It "should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present"
                }
                
                It "Should return true from the test method" {
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
