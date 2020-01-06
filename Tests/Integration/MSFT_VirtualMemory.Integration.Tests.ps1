#region HEADER
$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'MSFT_VirtualMemory'

# Integration Test Template Version: 1.3.3
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
    -TestType Integration
#endregion

# Using try/finally to always cleanup.
try
{
    #region Integration Tests
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configFile

    Describe "$($script:dscResourceName)_Integration" {

        Context 'Set page file to automatically managed' {
            $CurrentConfig = 'setToAuto'
            $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
            $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')

            It 'Should compile a MOF file without error' {
                {
                    . $CurrentConfig -OutputPath $ConfigDir
                } | Should -Not -Throw
            }

            It 'Should apply the MOF correctly' {
                {
                    Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                } | Should -Not -Throw
            }

            It 'Should return a compliant state after being applied' {
                (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should -BeTrue
            }
        }

        Context 'Set page file to custom size' {
            $CurrentConfig = 'setToCustom'
            $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
            $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')

            It 'Should compile a MOF file without error' {
                {
                    . $CurrentConfig -OutputPath $ConfigDir
                } | Should -Not -Throw
            }

            It 'Should apply the MOF correctly' {
                {
                    Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                } | Should -Not -Throw
            }

            It 'Should return a compliant state after being applied' {
                (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should -BeTrue
            }
        }

        Context 'Set page file to system managed' {
            $CurrentConfig = 'setToSystemManaged'
            $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
            $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')

            It 'Should compile a MOF file without error' {
                {
                    . $CurrentConfig -OutputPath $ConfigDir
                } | Should -Not -Throw
            }

            It 'Should apply the MOF correctly' {
                {
                    Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                } | Should -Not -Throw
            }

            It 'Should return a compliant state after being applied' {
                (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should -BeTrue
            }
        }

        Context 'Set page file to none' {
            $CurrentConfig = 'setToNone'
            $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
            $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')

            It 'Should compile a MOF file without error' {
                {
                    . $CurrentConfig -OutputPath $ConfigDir
                } | Should -Not -Throw
            }

            It 'Should apply the MOF correctly' {
                {
                    Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                } | Should -Not -Throw
            }

            It 'Should return a compliant state after being applied' {
                (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should -BeTrue
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
