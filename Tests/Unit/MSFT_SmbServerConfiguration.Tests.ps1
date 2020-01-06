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

        $testCases = @(
            @{
                smbSetting = 'AnnounceComment'
                newValue   = 'Test String'
            }
            @{
                smbSetting = 'AnnounceServer'
                newValue   = $true
            }
            @{
                smbSetting = 'AsynchronousCredits'
                newValue   = 32
            }
            @{
                smbSetting = 'AuditSmb1Access'
                newValue   = $true
            }
            @{
                smbSetting = 'AutoDisconnectTimeout'
                newValue   = 30
            }
            @{
                smbSetting = 'AutoShareServer'
                newValue   = $false
            }
            @{
                smbSetting = 'AutoShareWorkstation'
                newValue   = $false
            }
            @{
                smbSetting = 'CachedOpenLimit'
                newValue   = 20
            }
            @{
                smbSetting = 'DurableHandleV2TimeoutInSeconds'
                newValue   = 360
            }
            @{
                smbSetting = 'EnableAuthenticateUserSharing'
                newValue   = $true
            }
            @{
                smbSetting = 'EnableDownlevelTimewarp'
                newValue   = $true
            }
            @{
                smbSetting = 'EnableForcedLogoff'
                newValue   = $false
            }
            @{
                smbSetting = 'EnableLeasing'
                newValue   = $false
            }
            @{
                smbSetting = 'EnableMultiChannel'
                newValue   = $false
            }
            @{
                smbSetting = 'EnableOplocks'
                newValue   = $false
            }
            @{
                smbSetting = 'EnableSecuritySignature'
                newValue   = $true
            }
            @{
                smbSetting = 'EnableSMB1Protocol'
                newValue   = $true
            }
            @{
                smbSetting = 'EnableSMB2Protocol'
                newValue   = $false
            }
            @{
                smbSetting = 'EnableStrictNameChecking'
                newValue   = $false
            }
            @{
                smbSetting = 'EncryptData'
                newValue   = $true
            }
            @{
                smbSetting = 'IrpStackSize'
                newValue   = 30
            }
            @{
                smbSetting = 'KeepAliveTime'
                newValue   = 4
            }
            @{
                smbSetting = 'MaxChannelPerSession'
                newValue   = 16
            }
            @{
                smbSetting = 'MaxMpxCount'
                newValue   = 25
            }
            @{
                smbSetting = 'MaxSessionPerConnection'
                newValue   = 16000
            }
            @{
                smbSetting = 'MaxThreadsPerQueue'
                newValue   = 10
            }
            @{
                smbSetting = 'MaxWorkItems'
                newValue   = 2
            }
            @{
                smbSetting = 'NullSessionPipes'
                newValue   = 'TestPipe'
            }
            @{
                smbSetting = 'NullSessionShares'
                newValue   = 'TestShare'
            }
            @{
                smbSetting = 'OplockBreakWait'
                newValue   = 60
            }
            @{
                smbSetting = 'PendingClientTimeoutInSeconds'
                newValue   = 240
            }
            @{
                smbSetting = 'RejectUnencryptedAccess'
                newValue   = $false
            }
            @{
                smbSetting = 'RequireSecuritySignature'
                newValue   = $true
            }
            @{
                smbSetting = 'ServerHidden'
                newValue   = $false
            }
            @{
                smbSetting = 'Smb2CreditsMax'
                newValue   = 1024
            }
            @{
                smbSetting = 'Smb2CreditsMin'
                newValue   = 256
            }
            @{
                smbSetting = 'SmbServerNameHardeningLevel'
                newValue   = 1
            }
            @{
                smbSetting = 'TreatHostAsStableStorage'
                newValue   = $true
            }
            @{
                smbSetting = 'ValidateAliasNotCircular'
                newValue   = $false
            }
            @{
                smbSetting = 'ValidateShareScope'
                newValue   = $false
            }
            @{
                smbSetting = 'ValidateShareScopeNotAliased'
                newValue   = $false
            }
            @{
                smbSetting = 'ValidateTargetName'
                newValue   = $false
            }
        )

        $mocks = @{
            DefaultSettings = @{
                AnnounceComment                 = ''
                AnnounceServer                  = $false
                AsynchronousCredits             = 64
                AuditSmb1Access                 = $false
                AutoDisconnectTimeout           = 15
                AutoShareServer                 = $true
                AutoShareWorkstation            = $true
                CachedOpenLimit                 = 10
                DurableHandleV2TimeoutInSeconds = 180
                EnableAuthenticateUserSharing   = $false
                EnableDownlevelTimewarp         = $false
                EnableForcedLogoff              = $true
                EnableLeasing                   = $true
                EnableMultiChannel              = $true
                EnableOplocks                   = $true
                EnableSecuritySignature         = $false
                EnableSMB1Protocol              = $false
                EnableSMB2Protocol              = $true
                EnableStrictNameChecking        = $true
                EncryptData                     = $false
                IrpStackSize                    = 15
                KeepAliveTime                   = 2
                MaxChannelPerSession            = 32
                MaxMpxCount                     = 50
                MaxSessionPerConnection         = 16384
                MaxThreadsPerQueue              = 20
                MaxWorkItems                    = 1
                NullSessionPipes                = ''
                NullSessionShares               = ''
                OplockBreakWait                 = 35
                PendingClientTimeoutInSeconds   = 120
                RejectUnencryptedAccess         = $true
                RequireSecuritySignature        = $false
                ServerHidden                    = $true
                Smb2CreditsMax                  = 2048
                Smb2CreditsMin                  = 128
                SmbServerNameHardeningLevel     = 0
                TreatHostAsStableStorage        = $false
                ValidateAliasNotCircular        = $true
                ValidateShareScope              = $true
                ValidateShareScopeNotAliased    = $true
                ValidateTargetName              = $true
            }
        }

        $fullParams = @{
            IsSingleInstance                = 'Yes'
            AnnounceComment                 = ''
            AnnounceServer                  = $false
            AsynchronousCredits             = 64
            AuditSmb1Access                 = $false
            AutoDisconnectTimeout           = 15
            AutoShareServer                 = $true
            AutoShareWorkstation            = $true
            CachedOpenLimit                 = 10
            DurableHandleV2TimeoutInSeconds = 180
            EnableAuthenticateUserSharing   = $false
            EnableDownlevelTimewarp         = $false
            EnableForcedLogoff              = $true
            EnableLeasing                   = $true
            EnableMultiChannel              = $true
            EnableOplocks                   = $true
            EnableSecuritySignature         = $false
            EnableSMB1Protocol              = $false
            EnableSMB2Protocol              = $true
            EnableStrictNameChecking        = $true
            EncryptData                     = $false
            IrpStackSize                    = 15
            KeepAliveTime                   = 2
            MaxChannelPerSession            = 32
            MaxMpxCount                     = 50
            MaxSessionPerConnection         = 16384
            MaxThreadsPerQueue              = 20
            MaxWorkItems                    = 1
            NullSessionPipes                = ''
            NullSessionShares               = ''
            OplockBreakWait                 = 35
            PendingClientTimeoutInSeconds   = 120
            RejectUnencryptedAccess         = $true
            RequireSecuritySignature        = $false
            ServerHidden                    = $true
            Smb2CreditsMax                  = 2048
            Smb2CreditsMin                  = 128
            SmbServerNameHardeningLevel     = 0
            TreatHostAsStableStorage        = $false
            ValidateAliasNotCircular        = $true
            ValidateShareScope              = $true
            ValidateShareScopeNotAliased    = $true
            ValidateTargetName              = $true
        }

        Describe 'MSFT_SmbServerConfiguration\Get-TargetResource' -Tag 'Get' {
            Context 'When getting the Target Resource information' {
                It 'Should get the current SMB server configuration state' {
                    $SmbServerConfiguration = Get-TargetResource -IsSingleInstance Yes

                    $SmbServerConfiguration.EnableSMB1Protocol | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.AnnounceComment | Should -BeOfType String
                    $SmbServerConfiguration.AnnounceServer | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.AsynchronousCredits | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.AuditSmb1Access | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.AutoDisconnectTimeout | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.AutoShareServer | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.AutoShareWorkstation | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.CachedOpenLimit | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.DurableHandleV2TimeoutInSeconds | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.EnableAuthenticateUserSharing | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.EnableDownlevelTimewarp | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.EnableForcedLogoff | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.EnableLeasing | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.EnableMultiChannel | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.EnableOplocks | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.EnableSecuritySignature | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.EnableSMB2Protocol | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.EnableStrictNameChecking | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.EncryptData | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.IrpStackSize | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.KeepAliveTime | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.MaxChannelPerSession | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.MaxMpxCount | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.MaxSessionPerConnection | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.MaxThreadsPerQueue | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.MaxWorkItems | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.NullSessionPipes | Should -BeOfType String
                    $SmbServerConfiguration.NullSessionShares | Should -BeOfType String
                    $SmbServerConfiguration.OplockBreakWait | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.PendingClientTimeoutInSeconds | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.RejectUnencryptedAccess | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.RequireSecuritySignature | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.ServerHidden | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.Smb2CreditsMax | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.Smb2CreditsMin | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.SmbServerNameHardeningLevel | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.TreatHostAsStableStorage | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.ValidateAliasNotCircular | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.ValidateShareScope | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.ValidateShareScopeNotAliased | Should -Not -BeNullOrEmpty
                    $SmbServerConfiguration.ValidateTargetName| Should -Not -BeNullOrEmpty
                }
            }
        }

        Describe 'MSFT_SmbServerConfiguration\Test-TargetResource' -Tag 'Test' {
            Context 'When the SMB Server is in the desired state' {
                It 'Test-TargetResource should return true' {
                    Mock -CommandName Get-SmbServerConfiguration { return $mocks.DefaultSettings }

                    $TestEnvironmentResult = Test-TargetResource @fullParams
                    $TestEnvironmentResult | Should -BeTrue
                }
            }

            Context 'When the SMB Server is not in the desired state' {
                It 'Should return false when <smbSetting> setting changes are required' -TestCases $testCases {
                    param ($smbSetting, $newValue)

                    Mock -CommandName Get-SmbServerConfiguration { return $mocks.DefaultSettings }

                    $caseParams = @{
                        IsSingleInstance = 'Yes'
                        $smbSetting      = $newValue
                    }

                    $TestEnvironmentResult = Test-TargetResource @caseParams
                    $TestEnvironmentResult | Should -BeFalse
                }
            }
        }

        Describe 'MSFT_SmbServerConfiguration\Set-TargetResource' -Tag 'Set' {
            Context 'When configuration is required' {
                It 'Runs the Set-SmbServerConfiguration cmdlet when the <smbSetting> needs to be changed' -TestCases $testCases {
                    param ($smbSetting, $newValue)

                    Mock -CommandName Get-SmbServerConfiguration { return $mocks.DefaultSettings }
                    Mock -CommandName Set-SmbServerConfiguration

                    $caseParams = @{
                        IsSingleInstance = 'Yes'
                        $smbSetting      = $newValue
                    }

                    Set-TargetResource @caseParams

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
