<#
    .SYNOPSIS
        Unit test for DSC_OfflineDomainJoin DSC resource.

    .NOTES
#>

# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'ComputerManagementDsc'
    $script:dscResourceName = 'DSC_OfflineDomainJoin'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force
}

Describe 'DSC_OfflineDomainJoin\Get-TargetResource' -Tag 'Get' {
    It 'Should return the correct values' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $testOfflineDomainJoin = @{
                IsSingleInstance = 'Yes'
                RequestFile      = 'C:\ODJRequest.txt'
            }

            $result = Get-TargetResource @testOfflineDomainJoin

            $result.IsSingleInstance | Should -Be $testOfflineDomainJoin.IsSingleInstance
            $result.RequestFile | Should -BeNullOrEmpty
        }
    }
}

Describe 'DSC_OfflineDomainJoin\Set-TargetResource' -Tag 'Set' {
    Context 'When Domain is not joined' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                return $true
            }

            Mock -CommandName Join-Domain
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testOfflineDomainJoin = @{
                    IsSingleInstance = 'Yes'
                    RequestFile      = 'C:\ODJRequest.txt'
                }

                { Set-TargetResource @testOfflineDomainJoin } | Should -Not -Throw
            }

            Should -Invoke -CommandName Test-Path -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Join-Domain -Exactly -Times 1 -Scope It
        }

    }

    Context 'When ODJ Request file is not found' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                return $false
            }

            Mock -CommandName Join-Domain
        }

        It 'Should throw expected exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testOfflineDomainJoin = @{
                    IsSingleInstance = 'Yes'
                    RequestFile      = 'C:\ODJRequest.txt'
                }

                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($LocalizedData.RequestFileNotFoundError -f $testOfflineDomainJoin.RequestFile) `
                    -ArgumentName 'RequestFile'

                { Test-TargetResource @testOfflineDomainJoin } | Should -Throw -ExpectedMessage $errorRecord
            }

            Should -Invoke -CommandName Test-Path -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Join-Domain -Exactly -Times 0 -Scope It
        }
    }
}

Describe 'DSC_OfflineDomainJoin\Test-TargetResource' -Tag 'Test' {
    Context 'When Domain is not joined' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                return $true
            }

            Mock -CommandName Get-DomainName -MockWith {
                return $null
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testOfflineDomainJoin = @{
                    IsSingleInstance = 'Yes'
                    RequestFile      = 'C:\ODJRequest.txt'
                }

                Test-TargetResource @testOfflineDomainJoin | Should -BeFalse
            }

            Should -Invoke -CommandName Test-Path -Exactly -Times 1
            Should -Invoke -CommandName Get-DomainName -Exactly -Times 1
        }
    }

    Context 'Domain is already joined' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                return $true
            }

            Mock -CommandName Get-DomainName -MockWith {
                return 'contoso.com'
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testOfflineDomainJoin = @{
                    IsSingleInstance = 'Yes'
                    RequestFile      = 'C:\ODJRequest.txt'
                }

                Test-TargetResource @testOfflineDomainJoin | Should -BeTrue
            }

            Should -Invoke -CommandName Test-Path -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-DomainName -Exactly -Times 1 -Scope It
        }
    }

    Context 'When ODJ Request file is not found' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                return $false
            }

            Mock -CommandName Get-DomainName -MockWith {
                return 'contoso.com'
            }
        }

        It 'Should throw expected exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testOfflineDomainJoin = @{
                    IsSingleInstance = 'Yes'
                    RequestFile      = 'C:\ODJRequest.txt'
                }

                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($LocalizedData.RequestFileNotFoundError -f $testOfflineDomainJoin.RequestFile) `
                    -ArgumentName 'RequestFile'

                { Test-TargetResource @testOfflineDomainJoin } | Should -Throw $errorRecord
            }

            Should -Invoke -CommandName Test-Path -Exactly -Times 1
            Should -Invoke -CommandName Get-DomainName -Exactly -Times 0
        }
    }
}

Describe 'DSC_OfflineDomainJoin\Join-Domain' -Tag 'Private' {
    Context 'When Domain Join is successful' {
        BeforeAll {
            Mock -CommandName djoin.exe -MockWith {
                return 'OK'
            }
        }

        It 'Should not throw' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $LASTEXITCODE = 0

                { Join-Domain -RequestFile 'c:\doesnotmatter.txt' } | Should -Not -Throw
            }

            Should -Invoke -CommandName djoin.exe -Exactly -Times 1 -Scope It
        }
    }

    Context 'When Domain Join is unsuccessful' {
        BeforeAll {
            Mock -CommandName djoin.exe -MockWith {
                return 'ERROR'
            }
        }

        It 'Should throw' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $LASTEXITCODE = 99
                $errorRecord = Get-InvalidOperationRecord -Message ($LocalizedData.DjoinError -f $LASTEXITCODE)

                { Join-Domain -RequestFile 'c:\doesnotmatter.txt' } | Should -Throw -ExpectedMessage $errorRecord
            }

            Should -Invoke -CommandName djoin.exe -Exactly -Times 1 -Scope It
        }
    }
}
