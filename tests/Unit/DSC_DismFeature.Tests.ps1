[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', 'global:DSCMachineStatus')]
param ()

$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'DSC_DismFeature'

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

try
{
    InModuleScope $script:dscResourceName {
        $mockTestEnabledFeature1 = 'Feature1'
        $mockTestDisabledFeature1 = 'Feature2'
        $mockTestUnknownStateFeature1 = 'Feature3'
        $mockTestNonExistenceFeature1 = 'FeatureX'

        Describe 'DismFeature/Get-TargetResource' {
            BeforeAll {
                Mock -CommandName Get-DismFeatures -MockWith {
                    return @{
                        $mockTestEnabledFeature1      = 'Enabled'
                        $mockTestDisabledFeature1     = 'Disabled'
                        $mockTestUnknownStateFeature1 = 'Unknown'
                    }
                }
            }

            Context 'Feature does not exist' {
                It 'Should throw the correct exception' {
                    $mockExpectedErrorMessage = $script:localizedData.UnknownFeature -f $mockTestNonExistenceFeature1

                    { Get-TargetResource -Name $mockTestNonExistenceFeature1 -Verbose } | Should -Throw $mockExpectedErrorMessage
                }
            }

            Context 'Feature exists and is enabled' {
                It 'Should return the "Present" hashtable' {
                    $getTargetResourceResult = Get-TargetResource -Name $mockTestEnabledFeature1 -Verbose

                    $getTargetResourceResult.Ensure | Should -Be 'Present'
                    $getTargetResourceResult.Name | Should -Be $mockTestEnabledFeature1
                }
            }

            Context 'Feature exists and is disabled' {
                It 'Should return the "Absent" hashtable' {
                    $getTargetResourceResult = Get-TargetResource -Name $mockTestDisabledFeature1 -Verbose

                    $getTargetResourceResult.Ensure | Should -Be 'Absent'
                    $getTargetResourceResult.Name | Should -Be $mockTestDisabledFeature1
                }
            }

            Context 'Feature exists but the status is neither enabled nor disabled' {
                It 'Should return the "Absent" hashtable' {
                    $getTargetResourceResult = Get-TargetResource -Name $mockTestUnknownStateFeature1 -Verbose

                    $getTargetResourceResult.Ensure | Should -Be 'Absent'
                    $getTargetResourceResult.Name | Should -Be $mockTestUnknownStateFeature1
                }
            }
        }

        Describe 'DismFeature/Set-TargetResource' {
            BeforeAll {
                $mockTestSourcePath1 = 'TestDrive:\TestFolder'

                Mock -CommandName Invoke-Dism
            }

            Context 'Ensure set to "Present" and Source parameter not specified' {
                It 'Should call dism.exe with correct arguments' {
                    { Set-TargetResource -Ensure 'Present' -Name $mockTestDisabledFeature1 -Verbose } | Should -Not -Throw

                    Assert-MockCalled -CommandName Invoke-Dism -Times 1 -Exactly -Scope It `
                        -ParameterFilter {
                            $Arguments -contains "/Online" -and `
                            $Arguments -contains "/Enable-Feature" -and `
                            $Arguments -contains "/FeatureName:$mockTestDisabledFeature1" -and `
                            $Arguments -notcontains "/Source:$mockTestSourcePath1"
                    }
                }
            }

            Context 'Ensure set to "Present" and Source parameter specified' {
                It 'Should call dism.exe with correct arguments' {
                    { Set-TargetResource -Ensure 'Present' -Name $mockTestDisabledFeature1 -Source $mockTestSourcePath1 -Verbose } | Should -Not -Throw

                    Assert-MockCalled -CommandName Invoke-Dism -Times 1 -Exactly -Scope It `
                        -ParameterFilter {
                            $Arguments -contains "/Online" -and `
                            $Arguments -contains "/Enable-Feature" -and `
                            $Arguments -contains "/FeatureName:$mockTestDisabledFeature1" -and `
                            $Arguments -contains "/Source:$mockTestSourcePath1" -and `
                            $Arguments -contains "/LimitAccess"
                    }
                }
            }

            Context 'Ensure set to "Present" and EnableAllParentFeatures parameter specified' {
                It 'Should call dism.exe with correct arguments' {
                    { Set-TargetResource -Ensure 'Present' -Name $mockTestDisabledFeature1 -EnableAllParentFeatures $true -Verbose } | Should -Not -Throw

                    Assert-MockCalled -CommandName Invoke-Dism -Times 1 -Exactly -Scope It `
                        -ParameterFilter {
                            $Arguments -contains "/Online" -and `
                            $Arguments -contains "/Enable-Feature" -and `
                            $Arguments -contains "/FeatureName:$mockTestDisabledFeature1" -and `
                            $Arguments -contains "/All"
                    }
                }
            }

            Context 'Ensure set to "Absent"' {
                It 'Should call dism.exe with correct arguments' {
                    { Set-TargetResource -Ensure 'Absent' -Name $mockTestDisabledFeature1 -Verbose } | Should -Not -Throw

                    Assert-MockCalled -CommandName Invoke-Dism -Times 1 -Exactly -Scope It `
                        -ParameterFilter {
                            $Arguments -contains "/Online" -and `
                            $Arguments -contains "/Disable-Feature" -and `
                            $Arguments -contains "/FeatureName:$mockTestDisabledFeature1"
                    }
                }
            }

            Context 'When a reboot is required' {
                BeforeAll {
                    Mock -CommandName Test-Path -MockWith {
                        return $true
                    } -ParameterFilter {
                        $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
                    }
                }

                AfterEach {
                    Remove-Variable -Name 'DSCMachineStatus' -Scope Global -Force -ErrorAction 'SilentlyContinue'
                }

                It 'Should set $global:DSCMachineStatus to 1 when "RebootPending" reg key is exist' {
                    { Set-TargetResource -Ensure 'Absent' -Name $mockTestDisabledFeature1 -Verbose } | Should -Not -Throw

                    $global:DSCMachineStatus | Should -Be 1
                }

                It 'Should not set $global:DSCMachineStatus when suppressing restart' {
                    { Set-TargetResource -Ensure 'Absent' -Name $mockTestDisabledFeature1 -SuppressRestart $true -Verbose } | Should -Not -Throw

                    $global:DSCMachineStatus | Should -BeNullOrEmpty
                }
            }

            Context 'When reboot is not required' {
                BeforeAll {
                    Mock -CommandName Test-Path -MockWith {
                        return $false
                    } -ParameterFilter {
                        $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
                    }
                }

                AfterEach {
                    Remove-Variable -Name 'DSCMachineStatus' -Scope Global -Force -ErrorAction 'SilentlyContinue'
                }

                It 'Should not set $global:DSCMachineStatus when "RebootPending" reg key is not exist' {
                    { Set-TargetResource -Ensure 'Absent' -Name $mockTestDisabledFeature1 -Verbose } | Should -Not -Throw

                    $global:DSCMachineStatus | Should -BeNullOrEmpty
                }
            }
        }

        Describe 'DismFeature/Test-TargetResource' {
            BeforeAll {
                Mock Get-TargetResource {
                    return @{
                        Ensure = 'Present'
                        Name   = $mockTestEnabledFeature1
                    }
                } -ParameterFilter {
                    $Name -eq $mockTestEnabledFeature1
                }

                Mock Get-TargetResource {
                    return @{
                        Ensure = 'Absent'
                        Name   = $mockTestDisabledFeature1
                    }
                } -ParameterFilter {
                    $Name -eq $mockTestDisabledFeature1
                }
            }

            Context 'Feature is in the desired state' {
                It 'Should return $true when Ensure set to Present and Feature is enabled' {
                    $testTargetResourceResult = Test-TargetResource -Ensure 'Present' -Name $mockTestEnabledFeature1 -Verbose

                    $testTargetResourceResult | Should -BeTrue
                }

                It 'Should return $true when Ensure set to Absent and Feature is disabled' {
                    $testTargetResourceResult = Test-TargetResource -Ensure 'Absent' -Name $mockTestDisabledFeature1 -Verbose

                    $testTargetResourceResult | Should -BeTrue
                }
            }

            Context 'Feature is not in the desired state' {
                It 'Should return $false when Ensure set to Present and Feature is disabled' {
                    $testTargetResourceResult = Test-TargetResource -Ensure 'Present' -Name $mockTestDisabledFeature1 -Verbose

                    $testTargetResourceResult | Should -BeFalse
                }

                It 'Should return $false when Ensure set to Absent and Feature is enabled' {
                    $testTargetResourceResult = Test-TargetResource -Ensure 'Absent' -Name $mockTestEnabledFeature1 -Verbose

                    $testTargetResourceResult | Should -BeFalse
                }
            }
        }

        Describe 'DismFeature/Get-DismFeatures' {
            BeforeAll {
                $mockValidDismGetFeaturesOutput = @"

Deployment Image Servicing and Management tool
Version: 10.0.17134.1

Image Version: 10.0.17134.48

Features listing for package : Microsoft-Windows-Foundation-Package~31bf3856ad364e35~amd64~~10.0.17134.1

Feature Name : $mockTestEnabledFeature1
State : Enabled

Feature Name : $mockTestDisabledFeature1
State : Disabled

The operation completed successfully.
"@
            }

            Context 'Valid dism output' {
                It 'Should return the correct hashtable' {
                    Mock -CommandName Invoke-Dism {
                        return $mockValidDismGetFeaturesOutput.Split("`n`r")
                    }

                    $getDismFeaturesResult = Get-DismFeatures -Verbose

                    $getDismFeaturesResult.Count | Should -Be 2
                    $getDismFeaturesResult[$mockTestEnabledFeature1] | Should -Be 'Enabled'
                    $getDismFeaturesResult[$mockTestDisabledFeature1] | Should -Be 'Disabled'
                }

            }

            Context 'Invalid dism output' {
                It 'Should return the empty hashtable' {
                    Mock -CommandName Invoke-Dism -MockWith {
                        return ''
                    }

                    $getDismFeaturesResult = Get-DismFeatures -Verbose

                    $getDismFeaturesResult | Should -BeOfType System.Collections.Hashtable
                    $getDismFeaturesResult.Count | Should -Be 0
                }

            }
        }

        Describe 'DismFeature/Invoke-Dism' {
            BeforeAll {
                # Placeholder to be able to mock calls to dism.exe
                function dism.exe {}
            }

            AfterEach {
                Remove-Variable -Name 'LASTEXITCODE' -Scope Script -Force -ErrorAction 'SilentlyContinue'
            }

            Context 'When a call to dism.exe is not successful' {
                BeforeAll {
                    $errorMessage = 'mocked error'

                    Mock -CommandName dism.exe -MockWith {
                        # We want to set the $LASTEXITCODE in the resource code.
                        $script:LASTEXITCODE = 1

                        return $errorMessage
                    }
                }

                It 'Should throw the correct error message' {
                    { Invoke-Dism -Arguments '/MockArgument1' -Verbose } | Should -Throw $errorMessage
                }
            }

            Context 'When a call to dism.exe is successful' {
                BeforeAll {
                    Mock -CommandName dism.exe -MockWith {
                        # We want to set the $LASTEXITCODE in the resource code.
                        $script:LASTEXITCODE = 0
                    }
                }

                It 'Should call dism.exe without throwing an exception' {
                    { Invoke-Dism -Arguments '/MockArgument1' -Verbose } | Should -Not -Throw
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}

