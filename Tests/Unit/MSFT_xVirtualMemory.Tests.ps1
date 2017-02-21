#region HEADER
$script:DSCModuleName      = 'xComputerManagement' 
$script:DSCResourceName    = 'MSFT_xVirtualMemory' 

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force
 
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName 'XComputerManagement' `
    -DSCResourceName 'MSFT_xVirtualMemory' `
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

    InModuleScope 'MSFT_xVirtualMemory' {

        Describe "$($script:DSCResourceName)\Get-TargetResource" {

            BeforeEach {
            $testParameters = @{
                Drive = 'C:'
                Type = 'CustomSize'
                InitialSize = 128
                MaximumSize = 2048
            }
            }
        
            Context 'When the system is in the desired present state' {
                BeforeEach {
                    Mock -CommandName Get-CimInstance -MockWith {
                        return New-Object Object | 
                            Add-Member -MemberType NoteProperty -Name AutomaticManagedPagefile -Value $false -PassThru -Force |
                            Add-MemberType NoteProperty -Name Name -Value "C:\pagefile.sys" -PassThru -Force
                    } -ModuleName $script:DSCResourceName -Verifiable
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.Type | Should Be $testParameters.Type
                    $result.InitialSize | Should Be $testParameters.InitialSize
                    $result.MaximumSize | Should Be $testParameters.MaximumSize
                    $result.Drive | Should Be $testParameters.Drive
                }
            }
            
            <#Context 'When the system is not in the desired present state' {
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
            }#>
        }
        <#
        Describe "$($script:DSCResourceName)\Set-TargetResource" {
            Context '<Context-description>' {
                It 'Should ...test-description' {
                    # test-code
                }
            }
        }

        Describe "$($script:DSCResourceName)\Test-TargetResource" {
            Context '<Context-description>' {
                It 'Should ...test-description' {
                    # test-code
                }
            }
        }#>
    }
}
finally
{
    Invoke-TestCleanup
}

