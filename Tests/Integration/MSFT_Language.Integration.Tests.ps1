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
            $CurrentState = Get-TargetResource -IsSingleInstance "Yes"
            It "LocationID requires modification"        {
                $CurrentState.LocationID | Should Not Be $LocationID
            }

            It "MUILanguage requires modification"        {
                #$CurrentState = Get-TargetResource -IsSingleInstance "Yes"
                $CurrentState.MUILanguage | Should Not Be $MUILanguage
            }

            It "MUI Fallback Language requires modification"        {
                #$CurrentState = Get-TargetResource -IsSingleInstance "Yes"
                $CurrentState.MUIFallbackLanguage | Should Not Be $MUIFallbackLanguage
            }
            
            It "System Locale requires modification"        {
                #$CurrentState = Get-TargetResource -IsSingleInstance "Yes"
                $CurrentState.SystemLocale | Should Not Be $SystemLocale
            }

            It "$AddInputLanguages keyboard is not already installed"        {
                #$CurrentState = Get-TargetResource -IsSingleInstance "Yes"
                $CurrentState.CurrentInstalledLanguages.Values | Should Not Match $AddInputLanguages
            }

            It "$RemoveInputLanguages keyboard should be installed"        {
                #$CurrentState = Get-TargetResource -IsSingleInstance "Yes"
                $CurrentState.CurrentInstalledLanguages.Values | Should Match $RemoveInputLanguages
            }

            It "User Locale requires modification"        {
                #$CurrentState = Get-TargetResource -IsSingleInstance "Yes"
                $CurrentState.UserLocale | Should Not Be $UserLocale
            }
        }
    }

    #region Integration Tests
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName).config.ps1"
    . $configFile

    Describe "$($script:DSCResourceName)_Integration" -Tag "Integration","RebootRequired" {
        #region DEFAULT TESTS
        It 'Should compile and apply the MOF without throwing' {
            {
                & "$($script:DSCResourceName)_Config" -OutputPath $TestDrive `
                    -LocationID $LocationID `
                    -MUILanguage $MUILanguage `
                    -MUIFallbackLanguage $MUIFallbackLanguage `
                    -SystemLocale $SystemLocale `
                    -AddInputLanguages $AddInputLanguages `
                    -RemoveInputLanguages $RemoveInputLanguages `
                    -UserLocale $UserLocale
                Start-DscConfiguration -Path $TestDrive `
                    -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        It 'Resource Test should return true' {
            Test-TargetResource -IsSingleInstance "Yes" `
                -LocationID $LocationID `
                -MUILanguage $MUILanguage `
                -MUIFallbackLanguage $MUIFallbackLanguage `
                -SystemLocale $SystemLocale `
                -AddInputLanguages $AddInputLanguages `
                -RemoveInputLanguages $RemoveInputLanguages `
                -UserLocale $UserLocale `
                -CopySystem $true `
                -CopyNewUser $true | Should Be $true
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
