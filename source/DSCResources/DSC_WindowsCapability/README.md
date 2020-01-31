# Description

This resource enables installation or removal of a Windows Capability.

The LogLevel and LogPath parameters can be passed to the resource but
are not used to determine if the resource is in the desired state.

This is because the LogLevel and LogPath properties returned by
`Get-WindowsCapability` do not reflect the values that may have been
set with `Add-WindowsCapability` or `Remove-WindowsCapability`.
