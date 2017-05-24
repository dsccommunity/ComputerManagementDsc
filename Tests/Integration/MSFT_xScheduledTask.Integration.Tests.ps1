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
# Begin Testing
try
{
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($Global:DSCResourceName).config.ps1"
    . $ConfigFile
    
    #region Pester Tests
    Describe $Global:DSCResourceName {

        $contexts = @{
            Once      = 'xScheduledTaskOnce'
            Daily     = 'xScheduledTaskDaily'
            Weekly    = 'xScheduledTaskWeekly'
            AtLogon   = 'xScheduledTaskLogon'
            AtStartup = 'xScheduledTaskStartup'
        }
        
        foreach ($contextInfo in $contexts.GetEnumerator())
        {
            Context "[$($contextInfo.Key)] No scheduled task exists but it should" {
                $CurrentConfig = '{0}Add' -f $contextInfo.Value
                $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
                $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')
            
                It 'should compile and apply the MOF without throwing' {
                    {
                        . $CurrentConfig -OutputPath $ConfigDir
                    } | Should Not Throw
                }
            
                It 'should apply the MOF correctly' {
                    {
                        Start-DscConfiguration -Path $ConfigDir -Wait -Force
                    } | Should Not Throw
                }
            
                It 'should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should be $true 
                }
            }

            Context "[$($contextInfo.Key)] A scheduled task exists with the wrong settings" {
                $CurrentConfig = '{0}Mod' -f $contextInfo.Value
                $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
                $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')
            
                It 'should compile and apply the MOF without throwing' {
                    {
                        . $CurrentConfig -OutputPath $ConfigDir
                    } | Should Not Throw
                }
            
                It 'should apply the MOF correctly' {
                    {
                        Start-DscConfiguration -Path $ConfigDir -Wait -Force
                    } | Should Not Throw
                }
            
                It 'should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should be $true 
                }
            }

            Context "[$($contextInfo.Key)] A scheduled tasks exists but it should not" {
                $CurrentConfig = '{0}Del' -f $contextInfo.Value
                $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
                $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')
            
                It 'should compile and apply the MOF without throwing' {
                    {
                        . $CurrentConfig -OutputPath $ConfigDir
                    } | Should Not Throw
                }
            
                It 'should apply the MOF correctly' {
                    {
                        Start-DscConfiguration -Path $ConfigDir -Wait -Force
                    } | Should Not Throw
                }
            
                It 'should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should be $true 
                }
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
