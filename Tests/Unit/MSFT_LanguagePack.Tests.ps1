$script:DSCModuleName      = 'ComputerManagementDsc'
$script:DSCResourceName    = 'MSFT_LanguagePack'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\ComputerManagementDsc'
Write-Output @('clone','https://github.com/PowerShell/DscResource.Tests.git',"'"+(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests')+"'")

if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests'),'--verbose')
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup {

}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment

    # TODO: Other Optional Cleanup Code Goes Here...
}

# Begin Testing
try
{

    Invoke-TestSetup

    InModuleScope 'MSFT_LanguagePack' {
        #Define Static Variables used within all Tests
        $script:DSCModuleName      = 'ComputerManagementDsc'
        $script:DSCResourceName = 'MSFT_LanguagePack'
        $ExistingLanguagePack = 'en-US'
        $NewLanguagePack = 'en-GB'
        $InvalidLanguagePack = 'no-lg'
        $LanguagePackLocation = "\\SRV1\LanguagePacks\"

        # TODO: Complete the Describe blocks below and add more as needed.
        # The most common method for unit testing is to test by function. For more information
        # check out this introduction to writing unit tests in Pester:
        # https://www.simple-talk.com/sysadmin/powershell/practical-powershell-unit-testing-getting-started/#eleventh
        # You may also follow one of the patterns provided in the TestsGuidelines.md file:
        # https://github.com/PowerShell/DscResources/blob/master/TestsGuidelines.md

        Describe 'Schema' {

            Context 'Check Variable requirements' {
                $systemLocaleResource = Get-DscResource -Name LanguagePack -Module $script:DSCModuleName

                it 'LanguagePackName should be mandatory.' {
                
                    $systemLocaleResource.Properties.Where{$_.Name -eq 'LanguagePackName'}.IsMandatory | Should -Be $true
                }

                it 'LanguagePackLocation should not be mandatory.' {
                    $systemLocaleResource.Properties.Where{$_.Name -eq 'LanguagePackLocation'}.IsMandatory | Should -Be $false
                }

                it 'Ensure should not be mandatory' {
                    $systemLocaleResource.Properties.Where{$_.Name -eq 'Ensure'}.IsMandatory | Should -Be $false
                }

                it 'Ensure should only have two values' {
                    $systemLocaleResource.Properties.Where{$_.Name -eq 'Ensure'}.Values | Should -Be @('Absent','Present')
                }
            }
        }

        Describe "$($script:DSCResourceName)\Get-TargetResource" {
            Mock -CommandName Get-CIMInstance `
                -ModuleName $($script:DSCResourceName) `
                -MockWith { @{
                    MUILanguages = 'en-US'
                } }

            Context 'Language Pack is in the desired state' {
                $Languages = Get-TargetResource `
                    -LanguagePackName $ExistingLanguagePack

                It 'Should return hashtable with Key LanguagePackName'{
                    $Languages.ContainsKey('LanguagePackName') | Should -Be $true
                }

                It "Should return hashtable with Value that matches '$ExistingLanguagePack'" {
                    $Languages.LanguagePackName = $ExistingLanguagePack
                }

                It 'Should return hashtable with Key Ensure'{
                    $Languages.ContainsKey('Ensure') | Should -Be $true
                }

                It "Should return hashtable with Value that matches Present" {
                    $Languages.Ensure = 'Present'
                }
            }

            Context 'Language Pack has not been installed' {
                $Languages = Get-TargetResource `
                    -LanguagePackName $NewLanguagePack

                It 'Should return hashtable with Key LanguagePackName'{
                    $Languages.ContainsKey('LanguagePackName') | Should -Be $true
                }

                It "Should return hashtable with Value that matches '$NewLanguagePack'" {
                    $Languages.LanguagePackName = $NewLanguagePack
                }

                It 'Should return hashtable with Key Ensure'{
                    $Languages.ContainsKey('Ensure') | Should -Be $true
                }

                It "Should return hashtable with Value that matches Absent" {
                    $Languages.Ensure = 'Absent'
                }
            }

            Context 'Language Pack does not exist' {
                $Languages = Get-TargetResource `
                    -LanguagePackName $InvalidLanguagePack

                It 'Should return hashtable with Key LanguagePackName'{
                    $Languages.ContainsKey('LanguagePackName') | Should -Be $true
                }

                It "Should return hashtable with Value that matches '$InvalidLanguagePack'" {
                    $Languages.LanguagePackName = $InvalidLanguagePack
                }

                It 'Should return hashtable with Key Ensure'{
                    $Languages.ContainsKey('Ensure') | Should -Be $true
                }

                It "Should return hashtable with Value that matches Absent" {
                    $Languages.Ensure = 'Absent'
                }
            }
        }

        Describe "$($script:DSCResourceName)\Test-TargetResource" {
            Mock -CommandName Get-CIMInstance `
                -ModuleName $($script:DSCResourceName) `
                -MockWith { @{
                    MUILanguages = 'en-US'
                } }

            Context 'Language Pack is already installed' {
                $Languages = Test-TargetResource `
                    -LanguagePackName $ExistingLanguagePack

                It 'Should return true'{
                    $Languages | Should -Be $true
                }
            }

            Context 'Language Pack will be installed' {
                $Languages = Test-TargetResource `
                    -LanguagePackName $NewLanguagePack

                It 'Should return false'{
                    $Languages | Should -Be $false
                }
            }

            Context 'Language Pack will be removed' {
                $Languages = Test-TargetResource `
                    -LanguagePackName $ExistingLanguagePack `
                    -Ensure "Absent"

                It 'Should return false'{
                    $Languages | Should -Be $false
                }
            }

            Context 'Language Pack does not need to be removed' {
                $Languages = Test-TargetResource `
                    -LanguagePackName $InvalidLanguagePack `
                    -Ensure "Absent"

                It 'Should return true'{
                    $Languages | Should -Be $true
                }
            }
        }

        Describe "$($script:DSCResourceName)\Set-TargetResource" {
            Mock -CommandName Test-Path `
                -ModuleName $($script:DSCResourceName) `
                -MockWith { $true }

            Mock -CommandName lpksetup.exe `
                -ModuleName $($script:DSCResourceName)

            Context 'Language Pack will be installed' {
                It 'Should not throw exception' {
                    {
                        Set-TargetResource `
                            -LanguagePackName $NewLanguagePack `
                            -LanguagePackLocation $LanguagePackLocation
                    } | Should -Not -Throw
                }
                It 'Should call lpksetup.exe once' {
                    Assert-MockCalled `
                        -CommandName lpksetup.exe `
                        -ModuleName $($script:DSCResourceName) `
                        -Exactly 1
                }

                It 'Should call Test-Path once' {
                    Assert-MockCalled `
                        -CommandName Test-Path `
                        -ModuleName $($script:DSCResourceName) `
                        -Exactly 1
                }
            }

            Context 'Language Pack will be removed' {
                It 'Should not throw exception' {
                    {
                        Set-TargetResource `
                            -LanguagePackName $ExistingLanguagePack `
                            -Ensure "Absent"
                    } | Should -Not -Throw
                }
                It 'Should call lpksetup.exe once' {
                    Assert-MockCalled `
                        -CommandName lpksetup.exe `
                        -ModuleName $($script:DSCResourceName) `
                        -Exactly 1
                }

                It 'Should not call Test-Path' {
                    Assert-MockCalled `
                        -CommandName Test-Path `
                        -ModuleName $($script:DSCResourceName) `
                        -Exactly 0
                }
            }

            Context 'Language Pack installation missing Location' {
                It 'Should not throw exception' {
                    {
                        Set-TargetResource `
                            -LanguagePackName $NewLanguagePack `
                            -Ensure "Present"
                    } | Should Throw
                }
                It 'Should not call lpksetup.exe' {
                    Assert-MockCalled `
                        -CommandName lpksetup.exe `
                        -ModuleName $($script:DSCResourceName) `
                        -Exactly 0
                }

                It 'Should not call Test-Path' {
                    Assert-MockCalled `
                        -CommandName Test-Path `
                        -ModuleName $($script:DSCResourceName) `
                        -Exactly 0
                }
            }

            Context 'Language Pack installation invalid Location' {
                Mock -CommandName Test-Path `
                -ModuleName $($script:DSCResourceName) `
                -MockWith { $false }
                It 'Should not throw exception' {
                    {
                        Set-TargetResource `
                            -LanguagePackName $NewLanguagePack `
                            -LanguagePackLocation $LanguagePackLocation
                            -Ensure "Present"
                    } | Should -Throw
                }
                It 'Should not call lpksetup.exe' {
                    Assert-MockCalled `
                        -CommandName lpksetup.exe `
                        -ModuleName $($script:DSCResourceName) `
                        -Exactly 0
                }

                It 'Should call Test-Path' {
                    Assert-MockCalled `
                        -CommandName Test-Path `
                        -ModuleName $($script:DSCResourceName) `
                        -Exactly 1
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
