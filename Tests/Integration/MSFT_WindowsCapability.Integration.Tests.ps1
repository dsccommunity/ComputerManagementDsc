#region HEADER
$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'MSFT_WindowsCapability'

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

function Invoke-TestSetup
{
    if (-not (Get-Module dism -ListAvailable))
    {
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs\dism.psm1') -Force
    }
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

try
{
    Invoke-TestSetup

    # Ensure that the tests can be performed on this computer
    $productType = (Get-CimInstance Win32_OperatingSystem).ProductType
    Describe 'Environment' {
        Context 'Operating System' {
            It 'Should be a Desktop OS' {
                if ($productType -ne 1)
                {
                    Set-ItResult -Inconclusive -Because 'Operating System is not a Desktop OS'
                }
            }
        }
    }

    if ($productType -ne 1)
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

            It 'Should compile and apply the MOF without throwing' {
                {
                    & "$($script:dscResourceName)_Config" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData

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
                $current.LogLevel | Should -Be $configData.AllNodes[0].LogLevel
                $current.LogPath | Should -Be $configData.AllNodes[0].LogPath
                $current.Ensure | Should -Be $configData.AllNodes[0].Ensure
                $current.IsSingleInstance | Should -Be 'Yes'
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

            It 'Should compile and apply the MOF without throwing' {
                {
                    & "$($script:dscResourceName)_Config" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData

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
                $current.LogLevel | Should -Be $configData.AllNodes[0].LogLevel
                $current.LogPath | Should -Be $configData.AllNodes[0].LogPath
                $current.Ensure | Should -Be $configData.AllNodes[0].Ensure
                $current.IsSingleInstance | Should -Be 'Yes'
            }
        }
    }
}
finally
{
    #region FOOTER
    Invoke-TestCleanup
    #endregion
}
