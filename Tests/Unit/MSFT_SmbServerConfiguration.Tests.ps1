#region HEADER
$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'MSFT_SmbServerConfiguration'

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

function Invoke-TestSetup
{
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

try
{
    Invoke-TestSetup

    InModuleScope $script:DSCResourceName {

        $CurrSmbConfig = Get-SmbServerConfiguration
        $Params = @{
            IsSingleInstance                = 'Yes'
            AnnounceComment                 = $CurrSmbConfig.AnnounceComment
            AnnounceServer                  = $CurrSmbConfig.AnnounceServer
            AsynchronousCredits             = $CurrSmbConfig.AsynchronousCredits
            AuditSmb1Access                 = $CurrSmbConfig.AuditSmb1Access
            AutoDisconnectTimeout           = $CurrSmbConfig.AutoDisconnectTimeout
            AutoShareServer                 = $CurrSmbConfig.AutoShareServer
            AutoShareWorkstation            = $CurrSmbConfig.AutoShareWorkstation
            CachedOpenLimit                 = $CurrSmbConfig.CachedOpenLimit
            DurableHandleV2TimeoutInSeconds = $CurrSmbConfig.DurableHandleV2TimeoutInSeconds
            EnableAuthenticateUserSharing   = $CurrSmbConfig.EnableAuthenticateUserSharing
            EnableDownlevelTimewarp         = $CurrSmbConfig.EnableDownlevelTimewarp
            EnableForcedLogoff              = $CurrSmbConfig.EnableForcedLogoff
            EnableLeasing                   = $CurrSmbConfig.EnableLeasing
            EnableMultiChannel              = $CurrSmbConfig.EnableMultiChannel
            EnableOplocks                   = $CurrSmbConfig.EnableOplocks
            EnableSecuritySignature         = $CurrSmbConfig.EnableSecuritySignature
            EnableSMB1Protocol              = $CurrSmbConfig.EnableSMB1Protocol
            EnableSMB2Protocol              = $CurrSmbConfig.EnableSMB2Protocol
            EnableStrictNameChecking        = $CurrSmbConfig.EnableStrictNameChecking
            EncryptData                     = $CurrSmbConfig.EncryptData
            IrpStackSize                    = $CurrSmbConfig.IrpStackSize
            KeepAliveTime                   = $CurrSmbConfig.KeepAliveTime
            MaxChannelPerSession            = $CurrSmbConfig.MaxChannelPerSession
            MaxMpxCount                     = $CurrSmbConfig.MaxMpxCount
            MaxSessionPerConnection         = $CurrSmbConfig.MaxSessionPerConnection
            MaxThreadsPerQueue              = $CurrSmbConfig.MaxThreadsPerQueue
            MaxWorkItems                    = $CurrSmbConfig.MaxWorkItems
            OplockBreakWait                 = $CurrSmbConfig.OplockBreakWait
            PendingClientTimeoutInSeconds   = $CurrSmbConfig.PendingClientTimeoutInSeconds
            RejectUnencryptedAccess         = $CurrSmbConfig.RejectUnencryptedAccess
            RequireSecuritySignature        = $CurrSmbConfig.RequireSecuritySignature
            ServerHidden                    = $CurrSmbConfig.ServerHidden
            Smb2CreditsMax                  = $CurrSmbConfig.Smb2CreditsMax
            Smb2CreditsMin                  = $CurrSmbConfig.Smb2CreditsMin
            SmbServerNameHardeningLevel     = $CurrSmbConfig.SmbServerNameHardeningLevel
            TreatHostAsStableStorage        = $CurrSmbConfig.TreatHostAsStableStorage
            ValidateAliasNotCircular        = $CurrSmbConfig.ValidateAliasNotCircular
            ValidateShareScope              = $CurrSmbConfig.ValidateShareScope
            ValidateShareScopeNotAliased    = $CurrSmbConfig.ValidateShareScopeNotAliased
            ValidateTargetName              = $CurrSmbConfig.ValidateTargetName
        }

        Describe 'MSFT_SmbServerConfiguration\Get-TargetResource' -Tag 'Get' {
            Context 'When getting the Target Resource information' {
                It 'Should get the current SMB server configuration state' {

                    $SmbServerConfiguration = Get-TargetResource -IsSingleInstance Yes

                    $SmbServerConfiguration.AuditSmb1Access | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.EnableSMB1Protocol | Should -Not -BeNullOrEmpty
                }
            }
        }

        Describe 'MSFT_SmbServerConfiguration\Test-TargetResource' -Tag 'Test' {
            Context 'When the SMB Server is in the desired state' {
                It 'Should return false' {
                    $TestEnvironmentResult = Test-TargetResource @Params
                    $TestEnvironmentResult | Should -Be $false
                }
            }
            Context 'When the SMB Server is not in the desired state' {
                It 'Should return True when AnnouncementComment setting changes are required' {
                    $TestEnvironmentResult = Test-TargetResource -IsSingleInstance Yes -AnnounceComment "Test Comment"
                    $TestEnvironmentResult | Should -Be $true
                }

                It 'Should return True when AnnounceServer setting changes are required' {
                    $Param = !$Params.AnnounceServer
                    $TestEnvironmentResult = Test-TargetResource -IsSingleInstance Yes -AnnounceServer $Param
                    $TestEnvironmentResult | Should -Be $true
                }

                It 'Should return True when AsynchronousCredits setting changes are required' {
                    $Param = $Params.AsynchronousCredits - 1
                    $TestEnvironmentResult = Test-TargetResource -IsSingleInstance Yes -AsynchronousCredits $Param
                    $TestEnvironmentResult | Should -Be $true
                }

                It 'Should return True when AuditSmb1Access setting changes are required' {
                    $Param = !$Params.AuditSmb1Access
                    $TestEnvironmentResult = Test-TargetResource -IsSingleInstance Yes -AuditSmb1Access $Param
                    $TestEnvironmentResult | Should -Be $true
                }

                It 'Should return True when AutoDisconnectTimeout setting changes are required' {
                    $Param = $Params.AutoDisconnectTimeout - 1
                    $TestEnvironmentResult = Test-TargetResource -IsSingleInstance Yes -AutoDisconnectTimeout $Param
                    $TestEnvironmentResult | Should -Be $true
                }

                It 'Should return True when AutoShareServer setting changes are required' {
                    $Param = !$Params.AutoShareServer
                    $TestEnvironmentResult = Test-TargetResource -IsSingleInstance Yes -AutoShareServer $Param
                    $TestEnvironmentResult | Should -Be $true
                }

                It 'Should return True when AutoShareWorkstation setting changes are required' {
                    $Param = !$Params.AutoShareWorkstation
                    $TestEnvironmentResult = Test-TargetResource -IsSingleInstance Yes -AutoShareWorkstation $Param
                    $TestEnvironmentResult | Should -Be $true
                }

                It 'Should return True when CachedOpenLimit setting changes are required' {
                    $Param = $Params.CachedOpenLimit - 1
                    $TestEnvironmentResult = Test-TargetResource -IsSingleInstance Yes -CachedOpenLimit $Param
                    $TestEnvironmentResult | Should -Be $true
                }

                It 'Should return True when DurableHandleV2TimeoutInSeconds setting changes are required' {
                    $Param = $Params.DurableHandleV2TimeoutInSeconds - 1
                    $TestEnvironmentResult = Test-TargetResource -IsSingleInstance Yes -DurableHandleV2TimeoutInSeconds $Param
                    $TestEnvironmentResult | Should -Be $true
                }

                It 'Should return True when EnableAuthenticateUserSharing setting changes are required' {
                    $Param = !$Params.EnableAuthenticateUserSharing
                    $TestEnvironmentResult = Test-TargetResource -IsSingleInstance Yes -EnableAuthenticateUserSharing $Param
                    $TestEnvironmentResult | Should -Be $true
                }

                It 'Should return True when EnableForcedLogoff setting changes are required' {
                    $Param = !$Params.EnableForcedLogoff
                    $TestEnvironmentResult = Test-TargetResource -IsSingleInstance Yes -EnableForcedLogoff $Param
                    $TestEnvironmentResult | Should -Be $true
                }

                It 'Should return True when EnableLeasing setting changes are required' {
                    $Param = !$Params.EnableLeasing
                    $TestEnvironmentResult = Test-TargetResource -IsSingleInstance Yes -EnableLeasing $Param
                    $TestEnvironmentResult | Should -Be $true
                }

                It 'Should return True when EnableMultiChannel setting changes are required' {
                    $Param = !$Params.EnableMultiChannel
                    $TestEnvironmentResult = Test-TargetResource -IsSingleInstance Yes -EnableMultiChannel $Param
                    $TestEnvironmentResult | Should -Be $true
                }

                It 'Should return True when EnableOplocks setting changes are required' {
                    $Param = !$Params.EnableOplocks
                    $TestEnvironmentResult = Test-TargetResource -IsSingleInstance Yes -EnableOplocks $Param
                    $TestEnvironmentResult | Should -Be $true
                }

                It 'Should return True when EnableOplocks setting changes are required' {
                    $Param = !$Params.EnableOplocks
                    $TestEnvironmentResult = Test-TargetResource -IsSingleInstance Yes -EnableOplocks $Param
                    $TestEnvironmentResult | Should -Be $true
                }

                It 'Should return True when EnableSMB1Protocol setting changes are required' {
                    $Param = !$Params.EnableSMB1Protocol
                    $TestEnvironmentResult = Test-TargetResource -IsSingleInstance Yes -EnableSMB1Protocol $Param
                    $TestEnvironmentResult | Should -Be $true
                }

                It 'Should return True when EnableSMB2Protocol setting changes are required' {
                    $Param = !$Params.EnableSMB2Protocol
                    $TestEnvironmentResult = Test-TargetResource -IsSingleInstance Yes -EnableSMB2Protocol $Param
                    $TestEnvironmentResult | Should -Be $true
                }

                It 'Should return True when EnableSMB2Protocol setting changes are required' {
                    $Param = !$Params.EnableSMB2Protocol
                    $TestEnvironmentResult = Test-TargetResource -IsSingleInstance Yes -EnableSMB2Protocol $Param
                    $TestEnvironmentResult | Should -Be $true
                }

                It 'Should return True when EnableSecuritySignature setting changes are required' {
                    $Param = !$Params.EnableSecuritySignature
                    $TestEnvironmentResult = Test-TargetResource -IsSingleInstance Yes -EnableSecuritySignature $Param
                    $TestEnvironmentResult | Should -Be $true
                }

                It 'Should return True when EnableStrictNameChecking setting changes are required' {
                    $Param = !$Params.EnableStrictNameChecking
                    $TestEnvironmentResult = Test-TargetResource -IsSingleInstance Yes -EnableStrictNameChecking $Param
                    $TestEnvironmentResult | Should -Be $true
                }

                It 'Should return True when EncryptData setting changes are required' {
                    $Param = !$Params.EncryptData
                    $TestEnvironmentResult = Test-TargetResource -IsSingleInstance Yes -EncryptData $Param
                    $TestEnvironmentResult | Should -Be $true
                }

                It 'Should return True when IrpStackSize setting changes are required' {
                    $Param = $Params.IrpStackSize - 1
                    $TestEnvironmentResult = Test-TargetResource -IsSingleInstance Yes -IrpStackSize $Param
                    $TestEnvironmentResult | Should -Be $true
                }

                It 'Should return True when KeepAliveTime setting changes are required' {
                    $Param = $Params.KeepAliveTime - 1
                    $TestEnvironmentResult = Test-TargetResource -IsSingleInstance Yes -KeepAliveTime $Param
                    $TestEnvironmentResult | Should -Be $true
                }

                It 'Should return True when MaxChannelPerSession setting changes are required' {
                    $Param = $Params.MaxChannelPerSession - 1
                    $TestEnvironmentResult = Test-TargetResource -IsSingleInstance Yes -MaxChannelPerSession $Param
                    $TestEnvironmentResult | Should -Be $true
                }

                It 'Should return True when MaxMpxCount setting changes are required' {
                    $Param = $Params.MaxMpxCount - 1
                    $TestEnvironmentResult = Test-TargetResource -IsSingleInstance Yes -MaxMpxCount $Param
                    $TestEnvironmentResult | Should -Be $true
                }

                It 'Should return True when MaxSessionPerConnection setting changes are required' {
                    $Param = $Params.MaxSessionPerConnection - 1
                    $TestEnvironmentResult = Test-TargetResource -IsSingleInstance Yes -MaxSessionPerConnection $Param
                    $TestEnvironmentResult | Should -Be $true
                }

                It 'Should return True when MaxThreadsPerQueue setting changes are required' {
                    $Param = $Params.MaxThreadsPerQueue - 1
                    $TestEnvironmentResult = Test-TargetResource -IsSingleInstance Yes -MaxThreadsPerQueue $Param
                    $TestEnvironmentResult | Should -Be $true
                }

                It 'Should return True when MaxWorkItems setting changes are required' {
                    $Param = $Params.MaxWorkItems - 1
                    $TestEnvironmentResult = Test-TargetResource -IsSingleInstance Yes -MaxWorkItems $Param
                    $TestEnvironmentResult | Should -Be $true
                }
            }
        }

        Describe 'MSFT_SmbServerConfiguration\Set-TargetResource' -Tag 'Set' {
            Context 'When configuration is required' {
                It 'Runs the Set-SmbServerConfiguration cmdlet with the parameters' {
                    Mock -CommandName Set-SmbServerConfiguration

                    Set-TargetResource @Params

                    Assert-MockCalled -CommandName Set-SmbServerConfiguration -Times 1
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
