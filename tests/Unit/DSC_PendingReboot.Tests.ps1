<#
    .SYNOPSIS
        Unit test for DSC_PendingReboot DSC resource.

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
    $script:dscResourceName = 'DSC_PendingReboot'

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

Describe 'DSC_PendingReboot\Get-TargetResource' -Tag 'Get' {
    Context 'When all reboots are required' {
        BeforeAll {
            Mock -CommandName Get-PendingRebootState -MockWith {
                @{
                    Name                        = 'Test'
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
            } -Verifiable
        }

        It 'Should return expected result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getTargetResourceResult = Get-TargetResource -Name 'Test'

                { $getTargetResourceResult } | Should -Not -Throw

                $getTargetResourceResult.Name | Should -Be 'Test'
                $getTargetResourceResult.SkipComponentBasedServicing | Should -BeFalse
                $getTargetResourceResult.ComponentBasedServicing | Should -BeTrue
                $getTargetResourceResult.SkipWindowsUpdate | Should -BeFalse
                $getTargetResourceResult.WindowsUpdate | Should -BeTrue
                $getTargetResourceResult.SkipPendingFileRename | Should -BeFalse
                $getTargetResourceResult.PendingFileRename | Should -BeTrue
                $getTargetResourceResult.SkipPendingComputerRename | Should -BeFalse
                $getTargetResourceResult.PendingComputerRename | Should -BeTrue
                $getTargetResourceResult.SkipCcmClientSDK | Should -BeTrue
                $getTargetResourceResult.CcmClientSDK | Should -BeTrue
                $getTargetResourceResult.RebootRequired | Should -BeTrue
            }

            Should -InvokeVerifiable
        }
    }

    Context 'When no reboots are required' {
        BeforeAll {
            Mock -CommandName Get-PendingRebootState -MockWith {
                @{
                    Name                        = 'Test'
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
            } -Verifiable
        }

        It 'Should return expected result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getTargetResourceResult = Get-TargetResource -Name 'Test'

                { $getTargetResourceResult } | Should -Not -Throw

                $getTargetResourceResult.Name | Should -Be 'Test'
                $getTargetResourceResult.SkipComponentBasedServicing | Should -BeFalse
                $getTargetResourceResult.ComponentBasedServicing | Should -BeFalse
                $getTargetResourceResult.SkipWindowsUpdate | Should -BeFalse
                $getTargetResourceResult.WindowsUpdate | Should -BeFalse
                $getTargetResourceResult.SkipPendingFileRename | Should -BeFalse
                $getTargetResourceResult.PendingFileRename | Should -BeFalse
                $getTargetResourceResult.SkipPendingComputerRename | Should -BeFalse
                $getTargetResourceResult.PendingComputerRename | Should -BeFalse
                $getTargetResourceResult.SkipCcmClientSDK | Should -BeTrue
                $getTargetResourceResult.CcmClientSDK | Should -BeFalse
                $getTargetResourceResult.RebootRequired | Should -BeFalse
            }

            Should -InvokeVerifiable
        }
    }
}

Describe 'DSC_PendingReboot\Set-TargetResource' -Tag 'Set' {
    Context 'When a reboot is not required' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $global:DSCMachineStatus = 0
            }

            Mock -CommandName Get-PendingRebootState -MockWith {
                @{
                    Name                        = 'Test'
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
            }  -Verifiable
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    Name                        = 'Test'
                    SkipComponentBasedServicing = $false
                    SkipWindowsUpdate           = $false
                    SkipPendingFileRename       = $false
                    SkipPendingComputerRename   = $false
                    SkipCcmClientSDK            = $false
                }

                { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
            }

            Should -InvokeVerifiable
        }

        It 'Should have set DSCMachineStatus to 1' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $global:DSCMachineStatus | Should -BeExactly 1
            }
        }
    }

    Context 'When a reboot is not required' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $global:DSCMachineStatus = 0
            }

            Mock -CommandName Get-PendingRebootState -MockWith {
                @{
                    Name                        = 'Test'
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
            }  -Verifiable
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = @{
                    Name                        = 'Test'
                    SkipComponentBasedServicing = $false
                    SkipWindowsUpdate           = $false
                    SkipPendingFileRename       = $false
                    SkipPendingComputerRename   = $false
                    SkipCcmClientSDK            = $false
                }

                { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
            }

            Should -InvokeVerifiable
        }

        It 'Should have not set DSCMachineStatus to 0' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $global:DSCMachineStatus | Should -BeExactly 0
            }
        }
    }
}

