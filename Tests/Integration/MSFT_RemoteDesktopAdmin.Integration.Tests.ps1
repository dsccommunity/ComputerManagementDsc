#region HEADER
$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'MSFT_RemoteDesktopAdmin'

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

    $script:tSRegistryKey = 'HKLM:\System\CurrentControlSet\Control\Terminal Server'
    $script:winStationsRegistryKey = 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'

    Describe "$($script:dscResourceName)_Integration" {

        Context 'Set Remote Desktop for Administration to Denied' {
            $CurrentConfig = 'setToDenied'
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
                (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should -Be $true
            }

            It 'Should return the correct values from Get-DscConfiguration' {
                $Current = Get-DscConfiguration   | Where-Object -FilterScript {$_.ConfigurationName -eq $CurrentConfig}
                $Current.IsSingleInstance   | Should -Be 'Yes'
                $Current.Ensure             | Should -Be 'Absent'
            }

            It 'Should have set the correct registry values' {
                (Get-ItemProperty -Path $script:tSRegistryKey -Name 'fDenyTSConnections').fDenyTSConnections | Should -Be 1
            }
        }

        Context 'Set Remote Desktop for Administration to Allowed' {
            $CurrentConfig = 'setToAllowed'
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
                (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should -Be $true
            }

            It 'Should return the correct values from Get-DscConfiguration' {
                $Current = Get-DscConfiguration   | Where-Object -FilterScript {$_.ConfigurationName -eq $CurrentConfig}
                $Current.IsSingleInstance   | Should -Be 'Yes'
                $Current.Ensure             | Should -Be 'Present'
            }

            It 'Should have set the correct registry values' {
                (Get-ItemProperty -Path $script:tSRegistryKey -Name 'fDenyTSConnections').fDenyTSConnections | Should -Be 0
            }
        }

        Context 'Set Remote Desktop for Administration to Allowed with Secure Authentication' {
            $CurrentConfig = 'setToAllowedSecure'
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
                (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should -Be $true
            }

            It 'Should return the correct values from Get-DscConfiguration' {
                $Current = Get-DscConfiguration   | Where-Object -FilterScript {$_.ConfigurationName -eq $CurrentConfig}
                $Current.IsSingleInstance   | Should -Be 'Yes'
                $Current.Ensure             | Should -Be 'Present'
                $Current.UserAuthentication | Should -Be 'Secure'
            }

            It 'Should have set the correct registry values' {
                (Get-ItemProperty -Path $script:tSRegistryKey -Name 'fDenyTSConnections').fDenyTSConnections | Should -Be 0
                (Get-ItemProperty -Path $script:winStationsRegistryKey -Name 'UserAuthentication').UserAuthentication | Should -Be 1
            }
        }

        Context 'Set Remote Desktop for Administration to Allowed with NonSecure Authentication' {
            $CurrentConfig = 'setToAllowedNonSecure'
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
                (Test-DscConfiguration -ReferenceConfiguration $ConfigMof -Verbose).InDesiredState | Should -Be $true
            }

            It 'Should return the correct values from Get-DscConfiguration' {
                $Current = Get-DscConfiguration   | Where-Object -FilterScript {$_.ConfigurationName -eq $CurrentConfig}
                $Current.IsSingleInstance   | Should -Be 'Yes'
                $Current.Ensure             | Should -Be 'Present'
                $Current.UserAuthentication | Should -Be 'NonSecure'
            }

            It 'Should have set the correct registry values' {
                (Get-ItemProperty -Path $script:tSRegistryKey -Name 'fDenyTSConnections').fDenyTSConnections | Should -Be 0
                (Get-ItemProperty -Path $script:winStationsRegistryKey -Name 'UserAuthentication').UserAuthentication | Should -Be 0
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
