<#
    .SYNOPSIS
        Unit test for DSC_SystemRestorePoint DSC resource.

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
    $script:dscModuleName   = 'ComputerManagementDsc'
    $script:dscResourceName = 'DSC_SystemRestorePoint'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName']          = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName']        = $script:dscResourceName
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

Describe "DSC_SystemRestorePoint\Get-TargetResource" -Tag 'Get' {
    Context 'When running on a workstation OS' {
        BeforeAll {
            $workstationMock = @{
                ParameterFilter = $([scriptblock]::Create('$ClassName -eq ''Win32_OperatingSystem'''))
                MockWith        = $([scriptblock]::Create('@{ ProductType = 1 }'))
            }

            $getComputerRestorePoint = New-Object -TypeName PSObject
            $getComputerRestorePoint | Add-Member -MemberType NoteProperty -Name Description -Value 'DSC Unit Test'
            $getComputerRestorePoint | Add-Member -MemberType NoteProperty -Name SequenceNumber -Value 1
            $getComputerRestorePoint | Add-Member -MemberType NoteProperty -Name RestorePointType -Value 12

            Mock -CommandName Get-ComputerRestorePoint { $getComputerRestorePoint }
            Mock -CommandName Get-CimInstance @workstationMock
        }

        Context 'When getting the target resource' {
            It 'Should return Absent when requested restore point does not exist' {
                $result = Get-TargetResource -Ensure 'Present' -Description 'Does Not Exist'

                $result | Should -BeOfType Hashtable
                $result.Ensure | Should -Be 'Absent'
            }

            It 'Should return present when requested restore point exists' {
                $result = Get-TargetResource -Ensure 'Present' -Description 'DSC Unit Test'

                $result | Should -BeOfType Hashtable
                $result.Ensure | Should -Be 'Present'
            }
        }
    }

    Context 'When running on a server OS' {
        BeforeAll {
            $serverMock = @{
                ParameterFilter = $([scriptblock]::Create('$ClassName -eq ''Win32_OperatingSystem'''))
                MockWith        = $([scriptblock]::Create('@{ ProductType = 3 }'))
            }

            Mock -CommandName Get-CimInstance @serverMock
        }

        Context 'When getting the target resource' {
            It 'Should return Absent and write a warning on a server operating system' {
                Mock -CommandName Write-Warning

                $protectionSettings = Get-TargetResource -Ensure 'Present' -Description 'DSC Unit Test'

                $protectionSettings.Ensure | Should -Be 'Absent'
                Assert-MockCalled -CommandName Write-Warning -Times 1
            }
        }
    }
}