Describe 'DSC_PendingReboot\Test-TargetResource' -Tag 'Test' {
    Context 'When a reboot is required' {
        BeforeAll {
            Mock -CommandName Get-PendingRebootState -MockWith {
                @{
                    Name                        = 'Test'
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
            }  -Verifiable
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = @{
                    Name                        = 'Test'
                    SkipComponentBasedServicing = $false
                    SkipWindowsUpdate           = $false
                    SkipPendingFileRename       = $false
                    SkipPendingComputerRename   = $false
                    SkipCcmClientSDK            = $false
                }

                $testTargetResourceResult = Test-TargetResource $testTargetResourceParameters

                { $testTargetResourceResult } | Should -Not -Throw
                $testTargetResourceResult | Should -BeFalse
            }
            Should -InvokeVerifiable
        }

    }

    Context 'When a reboot is not required' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $global:DSCMachineStatus = 0
            }

            Mock -CommandName Get-PendingRebootState -MockWith {
                @{
                    Name                        = 'Test'
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
            }  -Verifiable
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetResourceParameters = @{
                    Name                        = 'Test'
                    SkipComponentBasedServicing = $false
                    SkipWindowsUpdate           = $false
                    SkipPendingFileRename       = $false
                    SkipPendingComputerRename   = $false
                    SkipCcmClientSDK            = $false
                }

                $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters

                { $testTargetResourceResult } | Should -Not -Throw
                $testTargetResourceResult | Should -BeTrue
            }

            Should -InvokeVerifiable
        }

        It 'Should have not set DSCMachineStatus to 0' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $global:DSCMachineStatus | Should -BeExactly 0
            }
        }
    }
}

