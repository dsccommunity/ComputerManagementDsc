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
$script:localizedData = Get-LocalizedData -ResourceName 'MSFT_SmbServer'

<#
    .SYNOPSIS
        Returns the current state of the SMB Server.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
    )

    Write-Verbose -Message ($script:localizedData.GetTargetResourceMessage -f $Name)

    $smbServer = Get-SmbServerConfiguration -ErrorAction 'SilentlyContinue'

    return $smbServer
}

<#
    .SYNOPSIS
        Determines if the SMB Server is in the desired state.

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
        [Parameter()]
        [string]
        $AnnounceComment,

        [Parameter()]
        [boolean]
        $AnnounceServer,

        [Parameter()]
        [uint32]
        $AsynchronousCredits,

        [Parameter()]
        [boolean]
        $AuditSmb1Access,

        [Parameter()]
        [uint32]
        $AutoDisconnectTimeout,

        [Parameter()]
        [boolean]
        $AutoShareServer,

        [Parameter()]
        [boolean]
        $AutoShareWorkstation,

        [Parameter()]
        [uint32]
        $CachedOpenLimit,

        [Parameter()]
        [uint32]
        $DurableHandleV2TimeoutInSeconds,

        [Parameter()]
        [boolean]
        $EnableAuthenticateUserSharing,

        [Parameter()]
        [boolean]
        $EnableDownlevelTimewarp,

        [Parameter()]
        [boolean]
        $EnableForcedLogoff,

        [Parameter()]
        [boolean]
        $EnableLeasing,

        [Parameter()]
        [boolean]
        $EnableMultiChannel,
        
        [Parameter()]
        [boolean]
        $EnableOplocks,

        [Parameter()]
        [boolean]
        $EnableSMB1Protocol,

        [Parameter()]
        [boolean]
        $EnableSMB2Protocol,

        [Parameter()]
        [boolean]
        $EnableSecuritySignature,

        [Parameter()]
        [boolean]
        $EnableStrictNameChecking,

        [Parameter()]
        [boolean]
        $EncryptData,

        [Parameter()]
        [uint32]
        $IrpStackSize,

        [Parameter()]
        [uint32]
        $KeepAliveTime,
        
        [Parameter()]
        [uint32]
        $MaxChannelPerSession,

        [Parameter()]
        [uint32]
        $MaxMpxCount,
        
        [Parameter()]
        [uint32]
        $MaxSessionPerConnection,
        
        [Parameter()]
        [uint32]
        $MaxThreadsPerQueue,

        [Parameter()]
        [uint32]
        $MaxWorkItems,

        [Parameter()]
        [string]
        $NullSessionPipes,

        [Parameter()]
        [string]
        $NullSessionShares,

        [Parameter()]
        [uint32]
        $OplockBreakWait,

        [Parameter()]
        [uint32]
        $PendingClientTimeoutInSeconds,

        [Parameter()]
        [boolean]
        $RejectUnencryptedAccess,

        [Parameter()]
        [boolean]
        $RequireSecuritySignature,

        [Parameter()]
        [boolean]
        $ServerHidden,

        [Parameter()]
        [uint32]
        $Smb2CreditsMax,

        [Parameter()]
        [uint32]
        $Smb2CreditsMin,

        [Parameter()]
        [uint32]
        $SmbServerNameHardeningLevel,

        [Parameter()]
        [boolean]
        $TreatHostAsStableStorage,
        
        [Parameter()]
        [boolean]
        $ValidateAliasNotCircular,

        [Parameter()]
        [boolean]
        $ValidateShareScope,

        [Parameter()]
        [boolean]
        $ValidateShareScopeNotAliased,

        [Parameter()]
        [boolean]
        $ValidateTargetName
    )

    Write-Verbose -Message ($script:localizedData.UpdatingProperties)

    Set-SmbServerConfiguration @PSBoundParameters
}

