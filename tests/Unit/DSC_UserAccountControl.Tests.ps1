<#
    .SYNOPSIS
        Unit test for DSC_UserAccountControl DSC resource.

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
    $script:dscResourceName = 'DSC_UserAccountControl'

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


Describe 'UserAccountControl\Get-TargetResource' -Tag 'Get' {
    Context 'When getting the current state of User Account Control' {
        BeforeAll {
            Mock -CommandName Get-NotificationLevel -MockWith {
                return 'AlwaysNotify'
            }

            Mock -CommandName Get-UserAccountControl -MockWith {
                return @{
                    FilterAdministratorToken    = 1
                    ConsentPromptBehaviorAdmin  = 2
                    ConsentPromptBehaviorUser   = 1
                    EnableInstallerDetection    = 1
                    ValidateAdminCodeSignatures = 1
                    EnableLua                   = 1
                    PromptOnSecureDesktop       = 1
                    EnableVirtualization        = 1
                }
            }
        }

        It 'Should return the expected state' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource -IsSingleInstance 'Yes' -SuppressRestart $true

                $result.IsSingleInstance | Should -Be 'Yes'
                $result.NotificationLevel | Should -Be 'AlwaysNotify'
                $result.FilterAdministratorToken | Should -Be 1
                $result.ConsentPromptBehaviorAdmin | Should -Be 2
                $result.ConsentPromptBehaviorUser | Should -Be 1
                $result.EnableInstallerDetection | Should -Be 1
                $result.ValidateAdminCodeSignatures | Should -Be 1
                $result.EnableLua | Should -Be 1
                $result.PromptOnSecureDesktop | Should -Be 1
                $result.EnableVirtualization | Should -Be 1
                $result.SuppressRestart | Should -BeTrue
            }
        }
    }
}

