$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'DSC_WindowsCapability'

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
    Describe 'WindowsCapability Integration Tests' {
        # Ensure that the tests can be performed on this computer
        $sourceAvailable = Test-WindowsCapabilitySourceAvailable -Verbose

        Describe 'Windows capability source files' {
            It 'Should be available' {
                if (-not $sourceAvailable)
                {
                    Set-ItResult -Inconclusive -Because 'Windows capability source files are not available'
                }
            }
        }

        if (-not $sourceAvailable)
        {
            break
        }

        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).Config.ps1"
        . $configFile

        Describe "$($script:dscResourceName)_Integration" {
            Context 'When adding a Windows Capability' {
                $configData = @{
                    AllNodes = @(
                        @{
                            NodeName = 'localhost'
                            Name     = 'XPS.Viewer~~~~0.0.1.0'
                            LogLevel = 'Errors'
                            LogPath  = Join-Path -Path $ENV:Temp -ChildPath 'Logfile.log'
                            Ensure   = 'Present'
                        }
                    )
                }

                It 'Should compile the MOF without throwing' {
                    {
                        & "$($script:dscResourceName)_Config" `
                            -OutputPath $TestDrive `
                            -ConfigurationData $configData
                    } | Should -Not -Throw
                }

                It 'Should apply the MOF without throwing' {
                    {
                        Reset-DscLcm

                        $startDscConfigurationParameters = @{
                            Path         = $TestDrive
                            ComputerName = 'localhost'
                            Wait         = $true
                            Verbose      = $true
                            Force        = $true
                            ErrorAction  = 'Stop'
                        }

                        Start-DscConfiguration @startDscConfigurationParameters
                    } | Should -Not -Throw
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    {
                        Get-DscConfiguration -Verbose -ErrorAction Stop
                    } | Should -Not -Throw
                }

                It 'Should have set the resource and all the parameters should match' {
                    $current = Get-DscConfiguration | Where-Object -FilterScript {
                        $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
                    }
                    $current.Name | Should -Be $configData.AllNodes[0].Name
                    $current.Ensure | Should -Be $configData.AllNodes[0].Ensure
                }
            }

            Context 'When removing a Windows Capability' {
                $configData = @{
                    AllNodes = @(
                        @{
                            NodeName = 'localhost'
                            Name     = 'XPS.Viewer~~~~0.0.1.0'
                            LogLevel = 'Errors'
                            LogPath  = Join-Path -Path $ENV:Temp -ChildPath 'Logfile.log'
                            Ensure   = 'Absent'
                        }
                    )
                }

                It 'Should compile the MOF without throwing' {
                    {
                        & "$($script:dscResourceName)_Config" `
                            -OutputPath $TestDrive `
                            -ConfigurationData $configData
                    } | Should -Not -Throw
                }

                It 'Should apply the MOF without throwing' {
                    {
                        Reset-DscLcm

                        $startDscConfigurationParameters = @{
                            Path         = $TestDrive
                            ComputerName = 'localhost'
                            Wait         = $true
                            Verbose      = $true
                            Force        = $true
                            ErrorAction  = 'Stop'
                        }

                        Start-DscConfiguration @startDscConfigurationParameters
                    } | Should -Not -Throw
                }

                It 'Should be able to call Get-DscConfiguration without throwing' {
                    {
                        Get-DscConfiguration -Verbose -ErrorAction Stop
                    } | Should -Not -Throw
                }

                It 'Should have set the resource and all the parameters should match' {
                    $current = Get-DscConfiguration | Where-Object -FilterScript {
                        $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
                    }
                    $current.Name | Should -Be $configData.AllNodes[0].Name
                    $current.Ensure | Should -Be $configData.AllNodes[0].Ensure
                }
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
