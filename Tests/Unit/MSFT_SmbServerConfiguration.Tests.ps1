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
                It 'Should return True when changes are required' {
                    
                    switch ($Params.EnableSMB1Protocol) 
                    {
                        $false 
                        {
                            $Params.EnableSMB1Protocol = $true
                        }
                        $true 
                        {
                            $Params.EnableSMB1Protocol = $false
                        }
                        default
                        {
                            $Params.EnableSMB1Protocol = $false
                        }
                    }
                    
                    $TestEnvironmentResult = Test-TargetResource @Params

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
