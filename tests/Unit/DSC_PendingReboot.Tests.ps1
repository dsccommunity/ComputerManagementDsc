$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'DSC_PendingReboot'

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
        $script:testResourceName = 'Test'

        $script:testAndSetTargetResourceParameters = @{
            Name                        = $script:testResourceName
            SkipComponentBasedServicing = $false
            SkipWindowsUpdate           = $false
            SkipPendingFileRename       = $false
            SkipPendingComputerRename   = $false
            SkipCcmClientSDK            = $false
            Verbose                     = $true
        }

        $getPendingRebootStateAllRebootsTrue = {
            @{
                Name                        = $script:testResourceName
                SkipComponentBasedServicing = $false
                ComponentBasedServicing     = $true
                SkipWindowsUpdate           = $false
                WindowsUpdate               = $true
                SkipPendingFileRename       = $false
                PendingFileRename           = $true
                SkipPendingComputerRename   = $false
                PendingComputerRename       = $true
                SkipCcmClientSDK            = $true
                CcmClientSDK                = $true
                RebootRequired              = $true
            }
        }

        $getPendingRebootStateAllRebootsFalse = {
            @{
                Name                        = $script:testResourceName
                SkipComponentBasedServicing = $false
                ComponentBasedServicing     = $false
                SkipWindowsUpdate           = $false
                WindowsUpdate               = $false
                SkipPendingFileRename       = $false
                PendingFileRename           = $false
                SkipPendingComputerRename   = $false
                PendingComputerRename       = $false
                SkipCcmClientSDK            = $true
                CcmClientSDK                = $false
                RebootRequired              = $false
            }
        }

        Describe 'DSC_PendingReboot\Get-TargetResource' {
            Context 'When all reboots are required' {
                Mock -CommandName Get-PendingRebootState `
                    -MockWith $getPendingRebootStateAllRebootsTrue `
                    -ModuleName 'DSC_PendingReboot' `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:getTargetResourceResult = Get-TargetResource -Name $script:testResourceName -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return expected result' {
                    $script:getTargetResourceResult.Name | Should -Be $script:testResourceName
                    $script:getTargetResourceResult.SkipComponentBasedServicing | Should -BeFalse
                    $script:getTargetResourceResult.ComponentBasedServicing | Should -BeTrue
                    $script:getTargetResourceResult.SkipWindowsUpdate | Should -BeFalse
                    $script:getTargetResourceResult.WindowsUpdate | Should -BeTrue
                    $script:getTargetResourceResult.SkipPendingFileRename | Should -BeFalse
                    $script:getTargetResourceResult.PendingFileRename | Should -BeTrue
                    $script:getTargetResourceResult.SkipPendingComputerRename | Should -BeFalse
                    $script:getTargetResourceResult.PendingComputerRename | Should -BeTrue
                    $script:getTargetResourceResult.SkipCcmClientSDK | Should -BeTrue
                    $script:getTargetResourceResult.CcmClientSDK | Should -BeTrue
                    $script:getTargetResourceResult.RebootRequired | Should -BeTrue
                }

                It 'Should call all verifiable mocks' {
                    Assert-VerifiableMock
                }
            }

            Context 'When no reboots are required' {
                Mock -CommandName Get-PendingRebootState `
                    -MockWith $getPendingRebootStateAllRebootsFalse `
                    -ModuleName 'DSC_PendingReboot' `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:getTargetResourceResult = Get-TargetResource -Name $script:testResourceName -Verbose
                    } | Should -Not -Throw
                }

                It 'Should return expected result' {
                    $script:getTargetResourceResult.Name | Should -Be $script:testResourceName
                    $script:getTargetResourceResult.SkipComponentBasedServicing | Should -BeFalse
                    $script:getTargetResourceResult.ComponentBasedServicing | Should -BeFalse
                    $script:getTargetResourceResult.SkipWindowsUpdate | Should -BeFalse
                    $script:getTargetResourceResult.WindowsUpdate | Should -BeFalse
                    $script:getTargetResourceResult.SkipPendingFileRename | Should -BeFalse
                    $script:getTargetResourceResult.PendingFileRename | Should -BeFalse
                    $script:getTargetResourceResult.SkipPendingComputerRename | Should -BeFalse
                    $script:getTargetResourceResult.PendingComputerRename | Should -BeFalse
                    $script:getTargetResourceResult.SkipCcmClientSDK | Should -BeTrue
                    $script:getTargetResourceResult.CcmClientSDK | Should -BeFalse
                    $script:getTargetResourceResult.RebootRequired | Should -BeFalse
                }

                It 'Should call all verifiable mocks' {
                    Assert-VerifiableMock
                }
            }
        }

        Describe 'DSC_PendingReboot\Set-TargetResource' {
            Context 'When a reboot is not required' {
                $global:DSCMachineStatus = 0

                Mock -CommandName Get-PendingRebootState `
                    -MockWith $getPendingRebootStateAllRebootsTrue `
                    -ModuleName 'DSC_PendingReboot' `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource @script:testAndSetTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should have set DSCMachineStatus to 1' {
                    $global:DSCMachineStatus | Should -BeExactly 1
                }
            }

            Context 'When a reboot is not required' {
                $global:DSCMachineStatus = 0

                Mock -CommandName Get-PendingRebootState `
                    -MockWith $getPendingRebootStateAllRebootsFalse `
                    -ModuleName 'DSC_PendingReboot' `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        Set-TargetResource @script:testAndSetTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should have not set DSCMachineStatus to 1' {
                    $global:DSCMachineStatus | Should -BeExactly 0
                }
            }
        }

        Describe 'DSC_PendingReboot\Test-TargetResource' {
            Context 'When a reboot is required' {
                Mock -CommandName Get-PendingRebootState `
                    -MockWith $getPendingRebootStateAllRebootsTrue `
                    -ModuleName 'DSC_PendingReboot' `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:testTargetResourceResult = Test-TargetResource $script:testAndSetTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should return false' {
                    $script:testTargetResourceResult | Should -BeFalse
                }
            }

            Context 'When a reboot is not required' {
                $global:DSCMachineStatus = 0

                Mock -CommandName Get-PendingRebootState `
                    -MockWith $getPendingRebootStateAllRebootsFalse `
                    -ModuleName 'DSC_PendingReboot' `
                    -Verifiable

                It 'Should not throw an exception' {
                    {
                        $script:testTargetResourceResult = Test-TargetResource $script:testAndSetTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should return true' {
                    $script:testTargetResourceResult | Should -BeTrue
                }
            }
        }

        Describe 'DSC_PendingReboot\Get-PendingRebootHashTable' {
            BeforeAll {
                $getChildItemComponentBasedServicingMock = {
                    @{
                        Name = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
                    }
                }
                $getChildItemComponentBasedServicingParameterFilter = {
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\'
                }

                $getChildItemAutoUpdateMock = {
                    @{
                        Name = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
                    }
                }
                $getChildItemAutoUpdateParameterFilter = {
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\'
                }

                $getItemPropertyFileRenameMock = {
                    @{
                        PendingFileRenameOperations = @('File1', 'File2')
                    }
                }
                $getItemPropertyFileRenameParameterFilter = {
                    $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\'
                }

                $getItemPropertyActiveComputerNameMock = {
                    @{
                        ComputerName = 'box2'
                    }
                }
                $getItemPropertyActiveComputerNameFilter = {
                    $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName'
                }

                $getItemPropertyComputerNameMock = {
                    @{
                        ComputerName = 'box'
                    }
                }
                $getItemPropertyComputerNameFilter = {
                    $Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName'
                }

                $invokeCimMethodRebootPendingMock = {
                    New-Object PSObject -Property @{
                        ReturnValue         = 0
                        IsHardRebootPending = $false
                        RebootPending       = $true
                    }
                }

                $invokeCimMethodRebootNotPendingMock = {
                    New-Object PSObject -Property @{
                        ReturnValue         = 0
                        IsHardRebootPending = $false
                        RebootPending       = $false
                    }
                }
            }

            Context 'When all reboots are required' {
                BeforeAll {
                    Mock -CommandName Get-ChildItem `
                        -MockWith $getChildItemComponentBasedServicingMock `
                        -ParameterFilter $getChildItemComponentBasedServicingParameterFilter `
                        -ModuleName 'DSC_PendingReboot' `
                        -Verifiable

                    Mock -CommandName Get-ChildItem `
                        -MockWith $getChildItemAutoUpdateMock `
                        -ParameterFilter $getChildItemAutoUpdateParameterFilter `
                        -ModuleName 'DSC_PendingReboot' `
                        -Verifiable

                    Mock -CommandName Get-ItemProperty `
                        -MockWith $getItemPropertyFileRenameMock `
                        -ParameterFilter $getItemPropertyFileRenameParameterFilter `
                        -ModuleName 'DSC_PendingReboot' `
                        -Verifiable

                    Mock -CommandName Get-ItemProperty `
                        -MockWith $getItemPropertyActiveComputerNameMock `
                        -ParameterFilter $getItemPropertyActiveComputerNameFilter `
                        -ModuleName 'DSC_PendingReboot' `
                        -Verifiable

                    Mock -CommandName Get-ItemProperty `
                        -MockWith $getItemPropertyComputerNameMock `
                        -ParameterFilter $getItemPropertyComputerNameFilter `
                        -ModuleName 'DSC_PendingReboot' `
                        -Verifiable

                    Mock -CommandName Invoke-CimMethod `
                        -MockWith $invokeCimMethodRebootPendingMock `
                        -ModuleName 'DSC_PendingReboot'
                }

                Context 'When SkipCcmClientSdk is set to False' {
                    It 'Should not throw an exception' {
                        {
                            $getPendingRebootStateParameters = @{
                                Name             = $script:testResourceName
                                SkipCcmClientSDK = $false
                                Verbose          = $true
                            }

                            $script:getPendingRebootStateResult = Get-PendingRebootState @getPendingRebootStateParameters
                        } | Should -Not -Throw
                    }

                    It 'Should return expected result' {
                        $script:getPendingRebootStateResult.Name | Should -Be $script:testResourceName
                        $script:getPendingRebootStateResult.ComponentBasedServicing | Should -BeTrue
                        $script:getPendingRebootStateResult.WindowsUpdate | Should -BeTrue
                        $script:getPendingRebootStateResult.PendingFileRename | Should -BeTrue
                        $script:getPendingRebootStateResult.PendingComputerRename | Should -BeTrue
                        $script:getPendingRebootStateResult.CcmClientSDK | Should -BeTrue
                    }

                    It 'Should call all verifiable mocks' {
                        Assert-VerifiableMock
                        Assert-MockCalled -CommandName Invoke-CimMethod -Exactly -Times 1
                    }
                }

                Context 'When SkipCcmClientSdk is set to True' {
                    It 'Should not throw an exception' {
                        {
                            $getPendingRebootStateParameters = @{
                                Name             = $script:testResourceName
                                SkipCcmClientSDK = $true
                                Verbose          = $true
                            }

                            $script:getPendingRebootStateResult = Get-PendingRebootState @getPendingRebootStateParameters
                        } | Should -Not -Throw
                    }

                    It 'Should return expected result' {
                        $script:getPendingRebootStateResult.Name | Should -Be $script:testResourceName
                        $script:getPendingRebootStateResult.ComponentBasedServicing | Should -BeTrue
                        $script:getPendingRebootStateResult.WindowsUpdate | Should -BeTrue
                        $script:getPendingRebootStateResult.PendingFileRename | Should -BeTrue
                        $script:getPendingRebootStateResult.PendingComputerRename | Should -BeTrue
                        $script:getPendingRebootStateResult.CcmClientSDK | Should -BeFalse
                    }

                    It 'Should call all verifiable mocks' {
                        Assert-VerifiableMock
                        Assert-MockCalled -CommandName Invoke-CimMethod -Exactly -Times 0
                    }
                }
            }

            Context 'When no reboots are required' {
                BeforeAll {
                    Mock -CommandName Get-ChildItem `
                        -ParameterFilter $getChildItemComponentBasedServicingParameterFilter `
                        -ModuleName 'DSC_PendingReboot' `
                        -Verifiable

                    Mock -CommandName Get-ChildItem `
                        -ParameterFilter $getChildItemAutoUpdateParameterFilter `
                        -ModuleName 'DSC_PendingReboot' `
                        -Verifiable

                    Mock -CommandName Get-ItemProperty `
                        -MockWith {
                        @{
                            PendingFileRenameOperations = @()
                        }
                    } `
                        -ModuleName 'DSC_PendingReboot' `
                        -Verifiable

                    Mock -CommandName Get-ItemProperty `
                        -MockWith {
                        @{ }
                    } `
                        -ParameterFilter $getItemPropertyActiveComputerNameFilter `
                        -ModuleName 'DSC_PendingReboot' `
                        -Verifiable

                    Mock -CommandName Get-ItemProperty `
                        -MockWith {
                        @{ }
                    } `
                        -ParameterFilter $getItemPropertyComputerNameFilter `
                        -ModuleName 'DSC_PendingReboot' `
                        -Verifiable

                    Mock -CommandName Invoke-CimMethod `
                        -MockWith $invokeCimMethodRebootNotPendingMock `
                        -ModuleName 'DSC_PendingReboot'
                }

                Context 'When SkipCcmClientSdk is set to False' {
                    It 'Should not throw an exception' {
                        {
                            $getPendingRebootStateParameters = @{
                                Name             = $script:testResourceName
                                SkipCcmClientSDK = $false
                                Verbose          = $true
                            }

                            $script:getPendingRebootStateResult = Get-PendingRebootState @getPendingRebootStateParameters
                        } | Should -Not -Throw
                    }

                    It 'Should return expected result' {
                        $script:getPendingRebootStateResult.Name | Should -Be $script:testResourceName
                        $script:getPendingRebootStateResult.ComponentBasedServicing | Should -BeFalse
                        $script:getPendingRebootStateResult.WindowsUpdate | Should -BeFalse
                        $script:getPendingRebootStateResult.PendingFileRename | Should -BeFalse
                        $script:getPendingRebootStateResult.PendingComputerRename | Should -BeFalse
                        $script:getPendingRebootStateResult.CcmClientSDK | Should -BeFalse
                    }

                    It 'Should call all verifiable mocks' {
                        Assert-VerifiableMock
                        Assert-MockCalled -CommandName Invoke-CimMethod -Exactly -Times 1
                    }
                }

                Context 'When SkipCcmClientSdk is set to True' {
                    It 'Should not throw an exception' {
                        {
                            $getPendingRebootStateParameters = @{
                                Name             = $script:testResourceName
                                SkipCcmClientSDK = $true
                                Verbose          = $true
                            }

                            $script:getPendingRebootStateResult = Get-PendingRebootState @getPendingRebootStateParameters
                        } | Should -Not -Throw
                    }

                    It 'Should return expected result' {
                        $script:getPendingRebootStateResult.Name | Should -Be $script:testResourceName
                        $script:getPendingRebootStateResult.ComponentBasedServicing | Should -BeFalse
                        $script:getPendingRebootStateResult.WindowsUpdate | Should -BeFalse
                        $script:getPendingRebootStateResult.PendingFileRename | Should -BeFalse
                        $script:getPendingRebootStateResult.PendingComputerRename | Should -BeFalse
                        $script:getPendingRebootStateResult.CcmClientSDK | Should -BeFalse
                    }

                    It 'Should call all verifiable mocks' {
                        Assert-VerifiableMock
                        Assert-MockCalled -CommandName Invoke-CimMethod -Exactly -Times 0
                    }
                }

                Describe 'DSC_PendingReboot\Get-PendingRebootState' {
                    $getPendingRebootStateObject = @{
                        Name                        = $script:testResourceName
                        SkipComponentBasedServicing = $false
                        ComponentBasedServicing     = $false
                        SkipWindowsUpdate           = $false
                        WindowsUpdate               = $false
                        SkipPendingFileRename       = $false
                        PendingFileRename           = $false
                        SkipPendingComputerRename   = $false
                        PendingComputerRename       = $false
                        SkipCcmClientSDK            = $false
                        CcmClientSDK                = $false
                        RebootRequired              = $false
                    }

                    $getPendingRebootStateParameters = @{
                        Name                        = $script:testResourceName
                        SkipComponentBasedServicing = $true
                        SkipWindowsUpdate           = $true
                        SkipPendingFileRename       = $true
                        SkipPendingComputerRename   = $true
                        SkipCcmClientSDK            = $true
                        Verbose                     = $true
                    }

                    Context 'When a reboot is required' {
                        foreach ($rebootTrigger in $RebootTriggers)
                        {
                            Context "When $($rebootTrigger.Description) requires a reboot and is not skipped" {
                                BeforeAll {
                                    $getPendingRebootStateMock = $getPendingRebootStateObject.Clone()
                                    $null = $getPendingRebootStateMock.Remove('RebootRequired')
                                    $getPendingRebootStateMock.$($rebootTrigger.Name) = $true
                                    $getPendingRebootStateMock."skip$($rebootTrigger.Name)" = $false

                                    Mock -CommandName Get-PendingRebootHashTable `
                                        -MockWith {
                                        $getPendingRebootStateMock
                                    } `
                                        -ModuleName 'DSC_PendingReboot' `
                                        -Verifiable
                                }

                                It 'Should not throw an exception' {
                                    {
                                        $getPendingRebootStateParameters = $getPendingRebootStateParameters.Clone()
                                        $getPendingRebootStateParameters."skip$($rebootTrigger.Name)" = $false

                                        $script:getPendingRebootStateResult = Get-PendingRebootState `
                                            @getPendingRebootStateParameters
                                    } | Should -Not -Throw
                                }

                                It 'Should return reboot required true' {
                                    $script:getPendingRebootStateResult.RebootRequired | Should -BeTrue
                                }
                            }
                        }

                        foreach ($rebootTrigger in $RebootTriggers)
                        {
                            Context "When $($rebootTrigger.Description) requires a reboot but is skipped" {
                                BeforeAll {
                                    $getPendingRebootStateMock = $getPendingRebootStateObject.Clone()
                                    $null = $getPendingRebootStateMock.Remove('RebootRequired')
                                    $getPendingRebootStateMock.$($rebootTrigger.Name) = $true
                                    $getPendingRebootStateMock."skip$($rebootTrigger.Name)" = $true

                                    Mock -CommandName Get-PendingRebootHashTable `
                                        -MockWith {
                                        $getPendingRebootStateMock
                                    } `
                                        -ModuleName 'DSC_PendingReboot' `
                                        -Verifiable
                                }

                                It 'Should not throw an exception' {
                                    {
                                        $getPendingRebootStateParameters = $getPendingRebootStateParameters.Clone()
                                        $getPendingRebootStateParameters."skip$($rebootTrigger.Name)" = $true

                                        $script:getPendingRebootStateResult = Get-PendingRebootState `
                                            @getPendingRebootStateParameters
                                    } | Should -Not -Throw
                                }

                                It 'Should return reboot required false' {
                                    $script:getPendingRebootStateResult.RebootRequired | Should -BeFalse
                                }
                            }
                        }
                    }

                    Context 'When a reboot is not required' {
                        BeforeAll {
                            $getPendingRebootStateMock = $getPendingRebootStateObject.Clone()
                            $null = $getPendingRebootStateMock.Remove('RebootRequired')

                            Mock -CommandName Get-PendingRebootHashTable `
                                -MockWith {
                                $getPendingRebootStateMock
                            } `
                                -ModuleName 'DSC_PendingReboot' `
                                -Verifiable
                        }

                        It 'Should not throw an exception' {
                            {
                                $getPendingRebootStateParameters = $getPendingRebootStateParameters.Clone()

                                foreach ($rebootTrigger in $RebootTriggers)
                                {
                                    $getPendingRebootStateParameters."skip$($rebootTrigger.Name)" = $false
                                }

                                $script:getPendingRebootStateResult = Get-PendingRebootState `
                                    @getPendingRebootStateParameters
                            } | Should -Not -Throw
                        }

                        It 'Should return reboot required false' {
                            $script:getPendingRebootStateResult.RebootRequired | Should -BeFalse
                        }
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
