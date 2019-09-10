# Description

The resource is used to manage SMB Server Settings

## Requirements

Windows Server 2012 or newer.

## Parameters

* **AnnounceComment** Specifies the announce comment string.
* **AnnounceServer** Specifies whether this server announces itself by using browser announcements.
* **AsynchronousCredits** Specifies the asynchronous credits.
* **AuditSmb1Access** Enables auditing of SMB version 1 protocol in Windows Event Log.
* **AutoDisconnectTimeout** Specifies the auto disconnect time-out.
* **AutoShareServer** Specifies that the default server shares are shared out.
* **AutoShareWorkstation** Specifies whether the default workstation shares are shared out.
* **CachedOpenLimit** [Description("Specifies the maximum number of cached open files.
* **DurableHandleV2TimeoutInSeconds** Specifies the durable handle v2 time-out period, in seconds.
* **EnableAuthenticateUserSharing** Specifies whether authenticate user sharing is enabled.
* **EnableDownlevelTimewarp** Specifies whether down-level timewarp support is disabled.
* **EnableForcedLogoff** Specifies whether forced logoff is enabled.
* **EnableLeasing** Specifies whether leasing is disabled.
* **EnableMultiChannel** Specifies whether multi-channel is disabled.
* **EnableOplocks** Specifies whether the opportunistic locks are enabled.
* **EnableSMB1Protocol** Specifies whether the SMB1 protocol is enabled.
* **EnableSMB2Protocol** Specifies whether the SMB2 protocol is enabled.
* **EnableSecuritySignature** Specifies whether the security signature is enabled.
* **EnableStrictNameChecking** Specifies whether the server should perform strict name checking on incoming connects.
* **EncryptData** Specifies whether the sessions established on this server are encrypted.
* **IrpStackSize** Specifies the default IRP stack size.
* **KeepAliveTime** Specifies the keep alive time.
* **MaxChannelPerSession** Specifies the maximum channels per session.
* **MaxMpxCount** Specifies the maximum MPX count for SMB1.
* **MaxSessionPerConnection** Specifies the maximum sessions per connection.
* **MaxThreadsPerQueue** Specifies the maximum threads per queue.
* **MaxWorkItems** Specifies the maximum SMB1 work items.
* **NullSessionPipes** Specifies the null session pipes.
* **NullSessionShares** Specifies the null session shares.
* **OplockBreakWait** Specifies how long the create caller waits for an opportunistic lock break.
* **PendingClientTimeoutInSeconds** Specifies the pending client time-out period, in seconds.
* **RejectUnencryptedAccess** Specifies whether the client that does not support encryption is denied access if it attempts to connect to an encrypted share.
* **RequireSecuritySignature** Specifies whether the security signature is required.
* **ServerHidden** Specifies whether the server announces itself.
* **Smb2CreditsMax** Specifies the maximum SMB2 credits.
* **Smb2CreditsMin** Specifies the minimum SMB2 credits.
* **SmbServerNameHardeningLevel** Specifies the SMB Service name hardening level.
* **TreatHostAsStableStorage** Specifies whether the host is treated as the stable storage.
* **ValidateAliasNotCircular** Specifies whether the aliases that are not circular are validated.
* **ValidateShareScope** Specifies whether the existence of share scopes is checked during share creation.
* **ValidateShareScopeNotAliased** Specifies whether the share scope being aliased is validated.
* **ValidateTargetName** Specifies whether the target name is validated.