Describe 'UserAccountControl\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        Mock -CommandName Assert-BoundParameter
        Mock -CommandName Set-ItemProperty
        Mock -CommandName Set-UserAccountControlToNotificationLevel
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $global:DSCMachineStatus = 0
        }
    }

    Context 'When the system is in the desired present state' {
        Context 'When the desired notification level is already set' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        NotificationLevel = 'AlwaysNotify'
                    }
                }
            }

            It 'Should not call any Set-* cmdlet or restart the computer' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    { Set-TargetResource -IsSingleInstance 'Yes' -NotificationLevel 'AlwaysNotify' } | Should -Not -Throw

                    $global:DSCMachineStatus | Should -Be 0
                }

                Should -Invoke -CommandName Set-ItemProperty -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName Set-UserAccountControlToNotificationLevel -Exactly -Times 0 -Scope It
            }
        }

        Context 'When the desired User Account Control properties are already set' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        FilterAdministratorToken   = 1
                        ConsentPromptBehaviorAdmin = 5
                    }
                }
            }

            It 'Should not call any Set-* cmdlet or restart the computer' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceParameters = @{
                        IsSingleInstance           = 'Yes'
                        FilterAdministratorToken   = 1
                        ConsentPromptBehaviorAdmin = 5
                    }

                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                    $global:DSCMachineStatus | Should -Be 0
                }

                Should -Invoke -CommandName Set-ItemProperty -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName Set-UserAccountControlToNotificationLevel -Exactly -Times 0 -Scope It
            }
        }
    }

    Context 'When the system is not in the desired present state' {
        Context 'When the notification level is not in the desired state' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        NotificationLevel = 'AlwaysNotify'
                    }
                }
            }

            It 'Should change the notification level and restart the computer' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceParameters = @{
                        IsSingleInstance  = 'Yes'
                        NotificationLevel = 'NotifyChanges'
                    }

                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                    $global:DSCMachineStatus | Should -Be 1
                }

                Should -Invoke -CommandName Set-ItemProperty -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName Set-UserAccountControlToNotificationLevel -Exactly -Times 1 -Scope It
            }
        }

        Context 'When User Account Control properties are not in desired state' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        FilterAdministratorToken    = 0
                        ConsentPromptBehaviorAdmin  = 0
                        ConsentPromptBehaviorUser   = 0
                        EnableInstallerDetection    = 0
                        ValidateAdminCodeSignatures = 0
                        EnableLua                   = 0
                        PromptOnSecureDesktop       = 0
                        EnableVirtualization        = 0
                    }
                }
            }

            It 'Should change the properties to the desired state and restart the computer' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceParameters = @{
                        IsSingleInstance            = 'Yes'
                        FilterAdministratorToken    = 1
                        ConsentPromptBehaviorAdmin  = 5
                        ConsentPromptBehaviorUser   = 1
                        EnableInstallerDetection    = 1
                        ValidateAdminCodeSignatures = 1
                        EnableLua                   = 1
                        PromptOnSecureDesktop       = 1
                        EnableVirtualization        = 1
                    }

                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                    $global:DSCMachineStatus | Should -Be 1
                }

                Should -Invoke -CommandName Set-ItemProperty -Exactly -Times 8 -Scope It
                Should -Invoke -CommandName Set-UserAccountControlToNotificationLevel -Exactly -Times 0 -Scope It
            }
        }

        Context 'When restart is suppressed' {
            BeforeAll {
                Mock -CommandName Write-Warning
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        NotificationLevel = 'AlwaysNotify'
                    }
                }
            }

            It 'Should change the notification level but suppress the restart' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceParameters = @{
                        IsSingleInstance  = 'Yes'
                        NotificationLevel = 'NotifyChanges'
                        SuppressRestart   = $true
                    }

                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                    $global:DSCMachineStatus | Should -Be 0
                }

                Should -Invoke -CommandName Set-UserAccountControlToNotificationLevel -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Write-Warning -Exactly -Times 1 -Scope It
            }
        }

        Context 'When Set-ItemProperty fails' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        FilterAdministratorToken = '1'
                    }
                }

                Mock -CommandName Set-ItemProperty -MockWith {
                    throw
                }
            }

            It 'Should throw the correct error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockGranularProperty = 'FilterAdministratorToken'
                    $errorMessage = Get-InvalidOperationRecord -Message ($script:localizedData.FailedToSetGranularProperty -f $mockGranularProperty)

                    { Set-TargetResource -IsSingleInstance 'Yes' -FilterAdministratorToken 0 } |
                        Should -Throw -ExpectedMessage ($errorMessage.Exception.Message + '*')
                }
            }
        }
    }
}

Describe 'UserAccountControl\Test-TargetResource' -Tag 'Test' {
    Context 'When the system is in the desired present state' {
        Context 'When the desired notification level is already set' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        NotificationLevel = 'AlwaysNotify'
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Test-TargetResource -IsSingleInstance 'Yes' -NotificationLevel 'AlwaysNotify'
                    $result | Should -BeTrue
                }
            }
        }

        Context 'When the desired User Account Control properties are already set' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        FilterAdministratorToken   = 1
                        ConsentPromptBehaviorAdmin = 5
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceParameters = @{
                        IsSingleInstance           = 'Yes'
                        FilterAdministratorToken   = 1
                        ConsentPromptBehaviorAdmin = 5
                    }

                    $result = Test-TargetResource @testTargetResourceParameters
                    $result | Should -BeTrue
                }
            }
        }
    }

    Context 'When the system is not in the desired present state' {
        Context 'When the notification level is not in the desired state' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        NotificationLevel = 'AlwaysNotify'
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Test-TargetResource -IsSingleInstance 'Yes' -NotificationLevel 'NotifyChanges'
                    $result | Should -BeFalse
                }
            }
        }

        Context 'When User Account Control properties are not in desired state' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        FilterAdministratorToken    = 0
                        ConsentPromptBehaviorAdmin  = 0
                        ConsentPromptBehaviorUser   = 0
                        EnableInstallerDetection    = 0
                        ValidateAdminCodeSignatures = 0
                        EnableLua                   = 0
                        PromptOnSecureDesktop       = 0
                        EnableVirtualization        = 0
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceParameters = @{
                        IsSingleInstance            = 'Yes'
                        FilterAdministratorToken    = 1
                        ConsentPromptBehaviorAdmin  = 5
                        ConsentPromptBehaviorUser   = 1
                        EnableInstallerDetection    = 1
                        ValidateAdminCodeSignatures = 1
                        EnableLua                   = 1
                        PromptOnSecureDesktop       = 1
                        EnableVirtualization        = 1
                    }

                    $result = Test-TargetResource @testTargetResourceParameters
                    $result | Should -BeFalse
                }
            }
        }
    }
}

