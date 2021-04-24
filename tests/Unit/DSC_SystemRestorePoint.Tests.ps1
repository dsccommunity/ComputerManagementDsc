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

        $productType = (Get-CimInstance -ClassName 'Win32_OperatingSystem').ProductType

        if ($productType -eq 1)
        {
            $srClass = New-Object -TypeName System.Management.ManagementClass `
                -ArgumentList ('root\default', 'SystemRestore', $null)

            $getComputerRestorePoint = New-Object -TypeName System.Management.ManagementObject
            $getComputerRestorePoint = $srClass.CreateInstance()

            $getComputerRestorePoint.Description      = 'DSC Unit Test'
            $getComputerRestorePoint.SequenceNumber   = 1
            $getComputerRestorePoint.RestorePointType = 12
        }

        $workstationMock = @{
            ParameterFilter = $([scriptblock]::Create('$ClassName -eq ''Win32_OperatingSystem'''))
            MockWith        = $([scriptblock]::Create('@{ ProductType = 1 }'))
        }

        $serverMock = @{
            ParameterFilter = $([scriptblock]::Create('$ClassName -eq ''Win32_OperatingSystem'''))
            MockWith        = $([scriptblock]::Create('@{ ProductType = 3 }'))
        }

        Describe "DSC_SystemRestorePoint\Get-TargetResource" -Tag 'Get' {
            Context 'When getting the target resource' {
                It 'Should return Absent and write a warning on a server operating system' {
                    Mock -CommandName Write-Warning
                    Mock -CommandName Get-CimInstance @serverMock

                    $protectionSettings = Get-TargetResource -Ensure 'Present' -Description 'DSC Unit Test'

                    $protectionSettings.Ensure | Should -Be 'Absent'
                    Assert-MockCalled -CommandName Write-Warning -Times 1
                }

                if ($productType -eq 1)
                {
                    It 'Should return Absent when requested restore point does not exist' {
                        Mock -CommandName Get-ComputerRestorePoint -MockWith { return $getComputerRestorePoint }

                        $result = Get-TargetResource -Ensure 'Present' -Description 'Does Not Exist'

                        $result | Should -BeOfType Hashtable
                        $result.Ensure | Should -Be 'Absent'
                    }

                    It 'Should return present when requested restore point exists' {
                        Mock -CommandName Get-ComputerRestorePoint -MockWith { return $getComputerRestorePoint }

                        $result = Get-TargetResource -Ensure 'Present' -Description 'DSC Unit Test'

                        $result | Should -BeOfType Hashtable
                        $result.Ensure | Should -Be 'Present'
                    }
                }
            }
        }

        Describe "DSC_SystemRestorePoint\Test-TargetResource" -Tag 'Test' {
            Context 'When testing the target resource' {
                It 'Should return Absent and write warnings on a server operating system' {
                    Mock -CommandName Write-Warning
                    Mock -CommandName Get-CimInstance @serverMock

                    $desiredState = Test-TargetResource -Ensure 'Present' -Description 'DSC Unit Test'

                    $desiredState | Should -BeTrue
                    Assert-MockCalled -CommandName Write-Warning -Times 2
                }

                if ($productType -eq 1)
                {
                    It 'Should return true if the restore point exists' {
                        Mock -CommandName Get-ComputerRestorePoint -MockWith { return $getComputerRestorePoint }

                        $result = Test-TargetResource @targetPresentArguments

                        $result | Should -BeTrue
                    }

                    It 'Should return false if the restore point does not exist' {
                        Mock -CommandName Get-ComputerRestorePoint -MockWith { return $getComputerRestorePoint }

                        $result = Test-TargetResource @dnePresentArguments

                        $result | Should -BeFalse
                    }

                    It 'Should return false if the restore point description matches but the type is different' {
                        Mock -CommandName Get-ComputerRestorePoint -MockWith { return $getComputerRestorePoint }

                        $result = Test-TargetResource `
                            -Ensure Present `
                            -Description 'DSC Unit Test' `
                            -RestorePointType 'APPLICATION_INSTALL'

                        $result | Should -BeFalse
                    }

                    It 'Should return false if the restore point exists but should be absent' {
                        Mock -CommandName Get-ComputerRestorePoint -MockWith { return $getComputerRestorePoint }

                        $result = Test-TargetResource @targetAbsentArguments

                        $result | Should -BeFalse
                    }
                }
            }
        }

        Describe "DSC_SystemRestorePoint\Set-TargetResource" -Tag 'Set' {
            Context 'When setting the target resource' {
                It 'Should throw when applied to a server operating system' {
                    $errorRecord = Get-InvalidOperationRecord -Message $script:localizedData.NotWorkstationOS

                    Mock -CommandName Get-CimInstance @serverMock

                    { Set-TargetResource @targetPresentArguments } | Should -Throw $errorRecord
                }
            }

            Context 'When setting the target resource to Present' {
                Mock -CommandName Get-CimInstance @workstationMock

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

            if ($productType -eq 1)
            {
                Context 'When setting the target resource to Absent' {
                    It 'Should not throw even if the requested restore point does not exist' {
                        { Set-TargetResource @dneAbsentArguments } | Should -Not -Throw
                    }

                    It 'Should delete the requested restore point' {
                        Mock -CommandName Remove-RestorePoint -MockWith { return $true }
                        Mock -CommandName Get-ComputerRestorePoint -MockWith { return $getComputerRestorePoint }

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
}
finally
{
    Invoke-TestCleanup
}
