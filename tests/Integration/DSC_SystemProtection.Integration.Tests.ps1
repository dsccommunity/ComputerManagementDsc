$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'DSC_SystemProtection'

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
    Describe 'SystemProtection Integration Tests' {
        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile

        Describe "$($script:dscResourceName)_Integration" {
            Context 'When enabling system protection for Drive C' {
                $currentConfig = 'DSC_SystemProtection_EnableDriveC'
                $configDir = (Join-Path -Path $TestDrive -ChildPath $currentConfig)
                $configMof = (Join-Path -Path $configDir -ChildPath 'localhost.mof')

                It 'Should compile the MOF without throwing' {
                    {
                        . $currentConfig -OutputPath $configDir
                    } | Should -Not -Throw
                }

                It 'Should apply the MOF without throwing' {
                    {
                        Reset-DscLcm

                        Start-DscConfiguration -Path $configDir -Wait -Verbose -Force
                    } | Should -Not -Throw
                }

                It 'Should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $configMof -Verbose).InDesiredState | Should -BeTrue
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }
            }

            Context 'When enabling system protection for Drive C with 20% disk usage' {
                $currentConfig = 'DSC_SystemProtection_EnableDriveC_20Percent'
                $configDir = (Join-Path -Path $TestDrive -ChildPath $currentConfig)
                $configMof = (Join-Path -Path $configDir -ChildPath 'localhost.mof')

                It 'Should compile the MOF without throwing' {
                    {
                        . $currentConfig -OutputPath $configDir
                    } | Should -Not -Throw
                }

                It 'Should apply the MOF without throwing' {
                    {
                        Reset-DscLcm

                        Start-DscConfiguration -Path $configDir -Wait -Verbose -Force
                    } | Should -Not -Throw
                }

                It 'Should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $configMof -Verbose).InDesiredState | Should -BeTrue
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }
            }

            Context 'When reducing disk usage from 20% to 5% for Drive C' {
                $currentConfig = 'DSC_SystemProtection_ReduceDriveC_5Percent'
                $configDir = (Join-Path -Path $TestDrive -ChildPath $currentConfig)
                $configMof = (Join-Path -Path $configDir -ChildPath 'localhost.mof')

                It 'Should compile the MOF without throwing' {
                    {
                        . $currentConfig -OutputPath $configDir
                    } | Should -Not -Throw
                }

                It 'Should apply the MOF without throwing' {
                    {
                        Reset-DscLcm

                        Start-DscConfiguration -Path $configDir -Wait -Verbose -Force
                    } | Should -Not -Throw
                }

                It 'Should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $configMof -Verbose).InDesiredState | Should -BeTrue
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }
            }

            Context 'When configuring the frequency of automatic restore points to 0' {
                $currentConfig = 'DSC_SystemProtection_AutoRestorePoints_Zero'
                $configDir = (Join-Path -Path $TestDrive -ChildPath $currentConfig)
                $configMof = (Join-Path -Path $configDir -ChildPath 'localhost.mof')

                It 'Should compile the MOF without throwing' {
                    {
                        . $currentConfig -OutputPath $configDir
                    } | Should -Not -Throw
                }

                It 'Should apply the MOF without throwing' {
                    {
                        Reset-DscLcm

                        Start-DscConfiguration -Path $configDir -Wait -Verbose -Force
                    } | Should -Not -Throw
                }

                It 'Should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $configMof -Verbose).InDesiredState | Should -BeTrue
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
                }
            }
         }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