Describe 'UserAccountControl\Set-UserAccountControlToNotificationLevel' -Tag 'Private' {
    BeforeDiscovery {
        $testCases = @(
            @{
                NotificationLevel          = 'AlwaysNotify'
                ConsentPromptBehaviorAdmin = 2
                EnableLua                  = 1
                PromptOnSecureDesktop      = 1
            }
            @{
                NotificationLevel          = 'AlwaysNotifyAndAskForCredentials'
                ConsentPromptBehaviorAdmin = 1
                EnableLua                  = 1
                PromptOnSecureDesktop      = 1
            }
            @{
                NotificationLevel          = 'NotifyChanges'
                ConsentPromptBehaviorAdmin = 5
                EnableLua                  = 1
                PromptOnSecureDesktop      = 1
            }
            @{
                NotificationLevel          = 'NotifyChangesWithoutDimming'
                ConsentPromptBehaviorAdmin = 5
                EnableLua                  = 1
                PromptOnSecureDesktop      = 0
            }
            @{
                NotificationLevel          = 'NeverNotify'
                ConsentPromptBehaviorAdmin = 0
                EnableLua                  = 1
                PromptOnSecureDesktop      = 0
            }
            @{
                NotificationLevel          = 'NeverNotifyAndDisableAll'
                ConsentPromptBehaviorAdmin = 0
                EnableLua                  = 0
                PromptOnSecureDesktop      = 0
            }
        )
    }
    BeforeAll {
        Mock -CommandName Set-ItemProperty
    }

    It 'Should call the mock with the correct values when notification level is <NotificationLevel>' -TestCases $testCases {
        InModuleScope -Parameters $_ -ScriptBlock {
            Set-StrictMode -Version 1.0

            { Set-UserAccountControlToNotificationLevel -NotificationLevel $NotificationLevel -Verbose } | Should -Not -Throw
        }

        Should -Invoke -CommandName Set-ItemProperty -ParameterFilter {
            $Name -eq 'ConsentPromptBehaviorAdmin' -and
            $Value -eq $ConsentPromptBehaviorAdmin -and
            $Type -eq 'DWord'
        } -Exactly -Times 1 -Scope It

        Should -Invoke -CommandName Set-ItemProperty -ParameterFilter {
            $Name -eq 'EnableLUA' -and
            $Value -eq $EnableLua
            $Type -eq 'DWord'
        } -Exactly -Times 1 -Scope It

        Should -Invoke -CommandName Set-ItemProperty -ParameterFilter {
            $Name -eq 'PromptOnSecureDesktop' -and
            $Value -eq $PromptOnSecureDesktop
            $Type -eq 'DWord'
        } -Exactly -Times 1 -Scope It
    }

    Context 'When Set-ItemProperty fails' {
        BeforeAll {
            Mock -CommandName Set-ItemProperty -MockWith {
                throw
            }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0


                $mockNotificationLevel = 'AlwaysNotify'
                $errorMessage = Get-InvalidOperationRecord -Message (
                    $localizedData.FailedToSetNotificationLevel -f $mockNotificationLevel
                )

                { Set-UserAccountControlToNotificationLevel -NotificationLevel $mockNotificationLevel } |
                    Should -Throw -ExpectedMessage ($errorMessage.Exception.Message + '*')
            }
        }
    }
}

