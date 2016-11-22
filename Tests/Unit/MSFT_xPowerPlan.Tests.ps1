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
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit 

#endregion HEADER

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Describe "$($script:DSCResourceName)\Get-TargetResource" {
        BeforeEach {
            $testParameters = @{
                IsSingleInstance = 'Yes'
                Name = 'High performance'
            }
        }
        
        Context 'When the system is in the desired present state' {
            BeforeEach {
                Mock -CommandName Get-CimInstance -MockWith {
                    return New-Object Object | 
                        Add-Member -MemberType NoteProperty -Name IsActive -Value $true -PassThru -Force
                } -ModuleName $script:DSCResourceName -Verifiable
            }

            It 'Should return the same values as passed as parameters' {
                $result = Get-TargetResource @testParameters
                $result.IsSingleInstance | Should Be 'Yes'
                $result.Name | Should Be $testParameters.Name
            }
        }

        Context 'When the system is not in the desired present state' {
            BeforeEach {
                Mock -CommandName Get-CimInstance -MockWith {
                    return New-Object Object | 
                        Add-Member -MemberType NoteProperty -Name IsActive -Value $false -PassThru -Force
                } -ModuleName $script:DSCResourceName -Verifiable
            }

            It 'Should not return any plan name' {
                $result = Get-TargetResource @testParameters
                $result.IsSingleInstance | Should Be 'Yes'
                $result.Name | Should Be $null
            }
        }
    
        Context 'When the Get-CimInstance cannot retrive information about power plans' {
            BeforeEach {
                Mock -CommandName Get-CimInstance -MockWith {
                    throw
                } -ModuleName $script:DSCResourceName -Verifiable
            }

            It 'Should throw the correct error' {
                { Get-TargetResource @testParameters } | Should Throw 'Could not get the Common Information Model (CIM) instances of class Win32_PowerPlan'
            }
        }

        Context 'When the preferred plan does not exist' {
            BeforeEach {
                Mock -CommandName Get-CimInstance -MockWith {
                    return $null
                } -ModuleName $script:DSCResourceName -Verifiable
            }

            It 'Should throw saying it was not able to find the plan High performance' {
                { Get-TargetResource @testParameters } | Should Throw "Unable to find the power plan 'High performance'."
            }
        }

        Assert-VerifiableMocks
    }

    Describe "$($script:DSCResourceName)\Set-TargetResource" {
        BeforeEach {
            $testParameters = @{
                IsSingleInstance = 'Yes'
                Name = 'High performance'
            }

            Mock -CommandName Invoke-CimMethod -MockWith {} -ModuleName $script:DSCResourceName -Verifiable

            Mock -CommandName Get-CimInstance -MockWith {
                return New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList @('Win32_PowerPlan','dummyNamespace')
            } -ModuleName $script:DSCResourceName -Verifiable
        }

        Context 'When the system is not in the desired present state' {
            It 'Should call the mocked function Invoke-CimMethod exactly once' {
                Set-TargetResource @testParameters

                Assert-MockCalled -CommandName Invoke-CimMethod -Exactly 1 -Scope It -ModuleName $script:DSCResourceName
            }
        }

        Context 'When the Get-CimInstance cannot retrive information about power plans' {
            BeforeEach {
                Mock -CommandName Get-CimInstance -MockWith {
                    throw
                } -ModuleName $script:DSCResourceName -Verifiable
            }

            It 'Should throw the correct error' {
                { Set-TargetResource @testParameters } | Should Throw 'Could not get the Common Information Model (CIM) instances of class Win32_PowerPlan'
            }
        }

        Context 'When the Invoke-CimMethod throws an error' {
            BeforeEach {
                Mock -CommandName Invoke-CimMethod -MockWith {
                    throw 'Failed to set value'
                } -ModuleName $script:DSCResourceName -Verifiable
            }

            It 'Should catch the correct error thrown by Invoke-CimMethod' {
                { Set-TargetResource @testParameters } | Should Throw "Unable to set the power plan 'High performance' to the active plan. Error message: Failed to set value"
            }
        }

        Assert-VerifiableMocks
    }

    Describe "$($script:DSCResourceName)\Test-TargetResource" {
        BeforeEach {
            $testParameters = @{
                IsSingleInstance = 'Yes'
                Name = 'High performance'
            }
        }

        Context 'When the system is in the desired present state' {
            BeforeEach {
                Mock -CommandName Get-CimInstance -MockWith {
                    return New-Object Object | 
                        Add-Member -MemberType NoteProperty -Name IsActive -Value $true -PassThru -Force
                } -ModuleName $script:DSCResourceName -Verifiable
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
