#region HEADER
$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'MSFT_PendingReboot'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

# Unit Test Template Version: 1.2.4
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath 'DscResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -ResourceType 'Mof' `
    -TestType Unit
#endregion HEADER

# Begin Testing
try
{
    #region Pester Tests
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

        Describe 'MSFT_PendingReboot\Get-TargetResource' {
            Context 'When all reboots are required' {
                Mock -CommandName Get-PendingRebootState `
                    -MockWith $getPendingRebootStateAllRebootsTrue `
                    -ModuleName 'MSFT_PendingReboot' `
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
                    -ModuleName 'MSFT_PendingReboot' `
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

        Describe 'MSFT_PendingReboot\Set-TargetResource' {
            Context 'When a reboot is not required' {
                $global:DSCMachineStatus = 0

                Mock -CommandName Get-PendingRebootState `
                    -MockWith $getPendingRebootStateAllRebootsTrue `
                    -ModuleName 'MSFT_PendingReboot' `
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
                    -ModuleName 'MSFT_PendingReboot' `
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

        Describe 'MSFT_PendingReboot\Test-TargetResource' {
            Context 'When a reboot is required' {
                Mock -CommandName Get-PendingRebootState `
                    -MockWith $getPendingRebootStateAllRebootsTrue `
                    -ModuleName 'MSFT_PendingReboot' `
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
                    -ModuleName 'MSFT_PendingReboot' `
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

        Describe 'MSFT_PendingReboot\Get-PendingRebootHashTable' {
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
                        -ModuleName 'MSFT_PendingReboot' `
                        -Verifiable

                    Mock -CommandName Get-ChildItem `
                        -MockWith $getChildItemAutoUpdateMock `
                        -ParameterFilter $getChildItemAutoUpdateParameterFilter `
                        -ModuleName 'MSFT_PendingReboot' `
                        -Verifiable

                    Mock -CommandName Get-ItemProperty `
                        -MockWith $getItemPropertyFileRenameMock `
                        -ParameterFilter $getItemPropertyFileRenameParameterFilter `
                        -ModuleName 'MSFT_PendingReboot' `
                        -Verifiable

                    Mock -CommandName Get-ItemProperty `
                        -MockWith $getItemPropertyActiveComputerNameMock `
                        -ParameterFilter $getItemPropertyActiveComputerNameFilter `
                        -ModuleName 'MSFT_PendingReboot' `
                        -Verifiable

                    Mock -CommandName Get-ItemProperty `
                        -MockWith $getItemPropertyComputerNameMock `
                        -ParameterFilter $getItemPropertyComputerNameFilter `
                        -ModuleName 'MSFT_PendingReboot' `
                        -Verifiable

                    Mock -CommandName Invoke-CimMethod `
                        -MockWith $invokeCimMethodRebootPendingMock `
                        -ModuleName 'MSFT_PendingReboot'
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
                        -ModuleName 'MSFT_PendingReboot' `
                        -Verifiable

                    Mock -CommandName Get-ChildItem `
                        -ParameterFilter $getChildItemAutoUpdateParameterFilter `
                        -ModuleName 'MSFT_PendingReboot' `
                        -Verifiable

                    Mock -CommandName Get-ItemProperty `
                        -MockWith {
                        @{
                            PendingFileRenameOperations = @()
                        }
                    } `
                        -ModuleName 'MSFT_PendingReboot' `
                        -Verifiable

                    Mock -CommandName Get-ItemProperty `
                        -MockWith {
                        @{ }
                    } `
                        -ParameterFilter $getItemPropertyActiveComputerNameFilter `
                        -ModuleName 'MSFT_PendingReboot' `
                        -Verifiable

                    Mock -CommandName Get-ItemProperty `
                        -MockWith {
                        @{ }
                    } `
                        -ParameterFilter $getItemPropertyComputerNameFilter `
                        -ModuleName 'MSFT_PendingReboot' `
                        -Verifiable

                    Mock -CommandName Invoke-CimMethod `
                        -MockWith $invokeCimMethodRebootNotPendingMock `
                        -ModuleName 'MSFT_PendingReboot'
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

                Describe 'MSFT_PendingReboot\Get-PendingRebootState' {
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
                                        -ModuleName 'MSFT_PendingReboot' `
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
                                        -ModuleName 'MSFT_PendingReboot' `
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
                                -ModuleName 'MSFT_PendingReboot' `
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
    } #end InModuleScope $DSCResourceName
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
