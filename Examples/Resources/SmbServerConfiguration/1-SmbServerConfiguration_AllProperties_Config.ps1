<#PSScriptInfo
.VERSION 1.0.0
.GUID 4a847e98-a3f9-4552-8654-6c7006ef25cf
.AUTHOR Microsoft Corporation
.COMPANYNAME Microsoft Corporation
.COPYRIGHT (c) Microsoft Corporation. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/PowerShell/ComputerManagementDsc/blob/master/LICENSE
.PROJECTURI https://github.com/PowerShell/ComputerManagementDsc
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES First version.
.PRIVATEDATA 2016-Datacenter,2016-Datacenter-Server-Core
#>

#Requires -module ComputerManagementDsc

<#
    .DESCRIPTION
        This example configures all supported SMB Server settings for a node
        to ensure they are set to known values.
#>
Configuration SmbServerConfiguration_AllProperties_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        SmbServerConfiguration SmbServer
        {
            IsSingleInstance                = 'Yes'
            AnnounceComment                 = 'SMB server hello'
            AnnounceServer                  = $true
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
            NullSessionPipes                = 'NullPipe'
            NullSessionShares               = 'NullShare'
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
}
