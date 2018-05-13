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
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Integration

#endregion
Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

# Using try/finally to always cleanup.
try
{
    $LanguagePackFolderLocation = "c:\LanguagePacks\"
    $LanguagePackFileLocation = "c:\LanguagePacks\x64fre_Server_de-de_lp.cab"
    $NewLanguagePackFromFolder = 'en-GB'
    $NewLanguagePackFromFile = 'de-DE'
    $RemoveLanguagePack = 'en-US'

    Describe "Pre-flight Checks" -Tag @("Integration","RequiresDependency") {

        Context "Ensure Language Binaries are available" {
            It "Language Pack Folder $LanguagePackFolderLocation Exists" {
                Test-Path -Path $LanguagePackFolderLocation -PathType Container | Should -Be $true
            }

            It "Language Pack Folder must include at least 1 cab file" {
                (Get-ChildItem -Path $LanguagePackFolderLocation -Filter "*.cab").count | Should -BeGreaterThan 0
            }

            It "Language Pack File Location must be a cab file" {
                $LanguagePackFileLocation.EndsWith(".cab") | Should -Be $true
            }

            It "Language Pack File Location must exist" {
                Test-Path -Path $LanguagePackFileLocation -PathType Leaf | Should -Be $true
            }
        }
    

        Context "Ensure System requires modification" {
            It "New Language Pack $NewLanguagePackFromFolder mustn't be installed"        {
                $CurrentState = Get-TargetResource -LanguagePackName $NewLanguagePackFromFolder
                $CurrentState.ensure | Should -Be "Absent"
            }

            It "New Language Pack $NewLanguagePackFromFile mustn't be installed"        {
                $CurrentState = Get-TargetResource -LanguagePackName $NewLanguagePackFromFile
                $CurrentState.ensure | Should -Be "Absent"
            }

            It "Language Pack to be removed $RemoveLanguagePack must be installed"        {
                $CurrentState = Get-TargetResource -LanguagePackName $RemoveLanguagePack
                $CurrentState.ensure | Should -Be "Present"
            }
        }
    }

    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $configFile 

    #region Integration Tests
    Describe "$($script:DSCResourceName) Folder Install Integration" -Tag @("Integration","RequiresDependency") {
        #region DEFAULT TESTS
        It "Should compile and apply the MOF without throwing" {
            {
                Write-Verbose "Run Config" -Verbose:$true
                & "$($script:DSCResourceName)_Config" -OutputPath $TestDrive -LangaugePackName $NewLanguagePackFromFolder -LangaugePackLocation $LanguagePackFolderLocation -Ensure "Present"
                Start-DscConfiguration -Path $TestDrive `
                    -ComputerName localhost -Wait -Verbose -Force
            } | Should -Not -Throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should -Not -Throw
        }
        #endregion

        It 'Should have installed the language Pack' {
            $currentConfig = Get-TargetResource -LanguagePackName $NewLanguagePackFromFolder -Verbose
            $currentConfig.Ensure | Should -Be "Present"
        }
    }

    Describe "$($script:DSCResourceName) File Install Integration" -Tag @("Integration","RequiresDependency") {
        $configMof = (Join-Path -Path $TestDrive -ChildPath 'localhost.mof')

        It 'Should compile the MOF without throwing' {
            {
                & "$($script:DSCResourceName)_Config" `
                    -OutputPath $TestDrive `
                    -LangaugePackName $NewLanguagePackFromFile `
                    -LangaugePackLocation $LanguagePackFileLocation `
                    -Ensure "Present"
            } | Should -Not -Throw
        }

        It 'Should apply the MOF correctly' {
            {
                Start-DscConfiguration `
                    -Path $TestDrive `
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

    Describe "$($script:DSCResourceName) Language Pack Uninstall Integration" -Tag @("Integration","RebootRequired","RequiresDependency") {

        It 'Should compile the MOF without throwing' {
            {
                & "$($script:DSCResourceName)_Config" `
                    -OutputPath $TestDrive `
                    -LangaugePackName $RemoveLanguagePack `
                    -Ensure "Absent"
            } | Should -Not -Throw
        }

        It 'Should apply the MOF correctly' {
            {
                Start-DscConfiguration `
                    -Path $TestDrive `
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
    #endregion
}
finally
{
    #region FOOTER

    Restore-TestEnvironment -TestEnvironment $TestEnvironment

    #endregion

    # TODO: Other Optional Cleanup Code Goes Here...
}
