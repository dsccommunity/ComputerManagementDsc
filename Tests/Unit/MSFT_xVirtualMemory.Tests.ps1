#region HEADER
$script:DSCModuleName      = 'xComputerManagement' 
$script:DSCResourceName    = 'MSFT_xVirtualMemory' 

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) ) {
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force
 
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName  `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup {
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try {
    Invoke-TestSetup

    InModuleScope 'MSFT_xVirtualMemory' {        

        Describe "$($script:DSCResourceName)\Get-TargetResource" {

            BeforeEach {
                $testParameters = @{
                    Drive = 'D:'
                    Type = 'CustomSize'
                }
            }
        
            Context 'When the system is in the desired present state' {
                BeforeEach {
                    Mock -CommandName Get-CimInstance -MockWith {
                        [PSObject] @{ AutomaticManagedPageFile = $false; Name = 'D:\pagefile.sys' }
                    } -ModuleName $script:DSCResourceName -Verifiable
                }

                It 'It should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.Type | Should Be $testParameters.Type
                    $result.Drive | Should Be ([System.IO.DriveInfo]$testParameters.Drive).Name
                }
            }
            
            Context 'When the system is not in the desired present state' {
                BeforeEach {
                    Mock -CommandName Get-CimInstance -MockWith {
                        [PSObject] @{
                        InitialSize = 0
                        MaximumSize = 0
                        Name = "C:\pagefile.sys"
                        }
                    } -ModuleName $script:DSCResourceName -Verifiable
                }

                It 'It should not return a valid type' {
                    $result = Get-TargetResource @testParameters
                    $result.Type | Should Not Be $testParameters.Type
                }
                
                It 'It should not return a valid drive letter' {
                    $result = Get-TargetResource @testParameters
                    $result.Drive | Should Not Be ([System.IO.DriveInfo]$testParameters.Drive).Name
                }
            }

            Assert-VerifiableMocks
        }
        
        Describe "$($script:DSCResourceName)\Set-TargetResource" {                   

            Context 'When the system is not in the desired state' {
                BeforeEach {
                    $testParameters = @{
                        Drive = 'C:'
                        Type = 'CustomSize'
                        InitialSize = 0
                        MaximumSize = 1337
                    }                
                }    
                Mock -CommandName Set-CimInstance -MockWith {} -ModuleName $script:DSCResourceName -Verifiable
                Mock -CommandName New-CimInstance -MockWith {} -ModuleName $script:DSCResourceName -Verifiable
                Mock -CommandName Remove-CimInstance -MockWith {} -ModuleName $script:DSCResourceName -Verifiable
                Mock -CommandName Get-CimInstance -MockWith {} -ModuleName $script:DSCResourceName -Verifiable
                
                It 'Should call the mocked function Set-CimInstance exactly once' {
                    Set-TargetResource @testParameters

                    Assert-MockCalled -CommandName Set-CimInstance -Exactly -Times 1 -Scope It
                }
            }

            
            context 'When an exception is expected' {
                Mock -CommandName Set-CimInstance -MockWith {} -ModuleName $script:DSCResourceName -Verifiable
                Mock -CommandName New-CimInstance -MockWith {} -ModuleName $script:DSCResourceName -Verifiable
                Mock -CommandName Remove-CimInstance -MockWith {} -ModuleName $script:DSCResourceName -Verifiable
                Mock -CommandName Get-CimInstance -MockWith {
                    [PSObject] @{
                        InitialSize = 0
                        MaximumSize = 1338
                        Name = "D:\pagefile.sys"
                        AutomaticManagedPageFile = $false
                        }
                }

                $testParameters = @{
                    Drive = 'abc'
                    Type = 'CustomSize'
                    InitialSize = 0
                    MaximumSize = 1337
                } 
                It 'Should throw if no valid drive letter has been used' {
                    { Set-TargetResource @testParameters } | Should Throw
                }

                $testParameters = @{
                    Drive = 'N:'
                    Type = 'CustomSize'
                    InitialSize = 0
                    MaximumSize = 1337
                } 
                It 'Should throw if the drive is not ready' {
                    { Set-TargetResource @testParameters } | Should Throw
                }
            }

            Assert-VerifiableMocks
        }

        Describe "$($script:DSCResourceName)\Test-TargetResource" {            
            Context 'When a True or False is expected' {
                BeforeEach {
                    $testParameters = @{
                        Drive = 'D:'
                        Type = 'CustomSize'
                        InitialSize = 0
                        MaximumSize = 1337
                    }                
                }

                $pageFileObject = [PSObject] @{
                        InitialSize = 0
                        MaximumSize = 1338
                        Name = "D:\pagefile.sys"
                        AutomaticManagedPageFile = $false
                    }
                    
                Mock -CommandName Get-CimInstance -MockWith {
                    $pageFileObject.MaximumSize = 1337
                    $pageFileObject
                }
                It 'Should return True if the input matches the actual values' {
                    Test-TargetResource @testParameters | Should Be $true
                }

                Mock -CommandName Get-CimInstance -MockWith {
                    $pageFileObject.MaximumSize = 1337
                    $pageFileObject.AutomaticManagedPageFile = $true
                    $pageFileObject
                }
                It 'Should return False if the type is wrong' {
                    Test-TargetResource @testParameters | Should Be $false
                }

                Mock -CommandName Get-CimInstance -MockWith {
                    $pageFileObject.MaximumSize = 1338
                    $pageFileObject
                }
                It 'Should return False if InitialSize and/or MaximumSize do not match' {
                    Test-TargetResource @testParameters | Should Be $false
                }

                Mock -CommandName Get-CimInstance -MockWith {
                    # In this case Get-CimInstance returns an empty object
                }
                It 'Should return False if Name does not match' {
                    Test-TargetResource @testParameters | Should Be $false
                }

            }
        }
    }
}
finally {
    Invoke-TestCleanup
}

