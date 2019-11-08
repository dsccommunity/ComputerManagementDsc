$script:DSCModuleName = 'ComputerManagementDsc'
$script:DSCResourceName = 'MSFT_SystemLocale'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

#region HEADER
# Unit Test Template Version: 1.1.0
[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit
#endregion HEADER

# Begin Testing
try
{
    InModuleScope $script:DSCResourceName {
        $script:testSystemLocale = 'en-US'
        $script:testAltSystemLocale = 'en-AU'
        $script:badSystemLocale = 'zzz-ZZZ'

        Describe 'MSFT_SystemLocale\Get-TargetResource' {
            Mock -CommandName Get-WinSystemLocale `
                -ModuleName 'MSFT_SystemLocale' `
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

        Describe 'MSFT_SystemLocale\Set-TargetResource' {
            Mock -CommandName Get-WinSystemLocale `
                -ModuleName 'MSFT_SystemLocale' `
                -MockWith { @{
                    LCID        = '1033'
                    Name        = 'en-US'
                    DisplayName = 'English (United States)'
                } }

            Mock -CommandName Set-WinSystemLocale `
                -ModuleName 'MSFT_SystemLocale'

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
                        -ModuleName 'MSFT_SystemLocale' `
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
                        -ModuleName 'MSFT_SystemLocale' `
                        -Exactly 1
                }
            }
        }

        Describe 'MSFT_SystemLocale\Test-TargetResource' {
            Mock -CommandName Get-WinSystemLocale `
                -ModuleName 'MSFT_SystemLocale' `
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

            Describe 'MSFT_SystemLocale\Test-SystemLocaleValue' {
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
    } #end InModuleScope $DSCResourceName
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
