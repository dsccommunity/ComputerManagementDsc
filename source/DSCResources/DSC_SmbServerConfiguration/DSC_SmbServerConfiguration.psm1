$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the ComputerManagementDsc Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'ComputerManagementDsc.Common' `
            -ChildPath 'ComputerManagementDsc.Common.psm1')) -Force

# Import the ComputerManagementDsc Resource Helper Module
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'ComputerManagementDsc.Common' `
            -ChildPath 'ComputerManagementDsc.Common.psm1'))

# Import Localization Strings
$script:localizedData = Get-LocalizedData -ResourceName 'DSC_SmbServerConfiguration'

$resourceData = Import-LocalizedData `
    -BaseDirectory $PSScriptRoot `
    -FileName 'DSC_SmbServerConfiguration.data.psd1'

$script:smbServerSettings = $resourceData.smbServerSettings

<#
    .SYNOPSIS
        Returns the current state of the SMB Server.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance
    )

    Write-Verbose -Message ($script:localizedData.GetTargetResourceMessage -f $Name)

    $smbReturn = @{}
    $smbServer = Get-SmbServerConfiguration -ErrorAction 'SilentlyContinue'
    $smbReturn.Add('IsSingleInstance', $IsSingleInstance)

    foreach ($smbServerSetting in $script:smbServerSettings)
    {
        $smbReturn.Add($smbServerSetting, $smbServer.$smbServerSetting)
    }

    return $smbReturn
}

