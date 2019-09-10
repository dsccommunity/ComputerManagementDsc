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

        $Params = @{
            IsSingleInstance                = 'Yes'
            AnnounceServer                  = $False
            AsynchronousCredits             = 64
            AuditSmb1Access                 = $False
            AutoDisconnectTimeout           = 15
            AutoShareServer                 = $True
            AutoShareWorkstation            = $True
            CachedOpenLimit                 = 10
            DurableHandleV2TimeoutInSeconds = 180
            EnableAuthenticateUserSharing   = $False
            EnableDownlevelTimewarp         = $False
            EnableForcedLogoff              = $True
            EnableLeasing                   = $True
            EnableMultiChannel              = $True
            EnableOplocks                   = $True
            EnableSecuritySignature         = $False
            EnableSMB1Protocol              = $False
            EnableSMB2Protocol              = $True
            EnableStrictNameChecking        = $True
            EncryptData                     = $False
            IrpStackSize                    = 15
            KeepAliveTime                   = 2
            MaxChannelPerSession            = 32
            MaxMpxCount                     = 50
            MaxSessionPerConnection         = 16384
            MaxThreadsPerQueue              = 20
            MaxWorkItems                    = 1
            OplockBreakWait                 = 35
            PendingClientTimeoutInSeconds   = 120
            RejectUnencryptedAccess         = $True
            RequireSecuritySignature        = $False
            ServerHidden                    = $True
            Smb2CreditsMax                  = 2048
            Smb2CreditsMin                  = 128
            SmbServerNameHardeningLevel     = 0
            TreatHostAsStableStorage        = $False
            ValidateAliasNotCircular        = $True
            ValidateShareScope              = $True
            ValidateShareScopeNotAliased    = $True
            ValidateTargetName              = $True
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
                    
                    $Params.EnableSMB1Protocol = $true
                    
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