Describe "DSC_SystemRestorePoint\Test-TargetResource" -Tag 'Test' {
    Context 'When running on a workstation OS' {
        BeforeAll {
            $workstationMock = @{
                ParameterFilter = $([scriptblock]::Create('$ClassName -eq ''Win32_OperatingSystem'''))
                MockWith        = $([scriptblock]::Create('@{ ProductType = 1 }'))
            }

            $getComputerRestorePoint = New-Object -TypeName PSObject
            $getComputerRestorePoint | Add-Member -MemberType NoteProperty -Name Description -Value 'DSC Unit Test'
            $getComputerRestorePoint | Add-Member -MemberType NoteProperty -Name SequenceNumber -Value 1
            $getComputerRestorePoint | Add-Member -MemberType NoteProperty -Name RestorePointType -Value 12

            Mock -CommandName Get-ComputerRestorePoint { $getComputerRestorePoint }
            Mock -CommandName Get-CimInstance @workstationMock
        }

        Context 'When testing the target resource' {
            It 'Should return true if the restore point exists' {
                $targetPresentArguments = @{
                    Ensure           = 'Present'
                    Description      = 'DSC Unit Test'
                    RestorePointType = 'MODIFY_SETTINGS'
                }

                $result = Test-TargetResource @targetPresentArguments

                $result | Should -BeTrue
            }

            It 'Should return false if the restore point does not exist' {
                $dnePresentArguments = @{
                    Ensure           = 'Present'
                    Description      = 'Does Not Exist'
                    RestorePointType = 'MODIFY_SETTINGS'
                }

                $result = Test-TargetResource @dnePresentArguments

                $result | Should -BeFalse
            }

            It 'Should return false if the restore point description matches but the type is different' {
                $result = Test-TargetResource `
                    -Ensure Present `
                    -Description 'DSC Unit Test' `
                    -RestorePointType 'APPLICATION_INSTALL'

                $result | Should -BeFalse
            }

            It 'Should return false if the restore point exists but should be absent' {
                $targetAbsentArguments = @{
                    Ensure           = 'Absent'
                    Description      = 'DSC Unit Test'
                    RestorePointType = 'MODIFY_SETTINGS'
                }

                $result = Test-TargetResource @targetAbsentArguments

                $result | Should -BeFalse
            }
        }
    }

    Context 'When running on a server OS' {
        BeforeAll {
            $serverMock = @{
                ParameterFilter = $([scriptblock]::Create('$ClassName -eq ''Win32_OperatingSystem'''))
                MockWith        = $([scriptblock]::Create('@{ ProductType = 3 }'))
            }

            Mock -CommandName Get-CimInstance @serverMock
        }

        Context 'When testing the target resource' {
            It 'Should return Absent and write warnings on a server operating system' {
                Mock -CommandName Write-Warning

                $desiredState = Test-TargetResource -Ensure 'Present' -Description 'DSC Unit Test'

                $desiredState | Should -BeTrue
                Assert-MockCalled -CommandName Write-Warning -Times 2
            }
        }
    }
}

Describe "DSC_SystemRestorePoint\Set-TargetResource" -Tag 'Set' {
    Context 'When running on a workstation OS' {
        BeforeAll {
            $workstationMock = @{
                ParameterFilter = $([scriptblock]::Create('$ClassName -eq ''Win32_OperatingSystem'''))
                MockWith        = $([scriptblock]::Create('@{ ProductType = 1 }'))
            }

            $getComputerRestorePoint = New-Object -TypeName PSObject
            $getComputerRestorePoint | Add-Member -MemberType NoteProperty -Name Description -Value 'DSC Unit Test'
            $getComputerRestorePoint | Add-Member -MemberType NoteProperty -Name SequenceNumber -Value 1
            $getComputerRestorePoint | Add-Member -MemberType NoteProperty -Name RestorePointType -Value 12

            Mock -CommandName Get-ComputerRestorePoint { $getComputerRestorePoint }
            Mock -CommandName Get-CimInstance @workstationMock
        }

        Context 'When setting the target resource to Present' {
            It 'Should throw if the operating system encounters a problem' {
                $errorMessage = $script:localizedData.CheckpointFailure

                Mock -CommandName Checkpoint-Computer { throw }

                { Set-TargetResource @targetPresentArguments } |
                    Should -Throw -ExpectedMessage $errorMessage.Exception.Message
            }

            It 'Should create the restore point' {
                $targetPresentArguments = @{
                    Ensure           = 'Present'
                    Description      = 'DSC Unit Test'
                    RestorePointType = 'MODIFY_SETTINGS'
                }

                Mock -CommandName Checkpoint-Computer

                { Set-TargetResource @targetPresentArguments } | Should -Not -Throw
            }
        }

        Context 'When setting the target resource to Absent' {
            BeforeAll {
                Mock -CommandName Add-Type
            }

            It 'Should not throw even if the requested restore point does not exist' {
                $dneAbsentArguments = @{
                    Ensure           = 'Absent'
                    Description      = 'Does Not Exist'
                    RestorePointType = 'MODIFY_SETTINGS'
                }

                { Set-TargetResource @dneAbsentArguments } | Should -Not -Throw
            }

            It 'Should delete the requested restore point' {
                $targetAbsentArguments = @{
                    Ensure           = 'Absent'
                    Description      = 'DSC Unit Test'
                    RestorePointType = 'MODIFY_SETTINGS'
                }

                Mock -CommandName Remove-RestorePoint { $true }

                { Set-TargetResource @targetAbsentArguments } | Should -Not -Throw
            }

            It 'Should throw if the operating system encountered a problem deleting the restore point' {
                $targetAbsentArguments = @{
                    Ensure           = 'Absent'
                    Description      = 'DSC Unit Test'
                    RestorePointType = 'MODIFY_SETTINGS'
                }

                $errorMessage = $script:localizedData.DeleteCheckpointFailure

                Mock -CommandName Remove-RestorePoint { return $false }

                { Set-TargetResource @targetAbsentArguments } |
                    Should -Throw -ExpectedMessage $errorMessage.Exception.Message
            }
        }
    }

    Context 'When running on a server OS' {
        BeforeAll {
            $serverMock = @{
                ParameterFilter = $([scriptblock]::Create('$ClassName -eq ''Win32_OperatingSystem'''))
                MockWith        = $([scriptblock]::Create('@{ ProductType = 3 }'))
            }

            Mock -CommandName Get-CimInstance @serverMock
        }

        Context 'When setting the target resource' {
            It 'Should throw when applied to a server operating system' {
                $errorMessage = $script:localizedData.NotWorkstationOS

                Mock -CommandName Get-CimInstance @serverMock

                { Set-TargetResource @targetPresentArguments } |
                    Should -Throw -ExpectedMessage $errorMessage.Exception.Message
            }
        }
    }
}
