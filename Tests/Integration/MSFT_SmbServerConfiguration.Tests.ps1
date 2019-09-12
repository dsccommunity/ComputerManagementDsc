#region HEADER
$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'MSFT_SmbServerConfiguration'

# Integration Test Template Version: 1.3.3
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
    -TestType Integration
#endregion

$script:CurrentSmbServerConfigBackup = Get-SmbServerConfiguration

try
{
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configFile

    Describe "$($script:dscResourceName)_Integration" {

        $configData = @{
            AllNodes = @(
                @{
                    NodeName                        = 'localhost'
                    IsSingleInstance                = 'Yes'
                    AnnounceComment                 = 'Test String'
                    AnnounceServer                  = $true
                    AsynchronousCredits             = 32
                    AuditSmb1Access                 = $true
                    AutoDisconnectTimeout           = 30
                    AutoShareServer                 = $false
                    AutoShareWorkstation            = $false
                    CachedOpenLimit                 = 20
                    DurableHandleV2TimeoutInSeconds = 90
                    EnableAuthenticateUserSharing   = $true
                    EnableDownlevelTimewarp         = $true
                    EnableForcedLogoff              = $false
                    EnableLeasing                   = $false
                    EnableMultiChannel              = $false
                    EnableOplocks                   = $false
                    EnableSecuritySignature         = $true
                    EnableSMB1Protocol              = $false
                    EnableSMB2Protocol              = $false
                    EnableStrictNameChecking        = $false
                    EncryptData                     = $true
                    IrpStackSize                    = 20
                    KeepAliveTime                   = 3
                    MaxChannelPerSession            = 16
                    MaxMpxCount                     = 100
                    MaxSessionPerConnection         = 16000
                    MaxThreadsPerQueue              = 15
                    MaxWorkItems                    = 2
                    NullSessionPipes                = 'TestPipe'
                    NullSessionShares               = 'TestShare'
                    OplockBreakWait                 = 30
                    PendingClientTimeoutInSeconds   = 60
                    RejectUnencryptedAccess         = $false
                    RequireSecuritySignature        = $true
                    ServerHidden                    = $false
                    Smb2CreditsMax                  = 2000
                    Smb2CreditsMin                  = 256
                    SmbServerNameHardeningLevel     = 1
                    TreatHostAsStableStorage        = $true
                    ValidateAliasNotCircular        = $false
                    ValidateShareScope              = $false
                    ValidateShareScopeNotAliased    = $false
                    ValidateTargetName              = $false
                }
            )
        }

        It 'Should compile and apply the MOF without throwing' {
            {
                & "$($script:dscResourceName)_Config" `
                    -OutputPath $TestDrive `
                    -ConfigurationData $configData

                $startDscConfigurationParameters = @{
                    Path         = $TestDrive
                    ComputerName = 'localhost'
                    Wait         = $true
                    Verbose      = $true
                    Force        = $true
                    ErrorAction  = 'Stop'
                }

                Start-DscConfiguration @startDscConfigurationParameters
            } | Should -Not -Throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            {
                Get-DscConfiguration -Verbose -ErrorAction Stop
            } | Should -Not -Throw
        }

        It 'Should have set the resource and all the parameters should match' {
            $current = Get-DscConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
            }
            $current.AnnounceComment | Should -Be $configData.AllNodes[0].AnnounceComment
            #$current.SkipComponentBasedServicing | Should -Be $configData.AllNodes[0].SkipComponentBasedServicing
            #$current.ComponentBasedServicing | Should -BeFalse
            #$current.SkipWindowsUpdate | Should -Be $configData.AllNodes[0].SkipWindowsUpdate
            #$current.WindowsUpdate | Should -BeTrue
            #$current.SkipPendingFileRename | Should -Be $configData.AllNodes[0].SkipPendingFileRename
            #$current.PendingFileRename | Should -BeFalse
            #$current.SkipPendingComputerRename | Should -Be $configData.AllNodes[0].SkipPendingComputerRename
            #$current.PendingComputerRename | Should -BeFalse
            #$current.SkipCcmClientSDK | Should -Be $configData.AllNodes[0].SkipCcmClientSDK
            #$current.CcmClientSDK | Should -BeFalse
            #$current.RebootRequired | Should -BeTrue
        }
    }
}
finally
{
    #region FOOTER
    Set-SmbServerConfiguration -AnnounceComment $script:CurrentSmbServerConfigBackup.AnnounceComment `
        -AnnounceServer $script:CurrentSmbServerConfigBackup.AnnounceServer `
        -AsynchronousCredits $script:CurrentSmbServerConfigBackup.AsynchronousCredits `
        -AuditSmb1Access $script:CurrentSmbServerConfigBackup.AuditSmb1Access `
        -AutoDisconnectTimeout $script:CurrentSmbServerConfigBackup.AutoDisconnectTimeout `
        -AutoShareServer $script:CurrentSmbServerConfigBackup.AutoShareServer `
        -AutoShareWorkstation $script:CurrentSmbServerConfigBackup.AutoShareWorkstation `
        -CachedOpenLimit $script:CurrentSmbServerConfigBackup.CachedOpenLimit `
        -DurableHandleV2TimeoutInSeconds $script:CurrentSmbServerConfigBackup.DurableHandleV2TimeoutInSeconds `
        -EnableAuthenticateUserSharing $script:CurrentSmbServerConfigBackup.EnableAuthenticateUserSharing `
        -EnableDownlevelTimewarp $script:CurrentSmbServerConfigBackup.EnableDownlevelTimewarp `
        -EnableForcedLogoff $script:CurrentSmbServerConfigBackup.EnableForcedLogoff `
        -EnableLeasing $script:CurrentSmbServerConfigBackup.EnableLeasing `
        -EnableMultiChannel $script:CurrentSmbServerConfigBackup.EnableMultiChannel `
        -EnableOplocks $script:CurrentSmbServerConfigBackup.EnableOplocks `
        -EnableSecuritySignature $script:CurrentSmbServerConfigBackup.EnableSecuritySignature `
        -EnableSMB1Protocol $script:CurrentSmbServerConfigBackup.EnableSMB1Protocol `
        -EnableSMB2Protocol $script:CurrentSmbServerConfigBackup.EnableSMB2Protocol `
        -EnableStrictNameChecking $script:CurrentSmbServerConfigBackup.EnableStrictNameChecking `
        -EncryptData $script:CurrentSmbServerConfigBackup.EncryptData `
        -IrpStackSize $script:CurrentSmbServerConfigBackup.IrpStackSize `
        -KeepAliveTime $script:CurrentSmbServerConfigBackup.KeepAliveTime `
        -MaxChannelPerSession $script:CurrentSmbServerConfigBackup.MaxChannelPerSession `
        -MaxMpxCount $script:CurrentSmbServerConfigBackup.MaxMpxCount `
        -MaxSessionPerConnection $script:CurrentSmbServerConfigBackup.MaxSessionPerConnection `
        -MaxThreadsPerQueue $script:CurrentSmbServerConfigBackup.MaxThreadsPerQueue `
        -MaxWorkItems $script:CurrentSmbServerConfigBackup.MaxWorkItems `
        -NullSessionPipes $script:CurrentSmbServerConfigBackup.NullSessionPipes `
        -NullSessionShares $script:CurrentSmbServerConfigBackup.NullSessionShares `
        -OplockBreakWait $script:CurrentSmbServerConfigBackup.OplockBreakWait `
        -PendingClientTimeoutInSeconds $script:CurrentSmbServerConfigBackup.PendingClientTimeoutInSeconds `
        -RejectUnencryptedAccess $script:CurrentSmbServerConfigBackup.RejectUnencryptedAccess `
        -RequireSecuritySignature $script:CurrentSmbServerConfigBackup.RequireSecuritySignature `
        -ServerHidden $script:CurrentSmbServerConfigBackup.ServerHidden `
        -Smb2CreditsMax $script:CurrentSmbServerConfigBackup.Smb2CreditsMax `
        -Smb2CreditsMin $script:CurrentSmbServerConfigBackup.Smb2CreditsMin `
        -SmbServerNameHardeningLevel $script:CurrentSmbServerConfigBackup.SmbServerNameHardeningLevel `
        -TreatHostAsStableStorage $script:CurrentSmbServerConfigBackup.TreatHostAsStableStorage `
        -ValidateAliasNotCircular $script:CurrentSmbServerConfigBackup.ValidateAliasNotCircular `
        -ValidateShareScope $script:CurrentSmbServerConfigBackup.ValidateShareScope `
        -ValidateShareScopeNotAliased $script:CurrentSmbServerConfigBackup.ValidateShareScopeNotAliased `
        -ValidateTargetName $script:CurrentSmbServerConfigBackup.ValidateTargetName `
        -Confirm:$false

    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
