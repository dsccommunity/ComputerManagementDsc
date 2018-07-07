$script:DSCModuleName      = 'ComputerManagementDsc'
$script:DSCResourceName    = 'MSFT_LanguagePack'

#region HEADER
# Integration Test Template Version: 1.1.1
$script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\ComputerManagementDsc'
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force
$testEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Integration

#endregion
Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

# Using try/finally to always cleanup.
try
{
    $languagePackFolderLocation = "c:\LanguagePacks\"
    $languagePackFileLocation = "c:\LanguagePacks\x64fre_Server_de-de_lp.cab"
    $newLanguagePackFromFolder = 'en-GB'
    $newLanguagePackFromFile = 'de-DE'
    $removeLanguagePack = 'en-US'
    if ($env:APPVEYOR -eq $true)
    {
        Write-Warning -Message ('Pre-flight checks for {0} Integration test will be skipped because appveyor does not have the required cab files.' -f $script:DSCResourceName)
    }
    else
    {
        Describe "Pre-flight Checks" -Tag @('Integration','RequiresDependency') {

            Context "Ensure Language Binaries are available" {
                It "Language Pack Folder $languagePackFolderLocation Exists" {
                    Test-Path -Path $languagePackFolderLocation -PathType Container | Should -Be $true
                }

                It "Language Pack Folder must include at least 1 cab file" {
                    (Get-ChildItem -Path $languagePackFolderLocation -Filter "*.cab").count | Should -BeGreaterThan 0
                }

                It "Language Pack File Location must be a cab file" {
                    $languagePackFileLocation.EndsWith(".cab") | Should -Be $true
                }

                It "Language Pack File Location must exist" {
                    Test-Path -Path $languagePackFileLocation -PathType Leaf | Should -Be $true
                }
            }

            Context "Ensure System requires modification" {
                It "New Language Pack $newLanguagePackFromFolder mustn't be installed"        {
                    $currentState = Get-TargetResource -LanguagePackName $newLanguagePackFromFolder
                    $currentState.ensure | Should -Be "Absent"
                }

                It "New Language Pack $newLanguagePackFromFile mustn't be installed"        {
                    $currentState = Get-TargetResource -LanguagePackName $newLanguagePackFromFile
                    $currentState.ensure | Should -Be "Absent"
                }

                It "Language Pack to be removed $removeLanguagePack must be installed"        {
                    $currentState = Get-TargetResource -LanguagePackName $removeLanguagePack
                    $currentState.ensure | Should -Be "Present"
                }
            }
        }
    }

    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $configFile

    #region Integration Tests
    if ($env:APPVEYOR -eq $true)
    {
        Write-Warning -Message ('Language Pack Folder install checks for {0} Integration test will be skipped because appveyor does not have the required cab files.' -f $script:DSCResourceName)
    }
    else
    {
        Describe "$($script:DSCResourceName) Folder Install Integration" -Tag @("Integration","RequiresDependency") {
            #region DEFAULT TESTS
            It "Should compile and apply the MOF without throwing" {
                {
                    Write-Verbose "Run Config" -Verbose:$true
                    & "$($script:DSCResourceName)_Config" -OutputPath $testDrive -LangaugePackName $newLanguagePackFromFolder -LangaugePackLocation $languagePackFolderLocation -Ensure "Present"
                    Start-DscConfiguration -Path $testDrive `
                        -ComputerName localhost -Wait -Verbose -Force
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
            }
            #endregion

            It 'Should have installed the language Pack' {
                $currentConfig = Get-TargetResource -LanguagePackName $newLanguagePackFromFolder -Verbose
                $currentConfig.Ensure | Should -Be "Present"
            }
        }
    }

    if ($env:APPVEYOR -eq $true)
    {
        Write-Warning -Message ('Language Pack File install checks for {0} Integration test will be skipped because appveyor does not have the required cab files.' -f $script:DSCResourceName)
    }
    else
    {
        Describe "$($script:DSCResourceName) File Install Integration" -Tag @("Integration","RequiresDependency") {


            $configMof = (Join-Path -Path $testDrive -ChildPath 'localhost.mof')

            It 'Should compile the MOF without throwing' {
                {
                    & "$($script:DSCResourceName)_Config" `
                        -OutputPath $testDrive `
                        -LangaugePackName $newLanguagePackFromFile `
                        -LangaugePackLocation $languagePackFileLocation `
                        -Ensure "Present"
                } | Should -Not -Throw
            }

            It 'Should apply the MOF correctly' {
                {
                    Start-DscConfiguration `
                        -Path $testDrive `
                        -Wait `
                        -Force `
                        -Verbose `
                        -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should return a compliant state after being applied' {
                (Test-DscConfiguration -ReferenceConfiguration $configMof -Verbose).InDesiredState | Should -Be $true
            }
        }
    }

    if ($env:APPVEYOR -eq $true)
    {
        Write-Warning -Message ('Integration test for {0} will be skipped because appveyor does not support reboots.' -f $script:DSCResourceName)
    }
    else
    {
        Describe "$($script:DSCResourceName) Language Pack Uninstall Integration" -Tag @("Integration","RebootRequired") {
            It 'Should compile the MOF without throwing' {
                {
                    & "$($script:DSCResourceName)_Config" `
                        -OutputPath $TestDrive `
                        -LangaugePackName $removeLanguagePack `
                        -Ensure "Absent"
                } | Should -Not -Throw
            }

            It 'Should apply the MOF correctly' {
                {
                    Start-DscConfiguration `
                        -Path $testDrive `
                        -Wait `
                        -Force `
                        -Verbose `
                        -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should return a compliant state after being applied' {
                (Test-DscConfiguration -ReferenceConfiguration $configMof -Verbose).InDesiredState | Should -Be $true
            }
        }
    }
    #endregion
}
finally
{
    #region FOOTER

    Restore-TestEnvironment -TestEnvironment $testEnvironment

    #endregion

    # TODO: Other Optional Cleanup Code Goes Here...
}
