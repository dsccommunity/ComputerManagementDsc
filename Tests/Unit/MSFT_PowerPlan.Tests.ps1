$script:DSCModuleName = 'ComputerManagementDsc'
$script:DSCResourceName = 'MSFT_PowerPlan'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\ComputerManagementDsc'
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
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
    $LocalizedData = InModuleScope $script:DSCResourceName {
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

    Describe "$($script:DSCResourceName)\Get-TargetResource" {
        Context 'When the system is in the desired present state' {
            BeforeEach {
                Mock `
                    -CommandName Get-PowerPlan `
                    -MockWith {
                        return @(
                            [PSCustomObject]@{
                                Name = 'High performance'
                                Guid = [Guid]'8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
                                IsActive = $true
                            }
                        )
                    } `
                    -ModuleName $script:DSCResourceName `
                    -Verifiable
            }

            It 'Should return the same values as passed as parameters (power plan specified as <Type>)' -TestCases $testCases {

                param
                (
                    [String]
                    $Name
                )

                $result = Get-TargetResource -Name $Name -IsSingleInstance 'Yes' -Verbose
                $result.IsSingleInstance | Should -Be 'Yes'
                $result.Name | Should -Be $Name
                $result.IsActive | Should -Be $true
            }
        }

        Context 'When the system is not in the desired present state' {
            BeforeEach {
                Mock `
                    -CommandName Get-PowerPlan `
                    -MockWith {
                        return @(
                            [PSCustomObject]@{
                                Name = 'High performance'
                                Guid = [Guid]'8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
                                IsActive = $false
                            }
                        )
                    } `
                    -ModuleName $script:DSCResourceName `
                    -Verifiable
            }

            It 'Should return an inactive plan (power plan specified as <Type>)' -TestCases $testCases {

                param
                (
                    [String]
                    $Name
                )

                $result = Get-TargetResource -Name $Name -IsSingleInstance 'Yes' -Verbose
                $result.IsSingleInstance | Should -Be 'Yes'
                $result.Name | Should -Be $Name
                $result.IsActive | Should -Be $false
            }
        }

        Context 'When the preferred plan does not exist' {
            BeforeEach {
                Mock `
                    -CommandName Get-PowerPlan `
                    -ModuleName $script:DSCResourceName `
                    -Verifiable
            }

            It 'Should throw the expected error (power plan specified as <Type>)' -TestCases $testCases {

                param
                (
                    [String]
                    $Name
                )

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($LocalizedData.PowerPlanNotFound -f $Name)

                { Get-TargetResource -Name $Name -IsSingleInstance 'Yes' -Verbose } | Should -Throw $errorRecord
            }

        Assert-VerifiableMock
    }
    }
    Describe "$($script:DSCResourceName)\Set-TargetResource" {
        BeforeEach {
            Mock `
            -CommandName Get-PowerPlan `
            -MockWith {
                return @(
                    [PSCustomObject]@{
                        Name = 'High performance'
                        Guid = [Guid]'8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
                        IsActive = $false
                    }
                )
            } `
            -ModuleName $script:DSCResourceName `
            -Verifiable

            Mock `
            -CommandName Set-PowerPlan `
            -ModuleName $script:DSCResourceName `
            -Verifiable
        }

        Context 'When the system is not in the desired present state' {
            It 'Should call Set-PowerPlan once (power plan specified as <Type>)' -TestCases $testCases {

                param
                (
                    [String]
                    $Name
                )

                Set-TargetResource -Name $Name -IsSingleInstance 'Yes' -Verbose

                Assert-MockCalled -CommandName Set-PowerPlan -Exactly -Times 1 -Scope It -ModuleName $script:DSCResourceName
            }
        }

        Context 'When the preferred plan does not exist' {
            BeforeEach {
                Mock `
                    -CommandName Get-PowerPlan `
                    -ModuleName $script:DSCResourceName `
                    -Verifiable
            }

            It 'Should throw the expected error (power plan specified as <Type>)' -TestCases $testCases {

                param
                (
                    [String]
                    $Name
                )

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($LocalizedData.PowerPlanNotFound -f $Name)

                { Set-TargetResource -Name $Name -IsSingleInstance 'Yes' -Verbose } | Should -Throw $errorRecord
            }
        }

        Assert-VerifiableMock
    }
    Describe "$($script:DSCResourceName)\Test-TargetResource" {
        Context 'When the system is in the desired present state' {
            BeforeEach {
                Mock `
                    -CommandName Get-PowerPlan `
                    -MockWith {
                        return @(
                            [PSCustomObject]@{
                                Name = 'High performance'
                                Guid = [Guid]'8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
                                IsActive = $true
                            }
                        )
                    } `
                    -ModuleName $script:DSCResourceName `
                    -Verifiable
            }

            It 'Should return the the state as present ($true) (power plan specified as <Type>)' -TestCases $testCases {

                param
                (
                    [String]
                    $Name
                )

                Test-TargetResource -Name $Name -IsSingleInstance 'Yes' -Verbose | Should -Be $true
            }
        }

        Context 'When the system is not in the desired state' {
            BeforeEach {
                Mock `
                    -CommandName Get-PowerPlan `
                    -MockWith {
                        return @(
                            [PSCustomObject]@{
                                Name = 'High performance'
                                Guid = [Guid]'8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
                                IsActive = $false
                            }
                        )
                    } `
                    -ModuleName $script:DSCResourceName `
                    -Verifiable
            }

            It 'Should return the the state as absent ($false) (power plan specified as <Type>)' -TestCases $testCases {

                param
                (
                    [String]
                    $Name
                )

                Test-TargetResource -Name $Name -IsSingleInstance 'Yes' -Verbose | Should -Be $false
            }
        }

        Assert-VerifiableMock
    }
}
finally
{
    Invoke-TestCleanup
}
