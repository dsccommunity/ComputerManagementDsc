$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'DSC_TimeZone'

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

# Store the test machine timezone
$currentTimeZone = & tzutil.exe /g

# Change the current timezone so that a complete test occurs.
tzutil.exe /s 'Eastern Standard Time'

# Begin Testing
try
{
    Describe 'TimeZone Integration Tests' {
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
                $current.TimeZone | Should -Be $configData.AllNodes[0].TimeZone
                $current.IsSingleInstance | Should -Be $configData.AllNodes[0].IsSingleInstance
            }
        }
    }
}
finally
{
    # Restore the test machine timezone
    & tzutil.exe /s $CurrentTimeZone

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
