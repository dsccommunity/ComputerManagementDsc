#region HEADER
$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'MSFT_PowerPlan'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

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

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    # Assign the localized data from the module into a local variable
    $LocalizedData = InModuleScope $script:dscResourceName {
         $LocalizedData
    }

    $testCases =@(
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

    Describe "$($script:dscResourceName)\Get-TargetResource" {
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
                    -ModuleName $script:dscResourceName `
                    -Verifiable

                Mock `
                    -CommandName Get-ActivePowerPlan `
                    -MockWith {
                    return [System.Guid]'8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
                } `
                    -ModuleName $script:dscResourceName `
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
                    -ModuleName $script:dscResourceName `
                    -Verifiable

                Mock `
                    -CommandName Get-ActivePowerPlan `
                    -MockWith {
                    return [System.Guid]'381b4222-f694-41f0-9685-ff5bb260df2e'
                } `
                    -ModuleName $script:dscResourceName `
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
                    -ModuleName $script:dscResourceName `
                    -Verifiable
            }

            It 'Should throw the expected error (power plan specified as <Type>)' -TestCases $testCases {

                param
                (
                    [System.String]
                    $Name
                )

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($LocalizedData.PowerPlanNotFound -f $Name)

                { Get-TargetResource -Name $Name -IsSingleInstance 'Yes' -Verbose } | Should -Throw $errorRecord
            }

            Assert-VerifiableMock
        }
    }

    Describe "$($script:dscResourceName)\Set-TargetReource" {
        BeforeEach {
            Mock `
                -CommandName Get-PowerPlan `
                -MockWith {
                    return @{
                            FriendlyName = 'High performance'
                            Guid = [System.Guid]'8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
                        }
                } `
                -ModuleName $script:dscResourceName `
                -Verifiable

            Mock `
                -CommandName Set-ActivePowerPlan `
                -ModuleName $script:dscResourceName `
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

                Assert-MockCalled -CommandName Get-PowerPlan -Exactly -Times 1 -Scope It -ModuleName $script:dscResourceName
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
                    -ModuleName $script:dscResourceName `
                    -ParameterFilter {$PowerPlanGuid -eq '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'}
            }
        }

        Context 'When the preferred plan does not exist' {
            BeforeEach {
                Mock `
                -CommandName Get-PowerPlan `
                -ModuleName $script:dscResourceName `
                -Verifiable
            }

            It 'Should throw the expected error (power plan specified as <Type>)' -TestCases $testCases {
                param
                (
                    [System.String]
                    $Name
                )

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($LocalizedData.PowerPlanNotFound -f $Name)

                { Set-TargetResource -Name $Name -IsSingleInstance 'Yes' -Verbose } | Should -Throw $errorRecord
            }
        }

        Assert-VerifiableMock
    }
    Describe "$($script:dscResourceName)\Test-TargetResource" {
        Context 'When the system is in the desired present state' {
            BeforeEach {
                Mock `
                    -CommandName Get-PowerPlan `
                    -MockWith {
                        return @{
                                FriendlyName = 'High performance'
                                Guid = [System.Guid]'8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
                            }
                    } `
                    -ModuleName $script:dscResourceName `
                    -Verifiable

                Mock `
                    -CommandName Get-ActivePowerPlan `
                    -MockWith {
                        return [System.Guid]'8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
                    } `
                    -ModuleName $script:dscResourceName `
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
                                Guid = [System.Guid]'8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
                            }
                    } `
                    -ModuleName $script:dscResourceName `
                    -Verifiable

                Mock `
                    -CommandName Get-ActivePowerPlan `
                    -MockWith {
                        return [System.Guid]'381b4222-f694-41f0-9685-ff5bb260df2e'
                    } `
                    -ModuleName $script:dscResourceName `
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
finally
{
    Invoke-TestCleanup
}
