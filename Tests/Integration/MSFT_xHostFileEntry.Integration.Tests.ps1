$Global:DSCModuleName      = 'xComputerManagement'
$Global:DSCResourceName    = 'MSFT_xHostFileEntry'

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
#endregion

# Begin Testing
try
{
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($Global:DSCResourceName).config.ps1"
    . $ConfigFile
    
    #region Pester Tests
    Describe $"$($Global:DSCResourceName)_Integration" {
        
        Context "A host entry doesn't exist, and should" {
            $CurrentConfig = "xHostFileEntry_Add"
            It "should compile a MOF file without error" {
                {
                    xHostFileEntry_Add -OutputPath (Join-Path $TestEnvironment.WorkingFolder $CurrentConfig)
                } | Should Not Throw
            }
            
            It "should apply the MOF correctly" {
                {
                    Start-DscConfiguration -Path (Join-Path $TestEnvironment.WorkingFolder $CurrentConfig) -ComputerName localhost -Wait -Verbose -Force
                } | Should Not Throw
            }
            
            It "should return a compliant state after being applied" {
                Test-DscConfiguration -ComputerName localhost -Path (Join-Path $TestEnvironment.WorkingFolder $CurrentConfig) | Should Be $true
            }
            
            It "should return Get-DscConfiguration without error" {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
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
