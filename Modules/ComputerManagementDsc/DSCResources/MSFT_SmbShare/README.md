# Description

The resource is used to manage SMB shares, and access permissions to
SMB shares.

## Requirements

It is not allowed to provide empty collections in the configuration for
the access permissions parameters. The below configuration will throw an
error.

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
are removed, then by design of the cmdlet `New-SmbShare` it will add
the *Everyone* group with read access permission to the SMB share.
To prevent that, add a member to either access permission parameters.
