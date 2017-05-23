#Requires -Version 5.0
$Global:DSCModuleName      = 'xComputerManagement'
$Global:DSCResourceName    = 'MSFT_xScheduledTask'
#region HEADER
# Integration Test Template Version: 1.1.1
[String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Integration

#endregion
# Begin Testing
try
{
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($Global:DSCResourceName).config.ps1"
    . $ConfigFile
    
    #region Pester Tests
    Describe $Global:DSCResourceName {
        
        #region Schedule type once
        Context '[Once] No scheduled task exists but it should' {
            $CurrentConfig = 'xScheduledTaskOnceAdd'
            $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
            $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')
            
            It 'should compile and apply the MOF without throwing' {
                {
                    . $CurrentConfig -OutputPath $ConfigDir
                } | Should Not Throw
            }
            
            It 'should apply the MOF correctly' {
                {
                    Start-DscConfiguration -Path $ConfigDir -Verbose -Wait -Force
                } | Should Not Throw
            }
            
            It 'should return a compliant state after being applied' {
                (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should be $true 
            }
        }

        Context '[Once] A scheduled task exists with the wrong settings'{
            $CurrentConfig = 'xScheduledTaskOnceMod'
            $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
            $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')
            
            It 'should compile and apply the MOF without throwing' {
                {
                    . $CurrentConfig -OutputPath $ConfigDir
                } | Should Not Throw
            }
            
            It 'should apply the MOF correctly' {
                {
                    Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                } | Should Not Throw
            }
            
            It 'should return a compliant state after being applied' {
                (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should be $true 
            }
        }

        Context '[Once] A scheduled tasks exists but it should not' {
            $CurrentConfig = 'xScheduledTaskOnceDel'
            $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
            $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')
            
            It 'should compile and apply the MOF without throwing' {
                {
                    . $CurrentConfig -OutputPath $ConfigDir
                } | Should Not Throw
            }
            
            It 'should apply the MOF correctly' {
                {
                    Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                } | Should Not Throw
            }
            
            It 'should return a compliant state after being applied' {
                (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should be $true 
            }
        }
        #endregion

        #region Schedule type daily
        Context '[Daily] No scheduled task exists but it should'{
            $CurrentConfig = 'xScheduledTaskDailyAdd'
            $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
            $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')
            
            It 'should compile and apply the MOF without throwing' {
                {
                    . $CurrentConfig -OutputPath $ConfigDir
                } | Should Not Throw
            }
            
            It 'should apply the MOF correctly' {
                {
                    Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                } | Should Not Throw
            }
            
            It 'should return a compliant state after being applied' {
                (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should be $true 
            }
        }

        Context '[Daily] A scheduled task exists with the wrong settings' {
            $CurrentConfig = 'xScheduledTaskDailyMod'
            $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
            $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')
            
            It 'should compile and apply the MOF without throwing' {
                {
                    . $CurrentConfig -OutputPath $ConfigDir
                } | Should Not Throw
            }
            
            It 'should apply the MOF correctly' {
                {
                    Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                } | Should Not Throw
            }
            
            It 'should return a compliant state after being applied' {
                (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should be $true 
            }
        }

        Context '[Daily] A scheduled tasks exists but it should not' {
            $CurrentConfig = 'xScheduledTaskDailyDel'
            $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
            $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')
            
            It 'should compile and apply the MOF without throwing' {
                {
                    . $CurrentConfig -OutputPath $ConfigDir
                } | Should Not Throw
            }
            
            It 'should apply the MOF correctly' {
                {
                    Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                } | Should Not Throw
            }
            
            It 'should return a compliant state after being applied' {
                (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should be $true 
            }
        }
        #endregion
        
        #region Schedule type weekly
        Context '[Weekly] No scheduled task exists but it should'{
            $CurrentConfig = 'xScheduledTaskWeeklyAdd'
            $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
            $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')
            
            It 'should compile and apply the MOF without throwing' {
                {
                    . $CurrentConfig -OutputPath $ConfigDir
                } | Should Not Throw
            }
            
            It 'should apply the MOF correctly' {
                {
                    Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                } | Should Not Throw
            }
            
            It 'should return a compliant state after being applied' {
                (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should be $true 
            }
        }

        Context '[Weekly] A scheduled task exists with the wrong settings' {
            $CurrentConfig = 'xScheduledTaskWeeklyMod'
            $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
            $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')
            
            It 'should compile and apply the MOF without throwing' {
                {
                    . $CurrentConfig -OutputPath $ConfigDir
                } | Should Not Throw
            }
            
            It 'should apply the MOF correctly' {
                {
                    Start-DscConfiguration -Path $ConfigDir -Wait -Force -Verbose
                } | Should Not Throw
            }
            
            It 'should return a compliant state after being applied' {
                (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should be $true 
            }
        }

        Context '[Weekly] A scheduled tasks exists but it should not' {
            $CurrentConfig = 'xScheduledTaskWeeklyDel'
            $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
            $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')
            
            It 'should compile and apply the MOF without throwing' {
                {
                    . $CurrentConfig -OutputPath $ConfigDir
                } | Should Not Throw
            }
            
            It 'should apply the MOF correctly' {
                {
                    Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                } | Should Not Throw
            }
            
            It 'should return a compliant state after being applied' {
                (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should be $true 
            }
        }
        #endregion
        
        #region Schedule type atlogon
        Context '[AtLogon] No scheduled task exists but it should' {
            $CurrentConfig = 'xScheduledTaskLogonAdd'
            $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
            $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')
            
            It 'should compile and apply the MOF without throwing' {
                {
                    . $CurrentConfig -OutputPath $ConfigDir
                } | Should Not Throw
            }
            
            It 'should apply the MOF correctly' {
                {
                    Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                } | Should Not Throw
            }
            
            It 'should return a compliant state after being applied' {
                (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should be $true 
            }
        }

        Context '[AtLogon] A scheduled task exists with the wrong settings' {
            $CurrentConfig = 'xScheduledTaskLogonMod'
            $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
            $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')
            
            It 'should compile and apply the MOF without throwing' {
                {
                    . $CurrentConfig -OutputPath $ConfigDir
                } | Should Not Throw
            }
            
            It 'should apply the MOF correctly' {
                {
                    Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                } | Should Not Throw
            }
            
            It 'should return a compliant state after being applied' {
                (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should be $true 
            }
        }

        Context '[AtLogon] A scheduled tasks exists but it should not' {
            $CurrentConfig = 'xScheduledTaskLogonDel'
            $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
            $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')
            
            It 'should compile and apply the MOF without throwing' {
                {
                    . $CurrentConfig -OutputPath $ConfigDir
                } | Should Not Throw
            }
            
            It 'should apply the MOF correctly' {
                {
                    Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                } | Should Not Throw
            }
            
            It 'should return a compliant state after being applied' {
                (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should be $true 
            }
        }
        #endregion
        
        #region Schedule type atstartup
        Context '[AtStartup] No scheduled task exists but it should' {

            $CurrentConfig = 'xScheduledTaskStartupAdd'
            $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
            $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')
            
            It 'should compile and apply the MOF without throwing' {
                {
                    . $CurrentConfig -OutputPath $ConfigDir
                } | Should Not Throw
            }
            
            It 'should apply the MOF correctly' {
                {
                    Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                } | Should Not Throw
            }
            
            It 'should return a compliant state after being applied' {
                (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should be $true 
            }
        }

        Context '[AtStartup] A scheduled task exists with the wrong settings' {

            $CurrentConfig = 'xScheduledTaskStartupMod'
            $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
            $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')
            
            It 'should compile and apply the MOF without throwing' {
                {
                    . $CurrentConfig -OutputPath $ConfigDir
                } | Should Not Throw
            }
            
            It 'should apply the MOF correctly' {
                {
                    Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                } | Should Not Throw
            }
            
            It 'should return a compliant state after being applied' {
                (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should be $true 
            }
        }

        Context '[AtStartup] A scheduled tasks exists but it should not' {
            $CurrentConfig = 'xScheduledTaskStartupDel'
            $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
            $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')
            
            It 'should compile and apply the MOF without throwing' {
                {
                    . $CurrentConfig -OutputPath $ConfigDir
                } | Should Not Throw
            }
            
            It 'should apply the MOF correctly' {
                {
                    Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                } | Should Not Throw
            }
            
            It 'should return a compliant state after being applied' {
                (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should be $true 
            }
        }
        #endregion        
    }
    #endregion
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