<#
    .SYNOPSIS
        Determines if the SMB Server is in the desired state.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER AnnounceComment
        Specifies the announce comment string.

    .PARAMETER AnnounceServer
        Indicates that this server announces itself by using browser announcements.

    .PARAMETER AsynchronousCredits
        Specifies the asynchronous credits.

    .PARAMETER AuditSmb1Access
        Enables auditing of SMB version 1 protocol in Windows Event Log.

    .PARAMETER AutoDisconnectTimeout
        Specifies the auto disconnect time-out.

    .PARAMETER AutoShareServer
        Specifies that the default server shares are shared out.

    .PARAMETER AutoShareWorkstation
        Specifies whether the default workstation shares are shared out.

    .PARAMETER CachedOpenLimit
        Specifies the maximum number of cached open files.

    .PARAMETER DurableHandleV2TimeoutInSeconds
        Specifies the durable handle v2 time-out period, in seconds.

    .PARAMETER EnableAuthenticateUserSharing
        Specifies whether authenticate user sharing is enabled.

    .PARAMETER EnableDownlevelTimewarp
        Specifies whether down-level timewarp support is disabled.

    .PARAMETER EnableForcedLogoff
        Specifies whether forced logoff is enabled.

    .PARAMETER EnableLeasing
        Specifies whether leasing is disabled.

    .PARAMETER EnableMultiChannel
        Specifies whether multi-channel is disabled.

    .PARAMETER EnableOplocks
        Specifies whether the opportunistic locks are enabled.

    .PARAMETER EnableSMB1Protocol
        Specifies whether the SMB1 protocol is enabled.

    .PARAMETER EnableSMB2Protocol
        Specifies whether the SMB2 protocol is enabled.

    .PARAMETER EnableSecuritySignature
        Specifies whether the security signature is enabled.

    .PARAMETER EnableStrictNameChecking
        Specifies whether the server should perform strict name checking on incoming connects.

    .PARAMETER EncryptData
        Specifies whether the sessions established on this server are encrypted.

    .PARAMETER IrpStackSize
        Specifies the default IRP stack size.

    .PARAMETER KeepAliveTime
        Specifies the keep alive time.

    .PARAMETER MaxChannelPerSession
        Specifies the maximum channels per session.

    .PARAMETER MaxMpxCount
        Specifies the maximum MPX count for SMB1.

    .PARAMETER MaxSessionPerConnection
        Specifies the maximum sessions per connection.

    .PARAMETER MaxThreadsPerQueue
        Specifies the maximum threads per queue.

    .PARAMETER MaxWorkItems
        Specifies the maximum SMB1 work items.

    .PARAMETER NullSessionPipes
        Specifies the null session pipes.

    .PARAMETER NullSessionShares
        Specifies the null session shares.

    .PARAMETER OplockBreakWait
        Specifies how long the create caller waits for an opportunistic lock break.

    .PARAMETER PendingClientTimeoutInSeconds
        Specifies the pending client time-out period, in seconds.

    .PARAMETER RejectUnencryptedAccess
        Specifies whether the client that does not support encryption is denied access if it attempts to connect to an encrypted share.

    .PARAMETER RequireSecuritySignature
        Specifies whether the security signature is required.

    .PARAMETER ServerHidden
        Specifies whether the server announces itself.

    .PARAMETER Smb2CreditsMax
        Specifies the maximum SMB2 credits.

    .PARAMETER Smb2CreditsMin
        Specifies the minimum SMB2 credits.

    .PARAMETER SmbServerNameHardeningLevel
        Specifies the SMB Service name hardening level.

    .PARAMETER TreatHostAsStableStorage
        Specifies whether the host is treated as the stable storage.

    .PARAMETER ValidateAliasNotCircular
        Specifies whether the aliases that are not circular are validated.

    .PARAMETER ValidateShareScope
        Specifies whether the existence of share scopes is checked during share creation.

    .PARAMETER ValidateShareScopeNotAliased
        Specifies whether the share scope being aliased is validated.

    .PARAMETER ValidateTargetName
        Specifies whether the target name is validated.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter()]
        [System.String]
        $AnnounceComment,

        [Parameter()]
        [System.Boolean]
        $AnnounceServer,

        [Parameter()]
        [System.Uint32]
        $AsynchronousCredits,

        [Parameter()]
        [System.Boolean]
        $AuditSmb1Access,

        [Parameter()]
        [System.Uint32]
        $AutoDisconnectTimeout,

        [Parameter()]
        [System.Boolean]
        $AutoShareServer,

        [Parameter()]
        [System.Boolean]
        $AutoShareWorkstation,

        [Parameter()]
        [System.Uint32]
        $CachedOpenLimit,

        [Parameter()]
        [System.Uint32]
        $DurableHandleV2TimeoutInSeconds,

        [Parameter()]
        [System.Boolean]
        $EnableAuthenticateUserSharing,

        [Parameter()]
        [System.Boolean]
        $EnableDownlevelTimewarp,

        [Parameter()]
        [System.Boolean]
        $EnableForcedLogoff,

        [Parameter()]
        [System.Boolean]
        $EnableLeasing,

        [Parameter()]
        [System.Boolean]
        $EnableMultiChannel,

        [Parameter()]
        [System.Boolean]
        $EnableOplocks,

        [Parameter()]
        [System.Boolean]
        $EnableSMB1Protocol,

        [Parameter()]
        [System.Boolean]
        $EnableSMB2Protocol,

        [Parameter()]
        [System.Boolean]
        $EnableSecuritySignature,

        [Parameter()]
        [System.Boolean]
        $EnableStrictNameChecking,

        [Parameter()]
        [System.Boolean]
        $EncryptData,

        [Parameter()]
        [System.Uint32]
        $IrpStackSize,

        [Parameter()]
        [System.Uint32]
        $KeepAliveTime,

        [Parameter()]
        [System.Uint32]
        $MaxChannelPerSession,

        [Parameter()]
        [System.Uint32]
        $MaxMpxCount,

        [Parameter()]
        [System.Uint32]
        $MaxSessionPerConnection,

        [Parameter()]
        [System.Uint32]
        $MaxThreadsPerQueue,

        [Parameter()]
        [System.Uint32]
        $MaxWorkItems,

        [Parameter()]
        [System.String]
        $NullSessionPipes,

        [Parameter()]
        [System.String]
        $NullSessionShares,

        [Parameter()]
        [System.Uint32]
        $OplockBreakWait,

        [Parameter()]
        [System.Uint32]
        $PendingClientTimeoutInSeconds,

        [Parameter()]
        [System.Boolean]
        $RejectUnencryptedAccess,

        [Parameter()]
        [System.Boolean]
        $RequireSecuritySignature,

        [Parameter()]
        [System.Boolean]
        $ServerHidden,

        [Parameter()]
        [System.Uint32]
        $Smb2CreditsMax,

        [Parameter()]
        [System.Uint32]
        $Smb2CreditsMin,

        [Parameter()]
        [System.Uint32]
        $SmbServerNameHardeningLevel,

        [Parameter()]
        [System.Boolean]
        $TreatHostAsStableStorage,

        [Parameter()]
        [System.Boolean]
        $ValidateAliasNotCircular,

        [Parameter()]
        [System.Boolean]
        $ValidateShareScope,

        [Parameter()]
        [System.Boolean]
        $ValidateShareScopeNotAliased,

        [Parameter()]
        [System.Boolean]
        $ValidateTargetName
    )

    $null = $PSBoundParameters.Remove('IsSingleInstance')
    $null = $PSBoundParameters.Add('Confirm', $false)

    Write-Verbose -Message ($script:localizedData.UpdatingProperties)

    Set-SmbServerConfiguration @PSBoundParameters
}

