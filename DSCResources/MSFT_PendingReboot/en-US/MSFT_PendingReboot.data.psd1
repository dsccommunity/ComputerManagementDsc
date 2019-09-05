@{
    RebootTriggers = @(
        @{
            Name        = 'ComponentBasedServicing'
            Description = 'Component based servicing'
        },
        @{
            Name        = 'WindowsUpdate'
            Description = 'Windows Update'
        },
        @{
            Name        = 'PendingFileRename'
            Description = 'Pending file rename'
        },
        @{
            Name        = 'PendingComputerRename'
            Description = 'Pending computer rename'
        },
        @{
            Name        = 'CcmClientSDK'
            Description = 'ConfigMgr'
        }
    )
}
