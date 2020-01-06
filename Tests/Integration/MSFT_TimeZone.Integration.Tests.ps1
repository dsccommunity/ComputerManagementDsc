#region HEADER
$script:dscModuleName      = 'ComputerManagementDsc'
$script:dscResourceName    = 'MSFT_TimeZone'

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

# Store the test machine timezone
$currentTimeZone = & tzutil.exe /g

# Change the current timezone so that a complete test occurs.
tzutil.exe /s 'Eastern Standard Time'

# Using try/finally to always cleanup even if something awful happens.
try
{
    #region Integration Tests
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configFile -Verbose -ErrorAction Stop

    Describe "$($script:dscResourceName)_Integration" {
        $configData = @{
            AllNodes = @(
                @{
                    NodeName         = 'localhost'
                    TimeZone         = 'Pacific Standard Time'
                    IsSingleInstance = 'Yes'
                }
            )
        }

        It 'Should compile and apply the MOF without throwing' {
            {
                & "$($script:dscResourceName)_Config" `
                    -OutputPath $TestDrive `
                    -ConfigurationData $configData

                Start-DscConfiguration `
                    -Path $TestDrive `
                    -ComputerName localhost `
                    -Wait `
                    -Verbose `
                    -Force `
                    -ErrorAction Stop
            } | Should -Not -Throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
        }

        It 'Should have set the configuration and all the parameters should match' {
            $current = Get-DscConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
            }
            $current.TimeZone         | Should -Be $configData.AllNodes[0].TimeZone
            $current.IsSingleInstance | Should -Be $configData.AllNodes[0].IsSingleInstance
        }
    }
    #endregion
}
finally
{
    # Restore the test machine timezone
    & tzutil.exe /s $CurrentTimeZone

    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
