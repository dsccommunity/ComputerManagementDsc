#region HEADER
$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'MSFT_RemoteDesktopAdmin'

# Unit Test Template Version: 1.2.4
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath 'DscResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -ResourceType 'Mof' `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup
{
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

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

        Describe 'MSFT_RemoteDesktopAdmin\Get-TargetResource' {
            Context 'When Remote Desktop Admin settings exist' {
                It 'Should return the correct values when Ensure is Present' {
                    Mock -CommandName Get-ItemProperty `
                        -ParameterFilter { $Name -eq 'fDenyTSConnections' } `
                        -MockWith { @{fDenyTSConnections = 0} }

                    Mock -CommandName Get-ItemProperty `
                        -ParameterFilter { $Name -eq 'UserAuthentication' } `
                        -MockWith { @{UserAuthentication = 0} }

                    $targetResource = Get-TargetResource -IsSingleInstance 'Yes'
                    $targetResource.Ensure | Should -Be 'Present'
                }

                It 'Should return the correct values when Ensure is Absent' {
                    Mock -CommandName Get-ItemProperty `
                        -ParameterFilter { $Name -eq 'fDenyTSConnections' } `
                        -MockWith { @{fDenyTSConnections = 1} }

                    Mock -CommandName Get-ItemProperty `
                        -ParameterFilter { $Name -eq 'UserAuthentication' } `
                        -MockWith { @{UserAuthentication = 0} }

                    $targetResource = Get-TargetResource -IsSingleInstance 'Yes'
                    $targetResource.Ensure | Should -Be 'Absent'
                }

                It 'Should return the correct values when UserAuthentication is NonSecure' {
                    Mock -CommandName Get-ItemProperty `
                        -ParameterFilter { $Name -eq 'fDenyTSConnections' } `
                        -MockWith { @{fDenyTSConnections = 0} }

                    Mock -CommandName Get-ItemProperty `
                        -ParameterFilter { $Name -eq 'UserAuthentication' } `
                        -MockWith { @{UserAuthentication = 0} } `

                    $result = Get-TargetResource -IsSingleInstance 'Yes'
                    $result.UserAuthentication | Should -Be 'NonSecure'
                }

                It 'Should return the correct values when UserAuthentication is Secure' {
                    Mock -CommandName Get-ItemProperty `
                        -ParameterFilter { $Name -eq 'fDenyTSConnections' } `
                        -MockWith { @{fDenyTSConnections = 0} }

                    Mock -CommandName Get-ItemProperty `
                        -ParameterFilter { $Name -eq 'UserAuthentication' } `
                        -MockWith { @{UserAuthentication = 1} } `

                    $result = Get-TargetResource -IsSingleInstance 'Yes'
                    $result.UserAuthentication | Should -Be 'Secure'
                }
            }
        }

        Describe 'MSFT_RemoteDesktopAdmin\Test-TargetResource' {
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

        Describe 'MSFT_RemoteDesktopAdmin\Set-TargetResource' {
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
