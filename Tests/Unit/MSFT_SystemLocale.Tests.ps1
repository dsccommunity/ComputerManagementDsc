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
    #region Pester Tests
    $testSystemLocale = 'en-US'
    $testAltSystemLocale = 'en-AU'
    $badSystemLocale = 'zzz-ZZZ'
    $localizedData = InModuleScope $script:DSCResourceName {
        $LocalizedData
    }

    Describe 'Schema' {
        it 'IsSingleInstance should be mandatory with one value.' {
            $systemLocaleResource = Get-DscResource -Name SystemLocale
            $systemLocaleResource.Properties.Where{
                $_.Name -eq 'IsSingleInstance'
            }.IsMandatory | Should -BeTrue
            $systemLocaleResource.Properties.Where{
                $_.Name -eq 'IsSingleInstance'
            }.Values | Should -Be 'Yes'
        }
    }

    Describe "$($script:DSCResourceName)\Get-TargetResource" {
        Mock -CommandName Get-WinSystemLocale `
            -ModuleName $($script:DSCResourceName) `
            -MockWith { @{
                LCID        = '1033'
                Name        = 'en-US'
                DisplayName = 'English (United States)'
            } }

        Context 'When System Locale is the desired state' {
            $systemLocale = Get-TargetResource `
                -SystemLocale $testSystemLocale `
                -IsSingleInstance 'Yes'

            It 'Should return hashtable with Key SystemLocale' {
                $systemLocale.ContainsKey('SystemLocale') | Should -BeTrue
            }

            It "Should return hashtable with Value that matches '$testSystemLocale'" {
                $systemLocale.SystemLocale = $testSystemLocale
            }
        }
    }

    Describe "$($script:DSCResourceName)\Set-TargetResource" {
        Mock -CommandName Get-WinSystemLocale `
            -ModuleName $($script:DSCResourceName) `
            -MockWith { @{
                LCID        = '1033'
                Name        = 'en-US'
                DisplayName = 'English (United States)'
            } }

        Mock -CommandName Set-WinSystemLocale `
            -ModuleName $($script:DSCResourceName)

        Context 'When System Locale is the desired state' {
            It 'Should not throw exception' {
                {
                    Set-TargetResource `
                        -SystemLocale $testSystemLocale `
                        -IsSingleInstance 'Yes'
                } | Should -Not -Throw
            }

            It 'Should not call Set-WinSystemLocale' {
                Assert-MockCalled `
                    -CommandName Set-WinSystemLocale `
                    -ModuleName $($script:DSCResourceName) `
                    -Exactly 0
            }
        }

        Context 'When System Locale is not in the desired state' {
            It 'Should not throw exception' {
                {
                    Set-TargetResource `
                        -SystemLocale $testAltSystemLocale `
                        -IsSingleInstance 'Yes'
                } | Should -Not -Throw
            }

            It 'Should call Set-WinSystemLocale' {
                Assert-MockCalled `
                    -CommandName Set-WinSystemLocale `
                    -ModuleName $($script:DSCResourceName) `
                    -Exactly 1
            }
        }
    }

    Describe "$($script:DSCResourceName)\Test-TargetResource" {
        Mock -CommandName Get-WinSystemLocale `
            -ModuleName $($script:DSCResourceName) `
            -MockWith { @{
                LCID        = '1033'
                Name        = 'en-US'
                DisplayName = 'English (United States)'
            } }

        It 'Should throw the expected exception' {
            $errorRecord = Get-InvalidArgumentRecord `
                -Message ($localizedData.InvalidSystemLocaleError -f $badSystemLocale) `
                -ArgumentName 'SystemLocale'

            { Test-TargetResource `
                    -SystemLocale $badSystemLocale `
                    -IsSingleInstance 'Yes' } | Should -Throw $errorRecord
        }

        It 'Should return true when Test is passed System Locale that is already set' {
            Test-TargetResource `
                -SystemLocale $testSystemLocale `
                -IsSingleInstance 'Yes' | Should -BeTrue
        }

        It 'Should return false when Test is passed System Locale that is not set' {
            Test-TargetResource `
                -SystemLocale $testAltSystemLocale `
                -IsSingleInstance 'Yes' | Should -BeFalse
        }
    }

    InModuleScope $script:DSCResourceName {
        # Redeclare these variables so that they can be accessed within the InModuleScope block
        $script:DSCResourceName = 'MSFT_SystemLocale'
        $testSystemLocale = 'en-US'
        $badSystemLocale = 'zzz-ZZZ'

        Describe "$($script:DSCResourceName)\Test-SystemLocaleValue" {
            It 'Should return true when a valid System Locale is passed' {
                Test-SystemLocaleValue `
                    -SystemLocale $testSystemLocale | Should -BeTrue
            }

            It 'Should return false when an invalid System Locale is passed' {
                Test-SystemLocaleValue `
                    -SystemLocale $badSystemLocale | Should -BeFalse
            }
        }
    } #end InModuleScope $DSCResourceName
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
