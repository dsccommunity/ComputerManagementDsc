$script:DSCModuleName      = 'xComputerManagement' 
$script:DSCResourceName    = 'MSFT_xVirtualMemory' 

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
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Integration

#endregion

# Using try/finally to always cleanup.
try
{
    #region Integration Tests
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $configFile

    Describe "$($script:DSCResourceName)_Integration" {
    
        Context "Set page file to automatically managed" {
            $CurrentConfig = "setToAuto"
            $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
            $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath "localhost.mof")
            
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

        Context "Set page file to custom size" {
            $CurrentConfig = "setToCustom"
            $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
            $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath "localhost.mof")
            
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

        Context "Set page file to system managed" {
            $CurrentConfig = "setToSystemManaged"
            $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
            $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath "localhost.mof")
            
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

        Context "Set page file to none" {
            $CurrentConfig = "setToNone"
            $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
            $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath "localhost.mof")
            
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
    }
}
finally
{
    #region FOOTER

    Restore-TestEnvironment -TestEnvironment $TestEnvironment

    #endregion
}

