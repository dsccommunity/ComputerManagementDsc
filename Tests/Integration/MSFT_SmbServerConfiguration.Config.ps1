# Integration Test Config Template Version: 1.0.0
configuration MSFT_SmbServerConfiguration_config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    node $AllNodes.NodeName {
        SmbServerConfiguration SmbServer
        {
            IsSingleInstance                = $node.IsSingleInstance
            AnnounceComment                 = $node.AnnounceComment
            AnnounceServer                  = $node.AnnounceServer
            AsynchronousCredits             = $node.AsynchronousCredits
            AuditSmb1Access                 = $node.AuditSmb1Access
            AutoDisconnectTimeout           = $node.AutoDisconnectTimeout
            AutoShareServer                 = $node.AutoShareServer
            AutoShareWorkstation            = $node.AutoShareWorkstation
            CachedOpenLimit                 = $node.CachedOpenLimit
            DurableHandleV2TimeoutInSeconds = $node.DurableHandleV2TimeoutInSeconds
            EnableAuthenticateUserSharing   = $node.EnableAuthenticateUserSharing
            EnableDownlevelTimewarp         = $node.EnableDownlevelTimewarp
            EnableForcedLogoff              = $node.EnableForcedLogoff
            EnableLeasing                   = $node.EnableLeasing
            EnableMultiChannel              = $node.EnableMultiChannel
            EnableOplocks                   = $node.EnableOplocks
            EnableSecuritySignature         = $node.EnableSecuritySignature
            EnableSMB1Protocol              = $node.EnableSMB1Protocol
            EnableSMB2Protocol              = $node.EnableSMB2Protocol
            EnableStrictNameChecking        = $node.EnableStrictNameChecking
            EncryptData                     = $node.EncryptData
            IrpStackSize                    = $node.IrpStackSize
            KeepAliveTime                   = $node.KeepAliveTime
            MaxChannelPerSession            = $node.MaxChannelPerSession
            MaxMpxCount                     = $node.MaxMpxCount
            MaxSessionPerConnection         = $node.MaxSessionPerConnection
            MaxThreadsPerQueue              = $node.MaxThreadsPerQueue
            MaxWorkItems                    = $node.MaxWorkItems
            NullSessionPipes                = $node.NullSessionPipes
            NullSessionShares               = $node.NullSessionShares
            OplockBreakWait                 = $node.OplockBreakWait
            PendingClientTimeoutInSeconds   = $node.PendingClientTimeoutInSeconds
            RejectUnencryptedAccess         = $node.RejectUnencryptedAccess
            RequireSecuritySignature        = $node.RequireSecuritySignature
            ServerHidden                    = $node.ServerHidden
            Smb2CreditsMax                  = $node.Smb2CreditsMax
            Smb2CreditsMin                  = $node.Smb2CreditsMin
            SmbServerNameHardeningLevel     = $node.SmbServerNameHardeningLevel
            TreatHostAsStableStorage        = $node.TreatHostAsStableStorage
            ValidateAliasNotCircular        = $node.ValidateAliasNotCircular
            ValidateShareScope              = $node.ValidateShareScope
            ValidateShareScopeNotAliased    = $node.ValidateShareScopeNotAliased
            ValidateTargetName              = $node.ValidateTargetName
        }
    }
}