<#
    .SYNOPSIS
        Determines if the SMB Server is in the desired state.

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
        [Parameter()]
        [string]
        $AnnounceComment,

        [Parameter()]
        [boolean]
        $AnnounceServer,

        [Parameter()]
        [uint32]
        $AsynchronousCredits,

        [Parameter()]
        [boolean]
        $AuditSmb1Access,

        [Parameter()]
        [uint32]
        $AutoDisconnectTimeout,

        [Parameter()]
        [boolean]
        $AutoShareServer,

        [Parameter()]
        [boolean]
        $AutoShareWorkstation,

        [Parameter()]
        [uint32]
        $CachedOpenLimit,

        [Parameter()]
        [uint32]
        $DurableHandleV2TimeoutInSeconds,

        [Parameter()]
        [boolean]
        $EnableAuthenticateUserSharing,

        [Parameter()]
        [boolean]
        $EnableDownlevelTimewarp,

        [Parameter()]
        [boolean]
        $EnableForcedLogoff,

        [Parameter()]
        [boolean]
        $EnableLeasing,

        [Parameter()]
        [boolean]
        $EnableMultiChannel,
        
        [Parameter()]
        [boolean]
        $EnableOplocks,

        [Parameter()]
        [boolean]
        $EnableSMB1Protocol,

        [Parameter()]
        [boolean]
        $EnableSMB2Protocol,

        [Parameter()]
        [boolean]
        $EnableSecuritySignature,

        [Parameter()]
        [boolean]
        $EnableStrictNameChecking,

        [Parameter()]
        [boolean]
        $EncryptData,

        [Parameter()]
        [uint32]
        $IrpStackSize,

        [Parameter()]
        [uint32]
        $KeepAliveTime,
        
        [Parameter()]
        [uint32]
        $MaxChannelPerSession,

        [Parameter()]
        [uint32]
        $MaxMpxCount,
        
        [Parameter()]
        [uint32]
        $MaxSessionPerConnection,
        
        [Parameter()]
        [uint32]
        $MaxThreadsPerQueue,

        [Parameter()]
        [uint32]
        $MaxWorkItems,

        [Parameter()]
        [string]
        $NullSessionPipes,

        [Parameter()]
        [string]
        $NullSessionShares,

        [Parameter()]
        [uint32]
        $OplockBreakWait,

        [Parameter()]
        [uint32]
        $PendingClientTimeoutInSeconds,

        [Parameter()]
        [boolean]
        $RejectUnencryptedAccess,

        [Parameter()]
        [boolean]
        $RequireSecuritySignature,

        [Parameter()]
        [boolean]
        $ServerHidden,

        [Parameter()]
        [uint32]
        $Smb2CreditsMax,

        [Parameter()]
        [uint32]
        $Smb2CreditsMin,

        [Parameter()]
        [uint32]
        $SmbServerNameHardeningLevel,

        [Parameter()]
        [boolean]
        $TreatHostAsStableStorage,
        
        [Parameter()]
        [boolean]
        $ValidateAliasNotCircular,

        [Parameter()]
        [boolean]
        $ValidateShareScope,

        [Parameter()]
        [boolean]
        $ValidateShareScopeNotAliased,

        [Parameter()]
        [boolean]
        $ValidateTargetName
    )

    Write-Verbose -Message ($script:localizedData.TestTargetResourceMessage)

    $resourceRequiresUpdate = $false

    $currentSmbServerConfiguration = Get-TargetResource

    if($AnnounceComment)
    {
        if($AnnounceComment -ne $currentSmbServerConfiguration.AnnounceComment)
        {
            $resourceRequiresUpdate = $true
        }
    }
    
    if($AnnounceServer)
    {
        if($AnnounceServer -ne $currentSmbServerConfiguration.AnnounceServer)
        {
            $resourceRequiresUpdate = $true
        }
    }

    if($AsynchronousCredits)
    {
        if($AsynchronousCredits -ne $currentSmbServerConfiguration.AsynchronousCredits)
        {
            $resourceRequiresUpdate = $true
        }
    }

    if($AuditSmb1Access)
    {
        if($AuditSmb1Access -ne $currentSmbServerConfiguration.AuditSmb1Access)
        {
            $resourceRequiresUpdate = $true
        }
    }

    if($AutoDisconnectTimeout)
    {
        if($AutoDisconnectTimeout -ne $currentSmbServerConfiguration.AutoDisconnectTimeout)
        {
            $resourceRequiresUpdate = $true
        }    
    }

    if($AutoShareServer)
    {
        if($AutoShareServer -ne $currentSmbServerConfiguration.AutoShareServer)
        {
            $resourceRequiresUpdate = $true
        }
    }

    if($AutoShareWorkstation)
    {
        if($AutoShareWorkstation -ne $currentSmbServerConfiguration.AutoShareWorkstation)
        {
            $resourceRequiresUpdate = $true
        }
    }

    if($CachedOpenLimit)
    {
        if($CachedOpenLimit -ne $currentSmbServerConfiguration.CachedOpenLimit)
        {
            $resourceRequiresUpdate = $true
        }
    }

    if($DurableHandleV2TimeoutInSeconds)
    {
        if($DurableHandleV2TimeoutInSeconds -ne $currentSmbServerConfiguration.DurableHandleV2TimeoutInSeconds)
        {
            $resourceRequiresUpdate = $true
        }
    }

    if($EnableAuthenticateUserSharing)
    {
        if($EnableAuthenticateUserSharing -ne $currentSmbServerConfiguration.EnableAuthenticateUserSharing)
        {
            $resourceRequiresUpdate = $true
        }
    }

    if($EnableDownlevelTimewarp)
    {
        if($EnableDownlevelTimewarp -ne $currentSmbServerConfiguration.EnableDownlevelTimewarp)
        {
            $resourceRequiresUpdate = $true
        }
    }

    if($EnableForcedLogoff)
    {
        if($EnableForcedLogoff -ne $currentSmbServerConfiguration.EnableForcedLogoff)
        {
            $resourceRequiresUpdate = $true
        }
    }

    if($EnableLeasing)
    {
        if($EnableLeasing -ne $currentSmbServerConfiguration.EnableLeasing)
        {
            $resourceRequiresUpdate = $true
        }
    }

    if($EnableMultiChannel)
    {
        if($EnableMultiChannel -ne $currentSmbServerConfiguration.EnableMultiChannel)
        {
            $resourceRequiresUpdate = $true
        }
    }
    
    if($EnableOplocks)
    
    {   
        if($EnableOplocks -ne $currentSmbServerConfiguration.EnableOplocks)
        {
            $resourceRequiresUpdate = $true
        }
    }

    if($EnableSMB1Protocol)
    {
        if($EnableSMB1Protocol -ne $currentSmbServerConfiguration.EnableSMB1Protocol)
        {
            $resourceRequiresUpdate = $true
        }
    }

    if($EnableSMB2Protocol)
    {
        if($EnableSMB2Protocol -ne $currentSmbServerConfiguration.EnableSMB2Protocol)
        {
            $resourceRequiresUpdate = $true
        }
    }

    if($EnableSecuritySignature)
    {
        if($EnableSecuritySignature -ne $currentSmbServerConfiguration.EnableSecuritySignature)
        {
            $resourceRequiresUpdate = $true
        }
    }

    if($EnableStrictNameChecking)
    {
        if($EnableStrictNameChecking -ne $currentSmbServerConfiguration.EnableStrictNameChecking)
        {
            $resourceRequiresUpdate = $true
        }
    }

    if($EncryptData)
    {
        if($EncryptData -ne $currentSmbServerConfiguration.EncryptData)
        {
            $resourceRequiresUpdate = $true
        }
    }

    if($IrpStackSize)
    {
        if($IrpStackSize -ne $currentSmbServerConfiguration.IrpStackSize)
        {
            $resourceRequiresUpdate = $true
        }
    }

    if($KeepAliveTime)
    {
        if($KeepAliveTime -ne $currentSmbServerConfiguration.KeepAliveTime)
        {
            $resourceRequiresUpdate = $true
        }
    }

    if($MaxChannelPerSession)
    {
        if($MaxChannelPerSession -ne $currentSmbServerConfiguration.MaxChannelPerSession)
        {
            $resourceRequiresUpdate = $true
        }
    }

    if($MaxMpxCount)
    {
        if($MaxMpxCount -ne $currentSmbServerConfiguration.MaxMpxCount)
        {
            $resourceRequiresUpdate = $true
        }
    }
    
    if($MaxSessionPerConnection)
    {
        if($MaxSessionPerConnection -ne $currentSmbServerConfiguration.MaxSessionPerConnection)
        {
            $resourceRequiresUpdate = $true
        }
    }

    if($MaxThreadsPerQueue)
    {
        if($MaxThreadsPerQueue -ne $currentSmbServerConfiguration.MaxThreadsPerQueue)
        {
            $resourceRequiresUpdate = $true
        }
    }

    if($MaxWorkItems)
    {
        if($MaxWorkItems -ne $currentSmbServerConfiguration.MaxWorkItems)
        {
            $resourceRequiresUpdate = $true
        }
    }

    if($NullSessionPipes)
    {
        if($NullSessionPipes -ne $currentSmbServerConfiguration.NullSessionPipes)
        {
            $resourceRequiresUpdate = $true
        }
    }
    
    if($NullSessionShares)
    {
        if($NullSessionShares -ne $currentSmbServerConfiguration.NullSessionShares)
        {
            $resourceRequiresUpdate = $true
        }
    }

    if($OplockBreakWait)
    {
        if($OplockBreakWait -ne $currentSmbServerConfiguration.OplockBreakWait)
        {
            $resourceRequiresUpdate = $true
        }
    }

    if($PendingClientTimeoutInSeconds)
    {
        if($PendingClientTimeoutInSeconds -ne $currentSmbServerConfiguration.PendingClientTimeoutInSeconds)
        {
            $resourceRequiresUpdate = $true
        }
    }

    if($RejectUnencryptedAccess)
    {
        if($RejectUnencryptedAccess -ne $currentSmbServerConfiguration.RejectUnencryptedAccess)
        {
            $resourceRequiresUpdate = $true
        }
    }

    if($RequireSecuritySignature)
    {
        if($RequireSecuritySignature -ne $currentSmbServerConfiguration.RequireSecuritySignature)
        {
            $resourceRequiresUpdate = $true
        }
    }
    
    if($ServerHidden)
    {
        if($ServerHidden -ne $currentSmbServerConfiguration.ServerHidden)
        {
            $resourceRequiresUpdate = $true
        }
    }

    if($Smb2CreditsMax)
    {
        if($Smb2CreditsMax -ne $currentSmbServerConfiguration.Smb2CreditsMax)
        {
            $resourceRequiresUpdate = $true
        }
    }

    if($Smb2CreditsMin)
    {
        if($Smb2CreditsMin -ne $currentSmbServerConfiguration.Smb2CreditsMin)
        {
            $resourceRequiresUpdate = $true
        }
    }
    
    if($SmbServerNameHardeningLevel)
    {
        if($SmbServerNameHardeningLevel -ne $currentSmbServerConfiguration.SmbServerNameHardeningLevel)
        {
            $resourceRequiresUpdate = $true
        }
    }

    if($TreatHostAsStableStorage)
    {
        if($TreatHostAsStableStorage -ne $currentSmbServerConfiguration.TreatHostAsStableStorage)
        {
            $resourceRequiresUpdate = $true
        }
    }

    if($ValidateAliasNotCircular)
    {
        if($ValidateAliasNotCircular -ne $currentSmbServerConfiguration.ValidateAliasNotCircular)
        {
            $resourceRequiresUpdate = $true
        }
    }

    if($ValidateShareScope)
    {
        if($ValidateShareScope -ne $currentSmbServerConfiguration.ValidateShareScope)
        {
            $resourceRequiresUpdate = $true
        }
    }

    if($ValidateShareScopeNotAliased)
    {
        if($ValidateShareScopeNotAliased -ne $currentSmbServerConfiguration.ValidateShareScopeNotAliased)
        {
            $resourceRequiresUpdate = $true
        }
    }

    if($ValidateTargetName)
    {
        if($ValidateTargetName -ne $currentSmbServerConfiguration.ValidateTargetName)
        {
            $resourceRequiresUpdate = $true
        }
    }
  
    return $resourceRequiresUpdate
}
