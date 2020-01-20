$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'DSC_VirtualMemory'

try
{
    Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
}
catch [System.IO.FileNotFoundException]
{
    throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
}

$script:testEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -ResourceType 'Mof' `
    -TestType 'Integration'

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

# Begin Testing
try
{
    Describe 'VirtualMemory Integration Tests' {
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
}
finally
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
