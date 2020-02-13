#region HEADER
$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'DSC_UserAccountControl'

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

try
{
    InModuleScope $script:dscResourceName {
        Describe 'UserAccountControl\Get-TargetResource' {
            Context 'When getting the current state of User Account Control' {
                BeforeAll {
                    Mock -CommandName Get-NotificationLevel -MockWith {
                        return 'AlwaysNotify'
                    }

                    Mock -CommandName Get-UserAccountControl -MockWith {
                        return @{
                            FilterAdministratorToken = 1
                            ConsentPromptBehaviorAdmin = 2
                            ConsentPromptBehaviorUser = 1
                            EnableInstallerDetection = 1
                            ValidateAdminCodeSignatures = 1
                            EnableLua = 1
                            PromptOnSecureDesktop = 1
                            EnableVirtualization = 1
                        }
                    }
                }

                It 'Should return the expected state' {
                    $result = Get-TargetResource -IsSingleInstance 'Yes' -SuppressRestart $true -Verbose

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

        Describe 'UserAccountControl\Set-TargetResource' {
            BeforeAll {
                Mock -CommandName Assert-BoundParameter
                Mock -CommandName Set-ItemProperty
                Mock -CommandName Set-UserAccountControlToNotificationLevel
            }

            BeforeEach {
                $global:DSCMachineStatus = 0
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
                        { Set-TargetResource -IsSingleInstance 'Yes' -NotificationLevel 'AlwaysNotify' -Verbose } | Should -Not -Throw

                        Assert-MockCalled -CommandName Set-ItemProperty -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Set-UserAccountControlToNotificationLevel -Exactly -Times 0 -Scope It
                        $global:DSCMachineStatus | Should -Be 0
                    }
                }

                Context 'When the desired User Account Control properties are already set' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                FilterAdministratorToken = 1
                                ConsentPromptBehaviorAdmin = 5
                            }
                        }
                    }

                    It 'Should not call any Set-* cmdlet or restart the computer' {
                        {
                            $setTargetResourceParameters = @{
                                IsSingleInstance = 'Yes'
                                FilterAdministratorToken = 1
                                ConsentPromptBehaviorAdmin = 5
                                Verbose = $true
                            }

                            Set-TargetResource @setTargetResourceParameters
                        } | Should -Not -Throw

                        Assert-MockCalled -CommandName Set-ItemProperty -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Set-UserAccountControlToNotificationLevel -Exactly -Times 0 -Scope It
                        $global:DSCMachineStatus | Should -Be 0
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
                        { Set-TargetResource -IsSingleInstance 'Yes' -NotificationLevel 'NotifyChanges' -Verbose } | Should -Not -Throw

                        Assert-MockCalled -CommandName Set-ItemProperty -Exactly -Times 0 -Scope It
                        Assert-MockCalled -CommandName Set-UserAccountControlToNotificationLevel -Exactly -Times 1 -Scope It
                        $global:DSCMachineStatus | Should -Be 1
                    }
                }

                Context 'When User Account Control properties are not in desired state' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                FilterAdministratorToken = 0
                                ConsentPromptBehaviorAdmin = 0
                                ConsentPromptBehaviorUser = 0
                                EnableInstallerDetection = 0
                                ValidateAdminCodeSignatures = 0
                                EnableLua = 0
                                PromptOnSecureDesktop = 0
                                EnableVirtualization = 0
                            }
                        }
                    }

                    It 'Should change the properties to the desired state and restart the computer' {
                        {
                            $setTargetResourceParameters = @{
                                IsSingleInstance = 'Yes'
                                FilterAdministratorToken = 1
                                ConsentPromptBehaviorAdmin = 5
                                ConsentPromptBehaviorUser = 1
                                EnableInstallerDetection = 1
                                ValidateAdminCodeSignatures = 1
                                EnableLua = 1
                                PromptOnSecureDesktop = 1
                                EnableVirtualization = 1
                                Verbose = $true
                            }

                            Set-TargetResource @setTargetResourceParameters
                        } | Should -Not -Throw

                        Assert-MockCalled -CommandName Set-ItemProperty -Exactly -Times 8 -Scope It
                        Assert-MockCalled -CommandName Set-UserAccountControlToNotificationLevel -Exactly -Times 0 -Scope It
                        $global:DSCMachineStatus | Should -Be 1
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
                        { Set-TargetResource -IsSingleInstance 'Yes' -NotificationLevel 'NotifyChanges' -SuppressRestart $true -Verbose } | Should -Not -Throw

                        Assert-MockCalled -CommandName Set-UserAccountControlToNotificationLevel -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Write-Warning -Exactly -Times 1 -Scope It
                        $global:DSCMachineStatus | Should -Be 0
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
                        $mockGranularProperty = 'FilterAdministratorToken'
                        $errorMessage = $script:localizedData.FailedToSetGranularProperty -f $mockGranularProperty

                        {
                            Set-TargetResource -IsSingleInstance 'Yes' -FilterAdministratorToken 0 -Verbose
                        } | Should -Throw $errorMessage
                    }
                }
            }
        }

        Describe 'UserAccountControl\Test-TargetResource' {
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
                        $result = Test-TargetResource -IsSingleInstance 'Yes' -NotificationLevel 'AlwaysNotify' -Verbose
                        $result | Should -BeTrue
                    }
                }

                Context 'When the desired User Account Control properties are already set' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                FilterAdministratorToken = 1
                                ConsentPromptBehaviorAdmin = 5
                            }
                        }
                    }

                    It 'Should return $true' {
                        $testTargetResourceParameters = @{
                            IsSingleInstance = 'Yes'
                            FilterAdministratorToken = 1
                            ConsentPromptBehaviorAdmin = 5
                            Verbose = $true
                        }

                        $result = Test-TargetResource @testTargetResourceParameters
                        $result | Should -BeTrue
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
                        $result = Test-TargetResource -IsSingleInstance 'Yes' -NotificationLevel 'NotifyChanges' -Verbose
                        $result | Should -BeFalse
                    }
                }

                Context 'When User Account Control properties are not in desired state' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                FilterAdministratorToken = 0
                                ConsentPromptBehaviorAdmin = 0
                                ConsentPromptBehaviorUser = 0
                                EnableInstallerDetection = 0
                                ValidateAdminCodeSignatures = 0
                                EnableLua = 0
                                PromptOnSecureDesktop = 0
                                EnableVirtualization = 0
                            }
                        }
                    }

                    It 'Should return $false' {
                        $testTargetResourceParameters = @{
                            IsSingleInstance = 'Yes'
                            FilterAdministratorToken = 1
                            ConsentPromptBehaviorAdmin = 5
                            ConsentPromptBehaviorUser = 1
                            EnableInstallerDetection = 1
                            ValidateAdminCodeSignatures = 1
                            EnableLua = 1
                            PromptOnSecureDesktop = 1
                            EnableVirtualization = 1
                            Verbose = $true
                        }

                        $result = Test-TargetResource @testTargetResourceParameters
                        $result | Should -BeFalse
                    }
                }
            }
        }

        Describe 'UserAccountControl\Set-UserAccountControlToNotificationLevel' -Tag 'Helper' {
            BeforeAll {
                Mock -CommandName Set-ItemProperty

                $testCases = @(
                    @{
                        NotificationLevel = 'AlwaysNotify'
                        ConsentPromptBehaviorAdmin = 2
                        EnableLua = 1
                        PromptOnSecureDesktop = 1
                    }
                    @{
                        NotificationLevel = 'AlwaysNotifyAndAskForCredentials'
                        ConsentPromptBehaviorAdmin = 1
                        EnableLua = 1
                        PromptOnSecureDesktop = 1
                    }
                    @{
                        NotificationLevel = 'NotifyChanges'
                        ConsentPromptBehaviorAdmin = 5
                        EnableLua = 1
                        PromptOnSecureDesktop = 1
                    }
                    @{
                        NotificationLevel = 'NotifyChangesWithoutDimming'
                        ConsentPromptBehaviorAdmin = 5
                        EnableLua = 1
                        PromptOnSecureDesktop = 0
                    }
                    @{
                        NotificationLevel = 'NeverNotify'
                        ConsentPromptBehaviorAdmin = 0
                        EnableLua = 1
                        PromptOnSecureDesktop = 0
                    }
                    @{
                        NotificationLevel = 'NeverNotifyAndDisableAll'
                        ConsentPromptBehaviorAdmin = 0
                        EnableLua = 0
                        PromptOnSecureDesktop = 0
                    }
                )
            }

            It 'Should call the mock with the correct values when notification level is ''<NotificationLevel>''' -TestCases $testCases {
                param
                (
                    [Parameter()]
                    [System.String]
                    $NotificationLevel,

                    [Parameter()]
                    [System.UInt16]
                    $ConsentPromptBehaviorAdmin,

                    [Parameter()]
                    [System.UInt16]
                    $EnableLua,

                    [Parameter()]
                    [System.UInt16]
                    $PromptOnSecureDesktop
                )

                { Set-UserAccountControlToNotificationLevel -NotificationLevel $NotificationLevel -Verbose} | Should -Not -Throw

                Assert-MockCalled -CommandName Set-ItemProperty -ParameterFilter {
                    $Name -eq 'ConsentPromptBehaviorAdmin' -and $Value -eq $ConsentPromptBehaviorAdmin
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Set-ItemProperty -ParameterFilter {
                    $Name -eq 'EnableLUA' -and $Value -eq $EnableLua
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Set-ItemProperty -ParameterFilter {
                    $Name -eq 'PromptOnSecureDesktop' -and $Value -eq $PromptOnSecureDesktop
                } -Exactly -Times 1 -Scope It
            }

            Context 'When Set-ItemProperty fails' {
                BeforeAll {
                    Mock -CommandName Set-ItemProperty -MockWith {
                        throw
                    }
                }

                It 'Should throw the correct error' {
                    $mockNotificationLevel = 'AlwaysNotify'
                    $errorMessage = $script:localizedData.FailedToSetNotificationLevel -f $mockNotificationLevel

                    {
                        Set-UserAccountControlToNotificationLevel -NotificationLevel $mockNotificationLevel -Verbose
                    } | Should -Throw $errorMessage
                }
            }
        }

        Describe 'UserAccountControl\Get-NotificationLevel' -Tag 'Helper' {
            Context 'When the notification level is set to ''AlwaysNotify''' {
                Mock -CommandName Get-UserAccountControl -MockWith {
                    return @{
                        ConsentPromptBehaviorAdmin = 2
                        EnableLua = 1
                        PromptOnSecureDesktop = 1
                    }
                }

                It 'Should return the correct notification level' {
                    $result = Get-NotificationLevel
                    $result | Should -Be 'AlwaysNotify'
                }
            }

            Context 'When the notification level is set to ''AlwaysNotifyAndAskForCredentials''' {
                Mock -CommandName Get-UserAccountControl -MockWith {
                    return @{
                        ConsentPromptBehaviorAdmin = 1
                        EnableLua = 1
                        PromptOnSecureDesktop = 1
                    }
                }

                It 'Should return the correct notification level' {
                    $result = Get-NotificationLevel
                    $result | Should -Be 'AlwaysNotifyAndAskForCredentials'
                }
            }

            Context 'When the notification level is set to ''NotifyChanges''' {
                Mock -CommandName Get-UserAccountControl -MockWith {
                    return @{
                        ConsentPromptBehaviorAdmin = 5
                        EnableLua = 1
                        PromptOnSecureDesktop = 1
                    }
                }

                It 'Should return the correct notification level' {
                    $result = Get-NotificationLevel
                    $result | Should -Be 'NotifyChanges'
                }
            }

            Context 'When the notification level is set to ''NotifyChangesWithoutDimming''' {
                Mock -CommandName Get-UserAccountControl -MockWith {
                    return @{
                        ConsentPromptBehaviorAdmin = 5
                        EnableLua = 1
                        PromptOnSecureDesktop = 0
                    }
                }

                It 'Should return the correct notification level' {
                    $result = Get-NotificationLevel
                    $result | Should -Be 'NotifyChangesWithoutDimming'
                }
            }


            Context 'When the notification level is set to ''NeverNotify''' {
                Mock -CommandName Get-UserAccountControl -MockWith {
                    return @{
                        ConsentPromptBehaviorAdmin = 0
                        EnableLua = 1
                        PromptOnSecureDesktop = 0
                    }
                }

                It 'Should return the correct notification level' {
                    $result = Get-NotificationLevel
                    $result | Should -Be 'NeverNotify'
                }
            }

            Context 'When the notification level is set to ''NeverNotifyAndDisableAll''' {
                Mock -CommandName Get-UserAccountControl -MockWith {
                    return @{
                        ConsentPromptBehaviorAdmin = 0
                        EnableLua = 0
                        PromptOnSecureDesktop = 0
                    }
                }

                It 'Should return the correct notification level' {
                    $getNotificationLevelResult = Get-NotificationLevel
                    $getNotificationLevelResult | Should -Be 'NeverNotifyAndDisableAll'
                }
            }
        }

        Describe 'UserAccountControl\Get-UserAccountControl' -Tag 'Helper' {
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
}
finally
{
    Invoke-TestCleanup
}
