$script:DSCModuleName      = 'ComputerManagementDsc'
$script:DSCResourceName    = 'MSFT_Language'

#region HEADER
# Integration Test Template Version: 1.1.1
$script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\ComputerManagementDsc'
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Integration

#endregion

Import-Module -Name (Join-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResources' ) -ChildPath 'MSFT_Language')
Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

# Using try/finally to always cleanup.
try
{
    $LocationID = 242
    $MUILanguage = "en-GB"
    $MUIFallbackLanguage = 'en-US'
    $SystemLocale = 'en-GB'
    $AddInputLanguages = "0809:00000809"
    $RemoveInputLanguages = "0409:00000409"
    $UserLocale = "en-GB"

    Describe "Pre-flight Checks" -Tag "Integration" {
        Context "Ensure System requires modification" {
            $CurrentState = Get-TargetResource -IsSingleInstance 'Yes'

            It "LocationID requires modification" {
                $CurrentState.LocationID | Should -Not -Be $LocationID
            }

            It "MUILanguage requires modification" {
                $CurrentState.MUILanguage | Should -Not -Be $MUILanguage
            }

            It "MUI Fallback Language requires modification" {
                $CurrentState.MUIFallbackLanguage | Should -Not -Be $MUIFallbackLanguage
            }

            It "System Locale requires modification" {
                $CurrentState.SystemLocale | Should -Not -Be $SystemLocale
            }

            It "$AddInputLanguages keyboard is not already installed" {
                $CurrentState.CurrentInstalledLanguages.Values | Should -Not -Match $AddInputLanguages
            }

            It "$RemoveInputLanguages keyboard should be installed" {
                $CurrentState.CurrentInstalledLanguages.Values | Should -Match $RemoveInputLanguages
            }

            It "User Locale requires modification" {
                $CurrentState.UserLocale | Should -Not -Be $UserLocale
            }
        }
    }


    #region Integration Tests
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $configFile
    if ($env:APPVEYOR -eq $true)
    {
        Write-Warning -Message ('Integration test for {0} will be skipped because appveyor does not support reboots.' -f $script:DSCResourceName)
    }
    else
    {
        Describe "$($script:DSCResourceName)_Integration" -Tag @('Integration', 'RebootRequired') {


            $configMof = (Join-Path -Path $TestDrive -ChildPath 'localhost.mof')
            It 'Should compile the MOF without throwing' {
                {
                    & "$($script:DSCResourceName)_Config" -OutputPath $TestDrive `
                        -LocationID $LocationID `
                        -MUILanguage $MUILanguage `
                        -MUIFallbackLanguage $MUIFallbackLanguage `
                        -SystemLocale $SystemLocale `
                        -AddInputLanguages $AddInputLanguages `
                        -RemoveInputLanguages $RemoveInputLanguages `
                        -UserLocale $UserLocale
                } | Should -Not -Throw
            }

            It 'Should not return a compliant state before being applied' {
                (Test-DscConfiguration -ReferenceConfiguration $configMof -Verbose).InDesiredState | Should -Be $false
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
    }
}
finally
{
    #region FOOTER

    Restore-TestEnvironment -TestEnvironment $TestEnvironment

    #endregion

    # TODO: Other Optional Cleanup Code Goes Here...
}