<#
    .SYNOPSIS
        Determines if the SMB Server is in the desired state.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER AnnounceComment
        Specifies the announce comment string.

    .PARAMETER AnnounceServer
        Indicates that this server announces itself by using browser announcements.

    .PARAMETER AsynchronousCredits
        Specifies the asynchronous credits.

    .PARAMETER AuditSmb1Access
        Enables auditing of SMB version 1 protocol in Windows Event Log.

    .PARAMETER AutoDisconnectTimeout
        Specifies the auto disconnect time-out.

    .PARAMETER AutoShareServer
        Specifies that the default server shares are shared out.

    .PARAMETER AutoShareWorkstation
        Specifies whether the default workstation shares are shared out.

    .PARAMETER CachedOpenLimit
        Specifies the maximum number of cached open files.

    .PARAMETER DurableHandleV2TimeoutInSeconds
        Specifies the durable handle v2 time-out period, in seconds.

    .PARAMETER EnableAuthenticateUserSharing
        Specifies whether authenticate user sharing is enabled.

    .PARAMETER EnableDownlevelTimewarp
        Specifies whether down-level timewarp support is disabled.

    .PARAMETER EnableForcedLogoff
        Specifies whether forced logoff is enabled.

    .PARAMETER EnableLeasing
        Specifies whether leasing is disabled.

    .PARAMETER EnableMultiChannel
        Specifies whether multi-channel is disabled.

    .PARAMETER EnableOplocks
        Specifies whether the opportunistic locks are enabled.

    .PARAMETER EnableSMB1Protocol
        Specifies whether the SMB1 protocol is enabled.

    .PARAMETER EnableSMB2Protocol
        Specifies whether the SMB2 protocol is enabled.

    .PARAMETER EnableSecuritySignature
        Specifies whether the security signature is enabled.

    .PARAMETER EnableStrictNameChecking
        Specifies whether the server should perform strict name checking on incoming connects.

    .PARAMETER EncryptData
        Specifies whether the sessions established on this server are encrypted.

    .PARAMETER IrpStackSize
        Specifies the default IRP stack size.

    .PARAMETER KeepAliveTime
        Specifies the keep alive time.

    .PARAMETER MaxChannelPerSession
        Specifies the maximum channels per session.

    .PARAMETER MaxMpxCount
        Specifies the maximum MPX count for SMB1.

    .PARAMETER MaxSessionPerConnection
        Specifies the maximum sessions per connection.

    .PARAMETER MaxThreadsPerQueue
        Specifies the maximum threads per queue.

    .PARAMETER MaxWorkItems
        Specifies the maximum SMB1 work items.

    .PARAMETER NullSessionPipes
        Specifies the null session pipes.

    .PARAMETER NullSessionShares
        Specifies the null session shares.

    .PARAMETER OplockBreakWait
        Specifies how long the create caller waits for an opportunistic lock break.

    .PARAMETER PendingClientTimeoutInSeconds
        Specifies the pending client time-out period, in seconds.

    .PARAMETER RejectUnencryptedAccess
        Specifies whether the client that does not support encryption is denied access if it attempts to connect to an encrypted share.

    .PARAMETER RequireSecuritySignature
        Specifies whether the security signature is required.

    .PARAMETER ServerHidden
        Specifies whether the server announces itself.

    .PARAMETER Smb2CreditsMax
        Specifies the maximum SMB2 credits.

    .PARAMETER Smb2CreditsMin
        Specifies the minimum SMB2 credits.

    .PARAMETER SmbServerNameHardeningLevel
        Specifies the SMB Service name hardening level.

    .PARAMETER TreatHostAsStableStorage
        Specifies whether the host is treated as the stable storage.

    .PARAMETER ValidateAliasNotCircular
        Specifies whether the aliases that are not circular are validated.

    .PARAMETER ValidateShareScope
        Specifies whether the existence of share scopes is checked during share creation.

    .PARAMETER ValidateShareScopeNotAliased
        Specifies whether the share scope being aliased is validated.

    .PARAMETER ValidateTargetName
        Specifies whether the target name is validated.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter()]
        [System.String]
        $AnnounceComment,

        [Parameter()]
        [System.Boolean]
        $AnnounceServer,

        [Parameter()]
        [System.Uint32]
        $AsynchronousCredits,

        [Parameter()]
        [System.Boolean]
        $AuditSmb1Access,

        [Parameter()]
        [System.Uint32]
        $AutoDisconnectTimeout,

        [Parameter()]
        [System.Boolean]
        $AutoShareServer,

        [Parameter()]
        [System.Boolean]
        $AutoShareWorkstation,

        [Parameter()]
        [System.Uint32]
        $CachedOpenLimit,

        [Parameter()]
        [System.Uint32]
        $DurableHandleV2TimeoutInSeconds,

        [Parameter()]
        [System.Boolean]
        $EnableAuthenticateUserSharing,

        [Parameter()]
        [System.Boolean]
        $EnableDownlevelTimewarp,

        [Parameter()]
        [System.Boolean]
        $EnableForcedLogoff,

        [Parameter()]
        [System.Boolean]
        $EnableLeasing,

        [Parameter()]
        [System.Boolean]
        $EnableMultiChannel,

        [Parameter()]
        [System.Boolean]
        $EnableOplocks,

        [Parameter()]
        [System.Boolean]
        $EnableSMB1Protocol,

        [Parameter()]
        [System.Boolean]
        $EnableSMB2Protocol,

        [Parameter()]
        [System.Boolean]
        $EnableSecuritySignature,

        [Parameter()]
        [System.Boolean]
        $EnableStrictNameChecking,

        [Parameter()]
        [System.Boolean]
        $EncryptData,

        [Parameter()]
        [System.Uint32]
        $IrpStackSize,

        [Parameter()]
        [System.Uint32]
        $KeepAliveTime,

        [Parameter()]
        [System.Uint32]
        $MaxChannelPerSession,

        [Parameter()]
        [System.Uint32]
        $MaxMpxCount,

        [Parameter()]
        [System.Uint32]
        $MaxSessionPerConnection,

        [Parameter()]
        [System.Uint32]
        $MaxThreadsPerQueue,

        [Parameter()]
        [System.Uint32]
        $MaxWorkItems,

        [Parameter()]
        [System.String]
        $NullSessionPipes,

        [Parameter()]
        [System.String]
        $NullSessionShares,

        [Parameter()]
        [System.Uint32]
        $OplockBreakWait,

        [Parameter()]
        [System.Uint32]
        $PendingClientTimeoutInSeconds,

        [Parameter()]
        [System.Boolean]
        $RejectUnencryptedAccess,

        [Parameter()]
        [System.Boolean]
        $RequireSecuritySignature,

        [Parameter()]
        [System.Boolean]
        $ServerHidden,

        [Parameter()]
        [System.Uint32]
        $Smb2CreditsMax,

        [Parameter()]
        [System.Uint32]
        $Smb2CreditsMin,

        [Parameter()]
        [System.Uint32]
        $SmbServerNameHardeningLevel,

        [Parameter()]
        [System.Boolean]
        $TreatHostAsStableStorage,

        [Parameter()]
        [System.Boolean]
        $ValidateAliasNotCircular,

        [Parameter()]
        [System.Boolean]
        $ValidateShareScope,

        [Parameter()]
        [System.Boolean]
        $ValidateShareScopeNotAliased,

        [Parameter()]
        [System.Boolean]
        $ValidateTargetName
    )

    Write-Verbose -Message ($script:localizedData.TestTargetResourceMessage)

    $resourceCompliant = $true

    $currentSmbServerConfiguration = Get-TargetResource -IsSingleInstance Yes

    foreach ($smbParameter in $script:smbServerSettings)
    {
        if ($PSBoundParameters.ContainsKey($smbParameter))
        {
            Write-Verbose -Message ($script:localizedData.EvaluatingProperties `
                -f $smbParameter, $currentSmbServerConfiguration.$smbParameter, $PSBoundParameters.$smbParameter)

            if ($PSBoundParameters.$smbParameter -ne $currentSmbServerConfiguration.$smbParameter)
            {
                $resourceCompliant = $false
            }
        }
    }

    return $resourceCompliant
}

Export-ModuleMember -Function *-TargetResource
