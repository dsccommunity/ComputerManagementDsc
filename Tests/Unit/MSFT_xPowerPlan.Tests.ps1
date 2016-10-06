$script:DSCModuleName      = 'xComputerManagement' 
$script:DSCResourceName    = 'MSFT_xPowerPlan' 

#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName 'xComputerManagement' `
    -DSCResourceName 'xPowerPlan' `
    -TestType Unit 

#endregion HEADER

function Invoke-TestSetup {
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{

    Invoke-TestSetup

    Describe "$($script:DSCResourceName)\Get-TargetResource" {
        Context 'When the system is in the desired present state' {
            BeforeEach {
                Mock -CommandName Get-CimInstance -MockWith {
                    return New-Object Object | 
                        Add-Member -MemberType NoteProperty -Name IsActive -Value $true -PassThru -Force
                } -ModuleName $script:DSCResourceName -Verifiable

                $ensureState = 'Present'
                $planName = 'High performance'

                $testParameters = @{
                    Ensure = $ensureState
                    Name = $planName
                }
            }

            It 'Should return the same values as passed as parameters' {
                $result = Get-TargetResource @testParameters
                $result.Ensure | Should Be $ensureState
                $result.Name | Should Be $planName
            }
        }

        Context 'When the system is in the desired present state (using default parameter value)' {
            BeforeEach {
                Mock -CommandName Get-CimInstance -MockWith {
                    return New-Object Object | 
                        Add-Member -MemberType NoteProperty -Name IsActive -Value $true -PassThru -Force
                } -ModuleName $script:DSCResourceName -Verifiable

                $ensureState = 'Present'

                $testParameters = @{
                    Ensure = $ensureState
                }
            }

            It 'Should return the same values as passed as parameters' {
                $result = Get-TargetResource @testParameters
                $result.Ensure | Should Be $ensureState
                $result.Name | Should Be 'High performance'
            }
        }        

        Context 'When the system is in the desired absent state' {
            BeforeEach {
                Mock -CommandName Get-CimInstance -MockWith {
                    return New-Object Object | 
                        Add-Member -MemberType NoteProperty -Name IsActive -Value $true -PassThru -Force
                } -ModuleName $script:DSCResourceName -Verifiable

                $ensureState = 'Absent'
                $planName = 'Balanced'

                $testParameters = @{
                    Ensure = $ensureState
                }
            }

            It 'Should return the same value as passed in the Ensure parameter' {
                $result = Get-TargetResource @testParameters
                $result.Ensure | Should Be $ensureState
            }

            It 'Should return the plan name as Balanced' {
                $result = Get-TargetResource @testParameters
                $result.Name | Should Be $planName
            }
        }

        Context 'When the system is not in the desired present state' {
            BeforeEach {
                Mock -CommandName Get-CimInstance -MockWith {
                    return New-Object Object | 
                        Add-Member -MemberType NoteProperty -Name IsActive -Value $false -PassThru -Force
                } -ModuleName $script:DSCResourceName -Verifiable

                $ensureState = 'Present'
                $planName = 'High performance'

                $testParameters = @{
                    Ensure = $ensureState
                    Name = $planName
                }
            }

            It 'Should return the same value as passed in the Ensure parameter' {
                $result = Get-TargetResource @testParameters
                $result.Ensure | Should Be $ensureState
            }

            It 'Should not return any plan name' {
                $result = Get-TargetResource @testParameters
                $result.Name | Should Be $null
            }
        }
    
        Context 'When the system is not in the desired absent state' {
            BeforeEach {
                Mock -CommandName Get-CimInstance -MockWith {
                    return New-Object Object | 
                        Add-Member -MemberType NoteProperty -Name IsActive -Value $false -PassThru -Force
                } -ModuleName $script:DSCResourceName -Verifiable

                $ensureState = 'Absent'

                $testParameters = @{
                    Ensure = $ensureState
                }
            }

            It 'Should return the same value as passed in the Ensure parameter' {
                $result = Get-TargetResource @testParameters
                $result.Ensure | Should Be $ensureState
            }

            It 'Should not return any plan name' {
                $result = Get-TargetResource @testParameters
                $result.Name | Should Be $null
            }
        }

        Context 'When the Get-CimInstance cannot retrive information about power plans' {
            BeforeEach {
                Mock -CommandName Get-CimInstance -MockWith {
                    throw
                } -ModuleName $script:DSCResourceName -Verifiable

                $ensureState = 'Absent'

                $testParameters = @{
                    Ensure = $ensureState
                }
            }

            It 'Should throw an error' {
                { Get-TargetResource @testParameters } | Should Throw
            }
        }

        Context 'When the preferred plan does not exist' {
            BeforeEach {
                Mock -CommandName Get-CimInstance -MockWith {
                    return $null
                } -ModuleName $script:DSCResourceName -Verifiable

                $ensureState = 'Absent'

                $testParameters = @{
                    Ensure = $ensureState
                }
            }

            It 'Should throw saying it was not able to find the plan Balanced' {
                { Get-TargetResource @testParameters } | Should Throw 'Unable to find the power plan Balanced.'
            }
        }

        Assert-VerifiableMocks
    }

    Describe "$($script:DSCResourceName)\Set-TargetResource" {
        BeforeEach {
            Mock -CommandName Invoke-CimMethod -MockWith {} -ModuleName $script:DSCResourceName -Verifiable

            Mock -CommandName Get-CimInstance -MockWith {
                return New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList @('Win32_PowerPlan','dummyNamespace')
            } -ModuleName $script:DSCResourceName -Verifiable
        }

        Context 'When the system is not in the desired present state' {
            BeforeEach {
                $testParameters = @{
                    Ensure = 'Present'
                    Name = 'High performance'
                }
            }

            It 'Should call the mocked function Invoke-CimMethod exactly once' {
                Set-TargetResource @testParameters

                Assert-MockCalled -CommandName Invoke-CimMethod -Exactly 1 -Scope It -ModuleName $script:DSCResourceName
            }
        }

        Context 'When the system is not in the desired absent state' {
            BeforeEach {
                $testParameters = @{
                    Ensure = 'Absent'
                }
            }

            It 'Should call the mocked function Invoke-CimMethod exactly once' {
                Set-TargetResource @testParameters

                Assert-MockCalled -CommandName Invoke-CimMethod -Exactly 1 -Scope It -ModuleName $script:DSCResourceName
            }
        }

        Context 'When the Invoke-CimMethod throws an error' {
            BeforeEach {
                Mock -CommandName Invoke-CimMethod -MockWith {
                    throw
                } -ModuleName $script:DSCResourceName -Verifiable

                $ensureState = 'Absent'

                $testParameters = @{
                    Ensure = $ensureState
                }
            }

            It 'Should throw an error' {
                { Set-TargetResource @testParameters } | Should Throw
            }
        }

        Assert-VerifiableMocks
    }

    Describe "$($script:DSCResourceName)\Test-TargetResource" {
        Context 'When the system is in the desired present state' {
            BeforeEach {
                Mock -CommandName Get-CimInstance -MockWith {
                    return New-Object Object | 
                        Add-Member -MemberType NoteProperty -Name IsActive -Value $true -PassThru -Force
                } -ModuleName $script:DSCResourceName -Verifiable

                $testParameters = @{
                    Ensure = 'Present'
                    Name = 'High performance'
                }
            }

            It 'Should return the the state as present ($true)' {
                Test-TargetResource @testParameters | Should Be $true
            }
        }

        Context 'When the system is in the desired absent state' {
            BeforeEach {
                Mock -CommandName Get-CimInstance -MockWith {
                    return New-Object Object | 
                        Add-Member -MemberType NoteProperty -Name IsActive -Value $true -PassThru -Force
                } -ModuleName $script:DSCResourceName -Verifiable

                $testParameters = @{
                    Ensure = 'Absent'
                }
            }

            It 'Should return the the state as present ($true)' {
                Test-TargetResource @testParameters | Should Be $true
            }
        }

        Context 'When the system is not in the desired state' {
            BeforeEach {
                Mock -CommandName Get-CimInstance -MockWith {
                    return New-Object Object | 
                        Add-Member -MemberType NoteProperty -Name IsActive -Value $false -PassThru -Force
                } -ModuleName $script:DSCResourceName -Verifiable

                $testParameters = @{
                    Ensure = 'Present'
                    Name = 'High performance'
                }
            }

            It 'Should return the the state as absent ($false)' {
                Test-TargetResource @testParameters | Should Be $false
            }
        }

        Assert-VerifiableMocks
    }
}
finally
{
    Invoke-TestCleanup
}
