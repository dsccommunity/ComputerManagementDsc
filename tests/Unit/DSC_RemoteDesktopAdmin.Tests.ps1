$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'DSC_RemoteDesktopAdmin'

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
        $mockGetTargetResourcePresentSecure = @{
            IsSingleInstance   = 'Yes'
            Ensure             = 'Present'
            UserAuthentication = 'Secure'
        }

        $mockGetTargetResourcePresentNonSecure = @{
            IsSingleInstance   = 'Yes'
            Ensure             = 'Present'
            UserAuthentication = 'NonSecure'
        }

        $mockGetTargetResourceAbsentNonSecure = @{
            IsSingleInstance   = 'Yes'
            Ensure             = 'Absent'
            UserAuthentication = 'NonSecure'
        }

        Describe 'DSC_RemoteDesktopAdmin\Get-TargetResource' {
            Context 'When Remote Desktop Admin settings exist' {
                It 'Should return the correct values when Ensure is Present' {
                    Mock -CommandName Get-ItemProperty `
                        -ParameterFilter { $Name -eq 'fDenyTSConnections' } `
                        -MockWith { @{fDenyTSConnections = 0 } }

                    Mock -CommandName Get-ItemProperty `
                        -ParameterFilter { $Name -eq 'UserAuthentication' } `
                        -MockWith { @{UserAuthentication = 0 } }

                    $targetResource = Get-TargetResource -IsSingleInstance 'Yes'
                    $targetResource.Ensure | Should -Be 'Present'
                }

                It 'Should return the correct values when Ensure is Absent' {
                    Mock -CommandName Get-ItemProperty `
                        -ParameterFilter { $Name -eq 'fDenyTSConnections' } `
                        -MockWith { @{fDenyTSConnections = 1 } }

                    Mock -CommandName Get-ItemProperty `
                        -ParameterFilter { $Name -eq 'UserAuthentication' } `
                        -MockWith { @{UserAuthentication = 0 } }

                    $targetResource = Get-TargetResource -IsSingleInstance 'Yes'
                    $targetResource.Ensure | Should -Be 'Absent'
                }

                It 'Should return the correct values when UserAuthentication is NonSecure' {
                    Mock -CommandName Get-ItemProperty `
                        -ParameterFilter { $Name -eq 'fDenyTSConnections' } `
                        -MockWith { @{fDenyTSConnections = 0 } }

                    Mock -CommandName Get-ItemProperty `
                        -ParameterFilter { $Name -eq 'UserAuthentication' } `
                        -MockWith { @{UserAuthentication = 0 } } `

                    $result = Get-TargetResource -IsSingleInstance 'Yes'
                    $result.UserAuthentication | Should -Be 'NonSecure'
                }

                It 'Should return the correct values when UserAuthentication is Secure' {
                    Mock -CommandName Get-ItemProperty `
                        -ParameterFilter { $Name -eq 'fDenyTSConnections' } `
                        -MockWith { @{fDenyTSConnections = 0 } }

                    Mock -CommandName Get-ItemProperty `
                        -ParameterFilter { $Name -eq 'UserAuthentication' } `
                        -MockWith { @{UserAuthentication = 1 } } `

                    $result = Get-TargetResource -IsSingleInstance 'Yes'
                    $result.UserAuthentication | Should -Be 'Secure'
                }
            }
        }

        Describe 'DSC_RemoteDesktopAdmin\Test-TargetResource' {
            Context 'When the system is in the desired state' {
                It 'Should return true when Ensure is present' {
                    Mock -CommandName Get-TargetResource `
                        -MockWith { $mockGetTargetResourcePresentSecure }

                    Test-TargetResource -IsSingleInstance 'yes' `
                        -Ensure 'Present' | Should Be $true
                }

                It 'Should return true when Ensure is absent' {
                    Mock -CommandName Get-TargetResource `
                        -MockWith { $mockGetTargetResourceAbsentNonSecure }

                    Test-TargetResource  -IsSingleInstance 'yes' `
                        -Ensure 'Absent' | Should Be $true
                }

                It 'Should return true when User Authentication is Secure' {
                    Mock -CommandName Get-TargetResource `
                        -MockWith { $mockGetTargetResourcePresentSecure }

                    Test-TargetResource  -IsSingleInstance 'yes' `
                        -Ensure 'Present' `
                        -UserAuthentication 'Secure' | Should Be $true
                }

                It 'Should return true when User Authentication is NonSecure' {
                    Mock -CommandName Get-TargetResource `
                        -MockWith { $mockGetTargetResourcePresentNonSecure }

                    Test-TargetResource -IsSingleInstance 'yes' `
                        -Ensure 'Present' `
                        -UserAuthentication 'NonSecure' | Should Be $true
                }
            }

            Context 'When the system is not in the desired state' {
                It 'Should return false when Ensure is present' {
                    Mock -CommandName Get-TargetResource `
                        -MockWith { $mockGetTargetResourcePresentSecure }

                    Test-TargetResource -IsSingleInstance 'yes' `
                        -Ensure 'Absent' | Should Be $false
                }

                It 'Should return false when Ensure is absent' {
                    Mock -CommandName Get-TargetResource `
                        -MockWith { $mockGetTargetResourceAbsenttNonSecure }

                    Test-TargetResource  -IsSingleInstance 'yes' `
                        -Ensure 'Present' | Should Be $false
                }

                It 'Should return false if User Authentication is Secure' {
                    Mock -CommandName Get-TargetResource `
                        -MockWith { $mockGetTargetResourcePresentSecure }

                    Test-TargetResource -IsSingleInstance 'yes' `
                        -Ensure 'Present' `
                        -UserAuthentication 'NonSecure' | Should Be $false
                }

                It 'Should return false if User Authentication is NonSecure' {
                    Mock -CommandName Get-TargetResource `
                        -MockWith { $mockGetTargetResourcePresentNonSecure }

                    Test-TargetResource -IsSingleInstance 'yes' `
                        -Ensure 'Present' `
                        -UserAuthentication 'Secure' | Should Be $false
                }
            }
        }

        Describe 'DSC_RemoteDesktopAdmin\Set-TargetResource' {
            Context 'When the state needs to be changed' {
                BeforeEach {
                    Mock -CommandName Set-ItemProperty
                }

                It 'Should set the state to Present' {
                    Mock -CommandName Get-TargetResource `
                        -MockWith { $mockGetTargetResourceAbsentNonSecure }

                    Set-TargetResource -IsSingleInstance 'yes' -Ensure 'Present'
                    Assert-MockCalled -CommandName Set-ItemProperty `
                        -ParameterFilter { $Name -eq 'fDenyTSConnections' -and $Value -eq '0' }`
                        -Times 1 -Exactly
                }

                It 'Should set the state to Absent' {
                    Mock -CommandName Get-TargetResource `
                        -MockWith { $mockGetTargetResourcePresentNonSecure }

                    Set-TargetResource -IsSingleInstance 'yes' -Ensure 'Absent'
                    Assert-MockCalled -CommandName Set-ItemProperty `
                        -ParameterFilter { $Name -eq 'fDenyTSConnections' -and $Value -eq '1' }`
                        -Times 1 -Exactly
                }

                It 'Should set UserAuthentication to Secure' {
                    Mock -CommandName Get-TargetResource `
                        -MockWith { $mockGetTargetResourcePresentNonSecure }

                    Set-TargetResource -IsSingleInstance 'yes' -Ensure 'Present' -UserAuthentication 'Secure'
                    Assert-MockCalled -CommandName Set-ItemProperty `
                        -ParameterFilter { $Name -eq 'UserAuthentication' -and $Value -eq '1' }`
                        -Times 1 -Exactly
                }

                It 'Should set UserAuthentication to NonSecure' {
                    Mock -CommandName Get-TargetResource `
                        -MockWith { $mockGetTargetResourcePresentSecure }

                    Set-TargetResource -IsSingleInstance 'yes' -Ensure 'Present' -UserAuthentication 'NonSecure'
                    Assert-MockCalled -CommandName Set-ItemProperty `
                        -ParameterFilter { $Name -eq 'UserAuthentication' -and $Value -eq '0' }`
                        -Times 1 -Exactly
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
