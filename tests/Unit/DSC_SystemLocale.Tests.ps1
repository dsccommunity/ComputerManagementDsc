$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'DSC_SystemLocale'

function Invoke-TestSetup
{
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
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

# Begin Testing
try
{
    InModuleScope $script:dscResourceName {
        $script:testSystemLocale = 'en-US'
        $script:testAltSystemLocale = 'en-AU'
        $script:badSystemLocale = 'zzz-ZZZ'

        Describe 'DSC_SystemLocale\Get-TargetResource' {
            Mock -CommandName Get-WinSystemLocale `
                -MockWith { @{
                    LCID        = '1033'
                    Name        = 'en-US'
                    DisplayName = 'English (United States)'
                } }

            Context 'When System Locale is the desired state' {
                $systemLocale = Get-TargetResource `
                    -SystemLocale $script:testSystemLocale `
                    -IsSingleInstance 'Yes'

                It 'Should return hashtable with Key SystemLocale' {
                    $systemLocale.ContainsKey('SystemLocale') | Should -BeTrue
                }

                It "Should return hashtable with Value that matches '$script:testSystemLocale'" {
                    $systemLocale.SystemLocale | Should -Be $script:testSystemLocale
                }
            }
        }

        Describe 'DSC_SystemLocale\Set-TargetResource' {
            Mock -CommandName Get-WinSystemLocale `
                -MockWith { @{
                    LCID        = '1033'
                    Name        = 'en-US'
                    DisplayName = 'English (United States)'
                } }

            Mock -CommandName Set-WinSystemLocale

            Context 'When System Locale is the desired state' {
                It 'Should not throw exception' {
                    {
                        Set-TargetResource `
                            -SystemLocale $script:testSystemLocale `
                            -IsSingleInstance 'Yes'
                    } | Should -Not -Throw
                }

                It 'Should not call Set-WinSystemLocale' {
                    Assert-MockCalled `
                        -CommandName Set-WinSystemLocale `
                        -Exactly 0
                }
            }

            Context 'When System Locale is not in the desired state' {
                It 'Should not throw exception' {
                    {
                        Set-TargetResource `
                            -SystemLocale $script:testAltSystemLocale `
                            -IsSingleInstance 'Yes'
                    } | Should -Not -Throw
                }

                It 'Should call Set-WinSystemLocale' {
                    Assert-MockCalled `
                        -CommandName Set-WinSystemLocale `
                        -Exactly 1
                }
            }
        }

        Describe 'DSC_SystemLocale\Test-TargetResource' {
            Mock -CommandName Get-WinSystemLocale `
                -MockWith { @{
                    LCID        = '1033'
                    Name        = 'en-US'
                    DisplayName = 'English (United States)'
                } }

            It 'Should throw the expected exception' {
                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($localizedData.InvalidSystemLocaleError -f $script:badSystemLocale) `
                    -ArgumentName 'SystemLocale'

                { Test-TargetResource `
                        -SystemLocale $script:badSystemLocale `
                        -IsSingleInstance 'Yes' } | Should -Throw $errorRecord
            }

            It 'Should return true when Test is passed System Locale that is already set' {
                Test-TargetResource `
                    -SystemLocale $script:testSystemLocale `
                    -IsSingleInstance 'Yes' | Should -BeTrue
            }

            It 'Should return false when Test is passed System Locale that is not set' {
                Test-TargetResource `
                    -SystemLocale $script:testAltSystemLocale `
                    -IsSingleInstance 'Yes' | Should -BeFalse
            }

            Describe 'DSC_SystemLocale\Test-SystemLocaleValue' {
                It 'Should return true when a valid System Locale is passed' {
                    Test-SystemLocaleValue `
                        -SystemLocale $script:testSystemLocale | Should -BeTrue
                }

                It 'Should return false when an invalid System Locale is passed' {
                    Test-SystemLocaleValue `
                        -SystemLocale $script:badSystemLocale | Should -BeFalse
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
