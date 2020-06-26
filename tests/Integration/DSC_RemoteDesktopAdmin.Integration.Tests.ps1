$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'DSC_RemoteDesktopAdmin'

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
    Describe 'RemoteDesktopAdmin Integration Tests' {
        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
        . $configFile

        $script:tSRegistryKey = 'HKLM:\System\CurrentControlSet\Control\Terminal Server'
        $script:winStationsRegistryKey = 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'

        Describe "$($script:dscResourceName)_Integration" {
            Context 'When setting Remote Desktop for Administration to Denied' {
                $CurrentConfig = 'setToDenied'
                $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
                $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')

                It 'Should compile the MOF without throwing' {
                    {
                        . $CurrentConfig -OutputPath $ConfigDir
                    } | Should -Not -Throw
                }

                It 'Should apply the MOF without throwing' {
                    {
                        Reset-DscLcm

                        Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                    } | Should -Not -Throw
                }

                It 'Should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should -Be $true
                }

                It 'Should return the correct values from Get-DscConfiguration' {
                    $Current = Get-DscConfiguration | Where-Object -FilterScript { $_.ConfigurationName -eq $CurrentConfig }
                    $Current.IsSingleInstance | Should -Be 'Yes'
                    $Current.Ensure | Should -Be 'Absent'
                }

                It 'Should have set the correct registry values' {
                    (Get-ItemProperty -Path $script:tSRegistryKey -Name 'fDenyTSConnections').fDenyTSConnections | Should -Be 1
                }
            }

            Context 'When setting Remote Desktop for Administration to Allowed' {
                $CurrentConfig = 'setToAllowed'
                $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
                $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')

                It 'Should compile the MOF without throwing' {
                    {
                        . $CurrentConfig -OutputPath $ConfigDir
                    } | Should -Not -Throw
                }

                It 'Should apply the MOF without throwing' {
                    {
                        Reset-DscLcm

                        Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                    } | Should -Not -Throw
                }

                It 'Should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should -Be $true
                }

                It 'Should return the correct values from Get-DscConfiguration' {
                    $Current = Get-DscConfiguration | Where-Object -FilterScript { $_.ConfigurationName -eq $CurrentConfig }
                    $Current.IsSingleInstance | Should -Be 'Yes'
                    $Current.Ensure | Should -Be 'Present'
                }

                It 'Should have set the correct registry values' {
                    (Get-ItemProperty -Path $script:tSRegistryKey -Name 'fDenyTSConnections').fDenyTSConnections | Should -Be 0
                }
            }

            Context 'When settting Remote Desktop for Administration to Allowed with Secure Authentication' {
                $CurrentConfig = 'setToAllowedSecure'
                $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
                $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')

                It 'Should compile the MOF without throwing' {
                    {
                        . $CurrentConfig -OutputPath $ConfigDir
                    } | Should -Not -Throw
                }

                It 'Should apply the MOF without throwing' {
                    {
                        Reset-DscLcm

                        Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                    } | Should -Not -Throw
                }

                It 'Should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should -Be $true
                }

                It 'Should return the correct values from Get-DscConfiguration' {
                    $Current = Get-DscConfiguration | Where-Object -FilterScript { $_.ConfigurationName -eq $CurrentConfig }
                    $Current.IsSingleInstance | Should -Be 'Yes'
                    $Current.Ensure | Should -Be 'Present'
                    $Current.UserAuthentication | Should -Be 'Secure'
                }

                It 'Should have set the correct registry values' {
                    (Get-ItemProperty -Path $script:tSRegistryKey -Name 'fDenyTSConnections').fDenyTSConnections | Should -Be 0
                    (Get-ItemProperty -Path $script:winStationsRegistryKey -Name 'UserAuthentication').UserAuthentication | Should -Be 1
                }
            }

            Context 'When settting Remote Desktop for Administration to Allowed with NonSecure Authentication' {
                $CurrentConfig = 'setToAllowedNonSecure'
                $ConfigDir = (Join-Path -Path $TestDrive -ChildPath $CurrentConfig)
                $ConfigMof = (Join-Path -Path $ConfigDir -ChildPath 'localhost.mof')

                It 'Should compile the MOF without throwing' {
                    {
                        . $CurrentConfig -OutputPath $ConfigDir
                    } | Should -Not -Throw
                }

                It 'Should apply the MOF without throwing' {
                    {
                        Reset-DscLcm

                        Start-DscConfiguration -Path $ConfigDir -Wait -Verbose -Force
                    } | Should -Not -Throw
                }

                It 'Should return a compliant state after being applied' {
                    (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should -Be $true
                }

                It 'Should return the correct values from Get-DscConfiguration' {
                    $Current = Get-DscConfiguration | Where-Object -FilterScript { $_.ConfigurationName -eq $CurrentConfig }
                    $Current.IsSingleInstance | Should -Be 'Yes'
                    $Current.Ensure | Should -Be 'Present'
                    $Current.UserAuthentication | Should -Be 'NonSecure'
                }

                It 'Should have set the correct registry values' {
                    (Get-ItemProperty -Path $script:tSRegistryKey -Name 'fDenyTSConnections').fDenyTSConnections | Should -Be 0
                    (Get-ItemProperty -Path $script:winStationsRegistryKey -Name 'UserAuthentication').UserAuthentication | Should -Be 0
                }
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
