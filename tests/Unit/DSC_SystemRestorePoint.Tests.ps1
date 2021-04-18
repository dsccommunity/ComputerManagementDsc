$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'DSC_SystemRestorePoint'

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
        $targetPresentArguments = @{
            Ensure           = 'Present'
            Description      = 'DSC Unit Test'
            RestorePointType = 'MODIFY_SETTINGS'
        }

        $targetAbsentArguments = @{
            Ensure           = 'Absent'
            Description      = 'DSC Unit Test'
            RestorePointType = 'MODIFY_SETTINGS'
        }

        $dnePresentArguments = @{
            Ensure           = 'Present'
            Description      = 'Does Not Exist'
            RestorePointType = 'MODIFY_SETTINGS'
        }

        $dneAbsentArguments = @{
            Ensure           = 'Absent'
            Description      = 'Does Not Exist'
            RestorePointType = 'MODIFY_SETTINGS'
        }

        $srClass = New-Object -TypeName System.Management.ManagementClass `
            -ArgumentList ('root\default', 'SystemRestore', $null)

        $GetComputerRestorePoint = New-Object -TypeName System.Management.ManagementObject
        $GetComputerRestorePoint = $srClass.CreateInstance()

        $GetComputerRestorePoint.Description      = 'DSC Unit Test'
        $GetComputerRestorePoint.SequenceNumber   = 1
        $GetComputerRestorePoint.RestorePointType = 12

        Describe "DSC_SystemRestorePoint\Get-TargetResource" -Tag 'Get' {
            Context 'When getting the target resource' {
                Mock -CommandName Get-ComputerRestorePoint -MockWith { return $GetComputerRestorePoint }

                It 'Should return absent when requested restore point does not exist' {
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

        Describe "DSC_SystemRestorePoint\Test-TargetResource" -Tag 'Test' {
            Context 'When testing the target resource' {
                Mock -CommandName Get-ComputerRestorePoint -MockWith { return $GetComputerRestorePoint }

                It 'Should return true if the restore point exists' {
                    $result = Test-TargetResource @targetPresentArguments
                    $result | Should -BeTrue
                }

                It 'Should return false if the restore point does not exist' {
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
                    $result = Test-TargetResource @targetAbsentArguments
                    $result | Should -BeFalse
                }
            }
        }

        Describe "DSC_SystemRestorePoint\Set-TargetResource" -Tag 'Set' {
            Context 'When setting the target resource to Present' {
                It 'Should throw if the operating system encounters a problem' {
                    $errorRecord = Get-InvalidOperationRecord -Message $script:localizedData.CheckpointFailure

                    Mock -CommandName Checkpoint-Computer -MockWith { throw }
                    { Set-TargetResource @targetPresentArguments } | Should -Throw $errorRecord
                }

                It 'Should create the restore point' {
                    Mock -CommandName Checkpoint-Computer
                    { Set-TargetResource @targetPresentArguments } | Should -Not -Throw
                }
            }

            Context 'When setting the target resource to Absent' {
                It 'Should not throw even if the requested restore point does not exist' {
                    { Set-TargetResource @dneAbsentArguments } | Should -Not -Throw
                }

                It 'Should delete the requested restore point' {
                    Mock -CommandName Remove-RestorePoint -MockWith { return $true }
                    Mock -CommandName Get-ComputerRestorePoint -MockWith { return $GetComputerRestorePoint }
                    { Set-TargetResource @targetAbsentArguments } | Should -Not -Throw
                }

                It 'Should throw if the operating system encountered a problem deleting the restore point' {
                    $errorRecord = Get-InvalidOperationRecord -Message $script:localizedData.DeleteCheckpointFailure

                    Mock -CommandName Remove-RestorePoint -MockWith { return $false }
                    { Set-TargetResource @targetAbsentArguments } | Should -Throw $errorRecord
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
