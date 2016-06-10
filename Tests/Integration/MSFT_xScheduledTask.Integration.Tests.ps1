#Requires -Version 5.0
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
    -TestType Integration 

# Begin Testing
try
{
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($Global:DSCResourceName).config.ps1"
    . $ConfigFile
    
    #region Pester Tests
    Describe $Global:DSCResourceName {
        
        Context "No scheduled task exists, but it should" {
            $CurrentConfig = "xScheduledTask_Add"
            $ConfigDir = (Join-Path $TestEnvironment.WorkingFolder $CurrentConfig)
            $ConfigMof = (Join-Path $ConfigDir "localhost.mof")
            
            It "should compile a MOF file without error" {
                {
                    . $CurrentConfig -OutputPath $ConfigDir
                } | Should Not Throw
            }
            
            It "should apply the MOF correctly" {
                {
                    Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                } | Should Not Throw
            }
            
            It "should return a compliant state after being applied" {
                (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should be $true 
            }
        }
        
        Context "A scheduled task with minutes based repetition exists, but has the wrong settings" {
            $CurrentConfig = "xScheduledTask_Edit1"
            $ConfigDir = (Join-Path $TestEnvironment.WorkingFolder $CurrentConfig)
            $ConfigMof = (Join-Path $ConfigDir "localhost.mof")
            
            It "should compile a MOF file without error" {
                {
                    . $CurrentConfig -OutputPath $ConfigDir
                } | Should Not Throw
            }
            
            It "should apply the MOF correctly" {
                {
                    Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                } | Should Not Throw
            }
            
            It "should return a compliant state after being applied" {
                (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should be $true 
            }
        }
        
        Context "A scheduled task with hourly based repetition exists, but has the wrong settings" {
            $CurrentConfig = "xScheduledTask_Edit2"
            $ConfigDir = (Join-Path $TestEnvironment.WorkingFolder $CurrentConfig)
            $ConfigMof = (Join-Path $ConfigDir "localhost.mof")
            
            It "should compile a MOF file without error" {
                {
                    . $CurrentConfig -OutputPath $ConfigDir
                } | Should Not Throw
            }
            
            It "should apply the MOF correctly" {
                {
                    Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                } | Should Not Throw
            }
            
            It "should return a compliant state after being applied" {
                (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should be $true 
            }
        }
        
        Context "A scheduled task with daily based repetition exists, but has the wrong settings" {
            $CurrentConfig = "xScheduledTask_Edit3"
            $ConfigDir = (Join-Path $TestEnvironment.WorkingFolder $CurrentConfig)
            $ConfigMof = (Join-Path $ConfigDir "localhost.mof")
            
            It "should compile a MOF file without error" {
                {
                    . $CurrentConfig -OutputPath $ConfigDir
                } | Should Not Throw
            }
            
            It "should apply the MOF correctly" {
                {
                    Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                } | Should Not Throw
            }
            
            It "should return a compliant state after being applied" {
                (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should be $true 
            }
        }
        
        Context "A scheduled task exists and is configured with the wrong working directory" {
            $CurrentConfig = "xScheduledTask_Edit4"
            $ConfigDir = (Join-Path $TestEnvironment.WorkingFolder $CurrentConfig)
            $ConfigMof = (Join-Path $ConfigDir "localhost.mof")
            
            It "should compile a MOF file without error" {
                {
                    . $CurrentConfig -OutputPath $ConfigDir
                } | Should Not Throw
            }
            
            It "should apply the MOF correctly" {
                {
                    Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                } | Should Not Throw
            }
            
            It "should return a compliant state after being applied" {
                (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should be $true 
            }
        }
        
        Context "A scheduled task exists and is configured with the wrong executable arguments" {
            $CurrentConfig = "xScheduledTask_Edit5"
            $ConfigDir = (Join-Path $TestEnvironment.WorkingFolder $CurrentConfig)
            $ConfigMof = (Join-Path $ConfigDir "localhost.mof")
            
            It "should compile a MOF file without error" {
                {
                    . $CurrentConfig -OutputPath $ConfigDir
                } | Should Not Throw
            }
            
            It "should apply the MOF correctly" {
                {
                    Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                } | Should Not Throw
            }
            
            It "should return a compliant state after being applied" {
                (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should be $true 
            }
        }
        
        Context "A scheduled task exists, but it shouldn't" {
            $CurrentConfig = "xScheduledTask_Remove"
            $ConfigDir = (Join-Path $TestEnvironment.WorkingFolder $CurrentConfig)
            $ConfigMof = (Join-Path $ConfigDir "localhost.mof")
            
            It "should compile a MOF file without error" {
                {
                    . $CurrentConfig -OutputPath $ConfigDir
                } | Should Not Throw
            }
            
            It "should apply the MOF correctly" {
                {
                    Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                } | Should Not Throw
            }
            
            It "should return a compliant state after being applied" {
                (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should be $true 
            }
        }
        
        Context "A scheduled task exists, and should be enabled" {
            $CurrentConfig = "xScheduledTask_Enable"
            $ConfigDir = (Join-Path $TestEnvironment.WorkingFolder $CurrentConfig)
            $ConfigMof = (Join-Path $ConfigDir "localhost.mof")
            
            It "should compile a MOF file without error" {
                {
                    . $CurrentConfig -OutputPath $ConfigDir
                } | Should Not Throw
            }
            
            It "should apply the MOF correctly" {
                {
                    Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                } | Should Not Throw
            }
            
            It "should return a compliant state after being applied" {
                (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should be $true 
            }
        }
        
        Context "A scheduled task exists, and should be disabled" {
            $CurrentConfig = "xScheduledTask_Disable"
            $ConfigDir = (Join-Path $TestEnvironment.WorkingFolder $CurrentConfig)
            $ConfigMof = (Join-Path $ConfigDir "localhost.mof")
            
            It "should compile a MOF file without error" {
                {
                    . $CurrentConfig -OutputPath $ConfigDir
                } | Should Not Throw
            }
            
            It "should apply the MOF correctly" {
                {
                    Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                } | Should Not Throw
            }
            
            It "should return a compliant state after being applied" {
                (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should be $true 
            }
        }
        
        AfterEach {
            Remove-DscConfigurationDocument -Stage Current, Pending, Previous -Force -Confirm:$false -WarningAction SilentlyContinue
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
