# Description

This resource is used configure System Protection. System
Protection is only applicable to workstation operating
systems. Server operating systems are not supported.

## DiskUsage and Force Parameters

The amount of disk that can be allocated for System Protection
is configurable on a per-drive basis which is why this
resource doesn't accept an array of drives like xWindowsRestore
did.

If you reduce the disk usage for a protected drive, the resource
will try to resize it but VSS could throw an error because you
have to delete checkpoints first. When you set Force to $true,
SystemProtection will attempt the resize and if VSS throws an
error, SystemProtection will delete **all** checkpoints on the
the protected drive and try the resize operation again.

Make sure you fully understand and accept the risks associated
with using the Force parameter.
