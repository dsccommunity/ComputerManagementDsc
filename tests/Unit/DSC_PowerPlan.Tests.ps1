$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'DSC_PowerPlan'

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
        $testCases = @(
            # Power plan as name specified
            @{
                Type = 'Name'
                Name = 'High performance'
            },

            # Power plan as Guid specified
            @{
                Type = 'Guid'
                Name = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
            }
        )

        Describe 'DSC_PowerPlan\Get-TargetResource' {
            Context 'When the system is in the desired present state' {
                BeforeEach {
                    Mock `
                        -CommandName Get-PowerPlan `
                        -MockWith {
                        return @{
                            FriendlyName = 'High performance'
                            Guid         = [System.Guid]'8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
                        }
                    } `
                        -Verifiable

                    Mock `
                        -CommandName Get-ActivePowerPlan `
                        -MockWith {
                        return [System.Guid]'8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
                    } `
                        -Verifiable
                }

                It 'Should return the same values as passed as parameters (power plan specified as <Type>)' -TestCases $testCases {
                    param
                    (
                        [System.String]
                        $Name
                    )

                    $result = Get-TargetResource -Name $Name -IsSingleInstance 'Yes' -Verbose
                    $result.IsSingleInstance | Should -Be 'Yes'
                    $result.Name | Should -Be $Name
                    $result.IsActive | Should -BeTrue
                }
            }

            Context 'When the system is not in the desired present state' {
                BeforeEach {
                    Mock `
                        -CommandName Get-PowerPlan `
                        -MockWith {
                        return @{
                            FriendlyName = 'High performance'
                            Guid         = [System.Guid]'8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
                        }
                    } `
                        -Verifiable

                    Mock `
                        -CommandName Get-ActivePowerPlan `
                        -MockWith {
                        return [System.Guid]'381b4222-f694-41f0-9685-ff5bb260df2e'
                    } `
                        -Verifiable
                }

                It 'Should return an inactive plan (power plan specified as <Type>)' -TestCases $testCases {

                    param
                    (
                        [System.String]
                        $Name
                    )

                    $result = Get-TargetResource -Name $Name -IsSingleInstance 'Yes' -Verbose
                    $result.IsSingleInstance | Should -Be 'Yes'
                    $result.Name | Should -Be $Name
                    $result.IsActive | Should -BeFalse
                }
            }

            Context 'When the preferred plan does not exist' {
                BeforeEach {
                    Mock `
                        -CommandName Get-PowerPlan `
                        -Verifiable
                }

                It 'Should throw the expected error (power plan specified as <Type>)' -TestCases $testCases {

                    param
                    (
                        [System.String]
                        $Name
                    )

                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($script:localizedData.PowerPlanNotFound -f $Name)

                    { Get-TargetResource -Name $Name -IsSingleInstance 'Yes' -Verbose } | Should -Throw $errorRecord
                }

                Assert-VerifiableMock
            }
        }

        Describe 'DSC_PowerPlan\Set-TargetReource' {
            BeforeEach {
                Mock `
                    -CommandName Get-PowerPlan `
                    -MockWith {
                    return @{
                        FriendlyName = 'High performance'
                        Guid         = [System.Guid]'8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
                    }
                } `
                    -Verifiable

                Mock `
                    -CommandName Set-ActivePowerPlan `
                    -Verifiable
            }

            Context 'When the system is not in the desired present state' {
                It 'Should call Get-PowerPlan once (power plan specified as <Type>)' -TestCases $testCases {
                    param
                    (
                        [System.String]
                        $Name
                    )

                    Set-TargetResource -Name $Name -IsSingleInstance 'Yes' -Verbose

                    Assert-MockCalled -CommandName Get-PowerPlan -Exactly -Times 1 -Scope It
                }

                It 'Should call Set-ActivePowerPlan once (power plan specified as <Type>)' -TestCases $testCases {
                    param
                    (
                        [System.String]
                        $Name
                    )

                    Set-TargetResource -Name $Name -IsSingleInstance 'Yes' -Verbose

                    Assert-MockCalled `
                        -CommandName Set-ActivePowerPlan `
                        -Exactly `
                        -Times 1 `
                        -Scope It `
                        -ParameterFilter { $PowerPlanGuid -eq '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c' }
                }
            }

            Context 'When the preferred plan does not exist' {
                BeforeEach {
                    Mock `
                        -CommandName Get-PowerPlan `
                        -Verifiable
                }

                It 'Should throw the expected error (power plan specified as <Type>)' -TestCases $testCases {
                    param
                    (
                        [System.String]
                        $Name
                    )

                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($script:localizedData.PowerPlanNotFound -f $Name)

                    { Set-TargetResource -Name $Name -IsSingleInstance 'Yes' -Verbose } | Should -Throw $errorRecord
                }
            }

            Assert-VerifiableMock
        }

        Describe 'DSC_PowerPlan\Test-TargetResource' {
            Context 'When the system is in the desired present state' {
                BeforeEach {
                    Mock `
                        -CommandName Get-PowerPlan `
                        -MockWith {
                        return @{
                            FriendlyName = 'High performance'
                            Guid         = [System.Guid]'8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
                        }
                    } `
                        -Verifiable

                    Mock `
                        -CommandName Get-ActivePowerPlan `
                        -MockWith {
                        return [System.Guid]'8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
                    } `
                        -Verifiable
                }


                It 'Should return the the state as present ($true) (power plan specified as <Type>)' -TestCases $testCases {
                    param
                    (
                        [System.String]
                        $Name
                    )

                    Test-TargetResource -Name $Name -IsSingleInstance 'Yes' -Verbose | Should -BeTrue
                }
            }

            Context 'When the system is not in the desired state' {
                BeforeEach {
                    Mock `
                        -CommandName Get-PowerPlan `
                        -MockWith {
                        return @{
                            FriendlyName = 'High performance'
                            Guid         = [System.Guid]'8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
                        }
                    } `
                        -Verifiable

                    Mock `
                        -CommandName Get-ActivePowerPlan `
                        -MockWith {
                        return [System.Guid]'381b4222-f694-41f0-9685-ff5bb260df2e'
                    } `
                        -Verifiable
                }

                It 'Should return the the state as absent ($false) (power plan specified as <Type>)' -TestCases $testCases {
                    param
                    (
                        [System.String]
                        $Name
                    )

                    Test-TargetResource -Name $Name -IsSingleInstance 'Yes' -Verbose | Should -BeFalse
                }
            }

            Assert-VerifiableMock
        }
    }
}
finally
{
    Invoke-TestCleanup
}
