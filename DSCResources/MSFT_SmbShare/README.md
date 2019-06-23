# Description

The resource is used to manage SMB shares, and access permissions to
SMB shares.

## Requirements

### Cluster Shares

The property `ContinuouslyAvailable` can only be set to `$true` when
the SMB share is a cluster share in a failover cluster. Also in the blog
[SMB Transparent Failover – making file shares continuously available](https://blogs.technet.microsoft.com/filecab/2016/03/25/smb-transparent-failover-making-file-shares-continuously-available-2)
by [Claus Joergensen](https://github.com/clausjor) it is mentioned that
SMB Transparent Failover does not support cluster disks with 8.3 name
generation enabled.

### Access permissions

It is not allowed to provide empty collections in the configuration for
the access permissions parameters. The configuration below will cause an
exception to be thrown.

```powershell
SmbShare 'Integration_Test'
{
    Name         = 'TestShare'
    Path         = 'C:\Temp'
    FullAccess   = @()
    ChangeAccess = @()
    ReadAccess   = @()
    NoAccess     = @()
}
```

The access permission parameters must either be all removed to manage
the access permission manually, or add at least one member to one of
the access permission parameters. If all the access permission parameters
are removed, then by design, the cmdlet New-SmbShare will add
the *Everyone* group with read access permission to the SMB share.
To prevent that, add a member to either access permission parameters.