Describe 'DSC_PendingReboot\Get-PendingRebootHashTable' -Tag 'Private' {
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
                -Verifiable

            Mock -CommandName Get-ChildItem `
                -MockWith $getChildItemAutoUpdateMock `
                -ParameterFilter $getChildItemAutoUpdateParameterFilter `
                -Verifiable

            Mock -CommandName Get-ItemProperty `
                -MockWith $getItemPropertyFileRenameMock `
                -ParameterFilter $getItemPropertyFileRenameParameterFilter `
                -Verifiable

            Mock -CommandName Get-ItemProperty `
                -MockWith $getItemPropertyActiveComputerNameMock `
                -ParameterFilter $getItemPropertyActiveComputerNameFilter `
                -Verifiable

            Mock -CommandName Get-ItemProperty `
                -MockWith $getItemPropertyComputerNameMock `
                -ParameterFilter $getItemPropertyComputerNameFilter `
                -Verifiable

            Mock -CommandName Invoke-CimMethod `
                -MockWith $invokeCimMethodRebootPendingMock `

        }

        Context 'When SkipCcmClientSdk is set to $false' {
            It 'Should return expected result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getPendingRebootStateParameters = @{
                        Name             = 'Test'
                        SkipCcmClientSDK = $false
                    }

                    $getPendingRebootStateResult = Get-PendingRebootState @getPendingRebootStateParameters

                    { $getPendingRebootStateResult } | Should -Not -Throw

                    $getPendingRebootStateResult.Name | Should -Be 'Test'
                    $getPendingRebootStateResult.ComponentBasedServicing | Should -BeTrue
                    $getPendingRebootStateResult.WindowsUpdate | Should -BeTrue
                    $getPendingRebootStateResult.PendingFileRename | Should -BeTrue
                    $getPendingRebootStateResult.PendingComputerRename | Should -BeTrue
                    $getPendingRebootStateResult.CcmClientSDK | Should -BeTrue
                }

                Should -InvokeVerifiable
                Should -Invoke -CommandName Invoke-CimMethod -Exactly -Times 1 -Scope It
            }
        }

        Context 'When SkipCcmClientSdk is set to $true' {
            It 'Should return expected result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getPendingRebootStateParameters = @{
                        Name             = 'Test'
                        SkipCcmClientSDK = $true
                    }

                    $getPendingRebootStateResult = Get-PendingRebootState @getPendingRebootStateParameters

                    { $getPendingRebootStateParameters } | Should -Not -Throw

                    $getPendingRebootStateResult.Name | Should -Be 'Test'
                    $getPendingRebootStateResult.ComponentBasedServicing | Should -BeTrue
                    $getPendingRebootStateResult.WindowsUpdate | Should -BeTrue
                    $getPendingRebootStateResult.PendingFileRename | Should -BeTrue
                    $getPendingRebootStateResult.PendingComputerRename | Should -BeTrue
                    $getPendingRebootStateResult.CcmClientSDK | Should -BeFalse
                }

                Should -InvokeVerifiable
                Should -Invoke -CommandName Invoke-CimMethod -Exactly -Times 0 -Scope It
            }
        }
    }

    Context 'When no reboots are required' {
        BeforeAll {
            Mock -CommandName Get-ChildItem `
                -ParameterFilter $getChildItemComponentBasedServicingParameterFilter `
                -Verifiable

            Mock -CommandName Get-ChildItem `
                -ParameterFilter $getChildItemAutoUpdateParameterFilter `
                -Verifiable

            Mock -CommandName Get-ItemProperty `
                -MockWith {
                @{
                    PendingFileRenameOperations = @()
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty `
                -MockWith {
                @{ }
            } `
                -ParameterFilter $getItemPropertyActiveComputerNameFilter `
                -Verifiable

            Mock -CommandName Get-ItemProperty `
                -MockWith {
                @{ }
            } `
                -ParameterFilter $getItemPropertyComputerNameFilter `
                -Verifiable

            Mock -CommandName Invoke-CimMethod `
                -MockWith $invokeCimMethodRebootNotPendingMock `

        }

        Context 'When SkipCcmClientSdk is set to $false' {
            It 'Should return expected result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getPendingRebootStateParameters = @{
                        Name             = 'Test'
                        SkipCcmClientSDK = $false
                    }

                    $getPendingRebootStateResult = Get-PendingRebootState @getPendingRebootStateParameters

                    { $getPendingRebootStateResult } | Should -Not -Throw

                    $getPendingRebootStateResult.Name | Should -Be 'Test'
                    $getPendingRebootStateResult.ComponentBasedServicing | Should -BeFalse
                    $getPendingRebootStateResult.WindowsUpdate | Should -BeFalse
                    $getPendingRebootStateResult.PendingFileRename | Should -BeFalse
                    $getPendingRebootStateResult.PendingComputerRename | Should -BeFalse
                    $getPendingRebootStateResult.CcmClientSDK | Should -BeFalse
                }

                Should -InvokeVerifiable
                Should -Invoke -CommandName Invoke-CimMethod -Exactly -Times 1
            }
        }

        Context 'When SkipCcmClientSdk is set to $true' {
            It 'Should return expected result' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getPendingRebootStateParameters = @{
                        Name             = 'Test'
                        SkipCcmClientSDK = $true
                    }

                    $getPendingRebootStateResult = Get-PendingRebootState @getPendingRebootStateParameters

                    { $getPendingRebootStateResult } | Should -Not -Throw

                    $getPendingRebootStateResult.Name | Should -Be 'Test'
                    $getPendingRebootStateResult.ComponentBasedServicing | Should -BeFalse
                    $getPendingRebootStateResult.WindowsUpdate | Should -BeFalse
                    $getPendingRebootStateResult.PendingFileRename | Should -BeFalse
                    $getPendingRebootStateResult.PendingComputerRename | Should -BeFalse
                    $getPendingRebootStateResult.CcmClientSDK | Should -BeFalse
                }

                Should -InvokeVerifiable
                Should -Invoke -CommandName Invoke-CimMethod -Exactly -Times 0 -Scope It
            }
        }
    }
}

Describe 'DSC_PendingReboot\Get-PendingRebootState' -Tag 'Private' {
    BeforeDiscovery {
        $RebootTriggers = @(
            @{
                Name        = 'ComponentBasedServicing'
                Description = 'Component based servicing'
            },
            @{
                Name        = 'WindowsUpdate'
                Description = 'Windows Update'
            },
            @{
                Name        = 'PendingFileRename'
                Description = 'Pending file rename'
            },
            @{
                Name        = 'PendingComputerRename'
                Description = 'Pending computer rename'
            },
            @{
                Name        = 'CcmClientSDK'
                Description = 'ConfigMgr'
            }
        )
    }

    BeforeAll {
        $getPendingRebootStateObject = @{
            Name                        = 'Test'
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

        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $script:getPendingRebootStateParameters = @{
                Name                        = 'Test'
                SkipComponentBasedServicing = $true
                SkipWindowsUpdate           = $true
                SkipPendingFileRename       = $true
                SkipPendingComputerRename   = $true
                SkipCcmClientSDK            = $true
            }
        }
    }

    Context 'When a reboot is required' {
        Context 'When <Description> requires a reboot and is not skipped' -ForEach $RebootTriggers {
            BeforeAll {
                $getPendingRebootStateMock = $getPendingRebootStateObject.Clone()
                $null = $getPendingRebootStateMock.Remove('RebootRequired')

                $getPendingRebootStateMock.$Name = $true
                $getPendingRebootStateMock."skip$Name" = $false

                Mock -CommandName Get-PendingRebootHashTable -MockWith {
                    $getPendingRebootStateMock
                }  -Verifiable
            }

            It 'Should return the correct result' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getPendingRebootStateParameters = $getPendingRebootStateParameters.Clone()
                    $getPendingRebootStateParameters."skip$Name" = $false

                    $getPendingRebootStateResult = Get-PendingRebootState @getPendingRebootStateParameters

                    { $getPendingRebootStateResult } | Should -Not -Throw
                    $getPendingRebootStateResult.RebootRequired | Should -BeTrue
                }

                Should -InvokeVerifiable
            }
        }

        Context 'When <Description> requires a reboot but is skipped' -ForEach $RebootTriggers {
            BeforeAll {
                $getPendingRebootStateMock = $getPendingRebootStateObject.Clone()
                $null = $getPendingRebootStateMock.Remove('RebootRequired')

                $getPendingRebootStateMock.$Name = $true
                $getPendingRebootStateMock."skip$Name" = $true

                Mock -CommandName Get-PendingRebootHashTable -MockWith {
                    $getPendingRebootStateMock
                }  -Verifiable
            }

            It 'Should return the correct result' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getPendingRebootStateParameters = $getPendingRebootStateParameters.Clone()
                    $getPendingRebootStateParameters."skip$Name" = $true

                    $getPendingRebootStateResult = Get-PendingRebootState @getPendingRebootStateParameters

                    { $getPendingRebootStateResult } | Should -Not -Throw

                    $getPendingRebootStateResult.RebootRequired | Should -BeFalse
                }

                Should -InvokeVerifiable
            }
        }
    }

    Context 'When a reboot is not required' {
        BeforeAll {
            $getPendingRebootStateMock = $getPendingRebootStateObject.Clone()
            $null = $getPendingRebootStateMock.Remove('RebootRequired')

            Mock -CommandName Get-PendingRebootHashTable -MockWith {
                $getPendingRebootStateMock
            }  -Verifiable
        }

        BeforeEach {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getPendingRebootStateParameters = $getPendingRebootStateParameters.Clone()
            }
        }

        It 'Should return $false for <Name>' -ForEach $RebootTriggers {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getPendingRebootStateParameters."skip$Name" = $false

                $getPendingRebootStateResult = Get-PendingRebootState @getPendingRebootStateParameters

                { $getPendingRebootStateResult } | Should -Not -Throw

                $getPendingRebootStateResult.RebootRequired | Should -BeFalse
            }

            Should -InvokeVerifiable
        }
    }
}