Describe 'UserAccountControl\Get-NotificationLevel' -Tag 'Private' {
    BeforeDiscovery {
        $testCases = @(
            @{
                NotificationLevel          = 'AlwaysNotify'
                ConsentPromptBehaviorAdmin = 2
                EnableLua                  = 1
                PromptOnSecureDesktop      = 1
            }
            @{
                NotificationLevel          = 'AlwaysNotifyAndAskForCredentials'
                ConsentPromptBehaviorAdmin = 1
                EnableLua                  = 1
                PromptOnSecureDesktop      = 1
            }
            @{
                NotificationLevel          = 'NotifyChanges'
                ConsentPromptBehaviorAdmin = 5
                EnableLua                  = 1
                PromptOnSecureDesktop      = 1
            }
            @{
                NotificationLevel          = 'NotifyChangesWithoutDimming'
                ConsentPromptBehaviorAdmin = 5
                EnableLua                  = 1
                PromptOnSecureDesktop      = 0
            }
            @{
                NotificationLevel          = 'NeverNotify'
                ConsentPromptBehaviorAdmin = 0
                EnableLua                  = 1
                PromptOnSecureDesktop      = 0
            }
            @{
                NotificationLevel          = 'NeverNotifyAndDisableAll'
                ConsentPromptBehaviorAdmin = 0
                EnableLua                  = 0
                PromptOnSecureDesktop      = 0
            }
        )
    }

    Context 'When the notification level is set to <NotificationLevel>' -ForEach $testCases {
        BeforeAll {
            Mock -CommandName Get-UserAccountControl -MockWith {
                return @{
                    ConsentPromptBehaviorAdmin = $ConsentPromptBehaviorAdmin
                    EnableLua                  = $EnableLua
                    PromptOnSecureDesktop      = $PromptOnSecureDesktop
                }
            }
        }

        It 'Should return the correct notification level' {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-NotificationLevel
                $result | Should -Be $NotificationLevel
            }
        }
    }
}

Describe 'UserAccountControl\Get-UserAccountControl' -Tag 'Private' {
    BeforeAll {
        Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
            $Name -eq 'FilterAdministratorToken'
        } -MockWith {
            return 1
        }

        Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
            $Name -eq 'ConsentPromptBehaviorAdmin'
        } -MockWith {
            return 1
        }

        Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
            $Name -eq 'ConsentPromptBehaviorUser'
        } -MockWith {
            return 1
        }

        Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
            $Name -eq 'EnableInstallerDetection'
        } -MockWith {
            return 1
        }

        Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
            $Name -eq 'ValidateAdminCodeSignatures'
        } -MockWith {
            return 1
        }

        Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
            $Name -eq 'EnableLUA'
        } -MockWith {
            return 1
        }

        Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
            $Name -eq 'PromptOnSecureDesktop'
        } -MockWith {
            return 1
        }

        Mock -CommandName Get-RegistryPropertyValue -ParameterFilter {
            $Name -eq 'EnableVirtualization'
        } -MockWith {
            return 1
        }

        Mock -CommandName Get-RegistryPropertyValue -MockWith {
            throw 'Called mock Get-RegistryPropertyValue with the wrong parameter values.'
        }
    }

    It 'Should return the expected values' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $getUserAccountControlResult = Get-UserAccountControl
            $getUserAccountControlResult.FilterAdministratorToken | Should -Be 1
            $getUserAccountControlResult.ConsentPromptBehaviorAdmin | Should -Be 1
            $getUserAccountControlResult.ConsentPromptBehaviorUser | Should -Be 1
            $getUserAccountControlResult.EnableInstallerDetection | Should -Be 1
            $getUserAccountControlResult.ValidateAdminCodeSignatures | Should -Be 1
            $getUserAccountControlResult.EnableLua | Should -Be 1
            $getUserAccountControlResult.PromptOnSecureDesktop | Should -Be 1
            $getUserAccountControlResult.EnableVirtualization | Should -Be 1
        }
    }
}
