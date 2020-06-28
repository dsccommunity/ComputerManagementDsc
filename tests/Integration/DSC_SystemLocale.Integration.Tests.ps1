$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'DSC_SystemLocale'

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

# Store the test machine system locale
$currentSystemLocale = (Get-WinSystemLocale).Name

# Change the current system locale so that a complete test occurs.
Set-WinSystemLocale -SystemLocale 'kl-GL'

# Begin Testing
try
{
    Describe 'SystemLocale Integration Tests' {
        $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
        . $configFile -Verbose -ErrorAction Stop

        Describe "$($script:DSCResourceName)_Integration" {
            Context 'When settting System Locale to fr-FR' {
                $configData = @{
                    AllNodes = @(
                        @{
                            NodeName         = 'localhost'
                            SystemLocale     = 'fr-FR'
                            IsSingleInstance = 'Yes'
                        }
                    )
                }

                It 'Should compile the MOF without throwing' {
                    {
                        & "$($script:DSCResourceName)_Config" `
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

                It 'Should have set the resource and all the parameters should match' {
                    $current = Get-DscConfiguration | Where-Object {
                        $_.ConfigurationName -eq "$($script:DSCResourceName)_Config"
                    }
                    <#
                        A reboot would need to occur before this node can be bought into alignment.
                        Therefore a test for the new SystemLocale can not be automated.
                    #>
                    $current.IsSingleInstance | Should -Be $configData.AllNodes[0].IsSingleInstance
                }
            }
        }
    }
}
finally
{
    # Restore the test machine system locale
    Set-WinSystemLocale -SystemLocale $currentSystemLocale

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
