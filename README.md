# ComputerManagementDsc

The **ComputerManagementDsc** module contains the following resources:

- **Computer**: allows you to configure a computer by changing its name and
  description and modifying its Active Directory domain or workgroup membership.
- **OfflineDomainJoin**: allows you to join computers to an Active Directory
  domain using an [Offline Domain Join](https://technet.microsoft.com/en-us/library/offline-domain-join-djoin-step-by-step(v=ws.10).aspx)
  request file.
- **PendingReboot**: examines specific registry locations where a Windows Server
  might indicate that a reboot is pending and allows DSC to predictably handle
  the condition.
- **PowerPlan**: allows specifying a power plan to activate.
- **PowerShellExecutionPolicy**: Specifies the desired PowerShell execution policy.
- **RemoteDesktopAdmin**: This resource will manage the remote desktop administration
  settings on a computer.
- **ScheduledTask**: is used to define basic run once or recurring scheduled tasks
  on the local computer. It can also be used to delete or disable built-in
  scheduled tasks.

  _The **ScheduledTask** resource requires the `ScheduledTasks` PowerShell module
  which is only available on Windows Server 2012/Windows 8 and above. DSC configurations
  containing this resource may be compiled on Windows Server 2008 R2/Windows 7 but
  can not be applied._
- **SmbServerConfiguration**: this resource is used to configure the SMB Server
settings on the local machine.
- **SmbShare**: this resource is used to manage SMB shares on a machine.
- **TimeZone**: this resource is used for setting the time zone on a machine.
- **VirtualMemory**: allows configuration of properties of the paging file on
  the local computer.
- **WindowsEventLog**: This resource allows configuration of a specified
  Windows Event Log.
- **WindowsCapability**: Provides a mechanism to enable or disable
  Windows Capabilities on a target node.

This project has adopted [this code of conduct](CODE_OF_CONDUCT.md).

## Documentation and Examples

For a full list of resources in ComputerManagementDsc and examples on their use,
check out the [ComputerManagementDsc wiki](https://github.com/PowerShell/ComputerManagementDsc/wiki).

## Branches

### master

[![Build status](https://ci.appveyor.com/api/projects/status/cg28qxeco39wgo9l/branch/master?svg=true)](https://ci.appveyor.com/project/PowerShell/ComputerManagementDsc/branch/master)
[![codecov](https://codecov.io/gh/PowerShell/ComputerManagementDsc/branch/master/graph/badge.svg)](https://codecov.io/gh/PowerShell/ComputerManagementDsc/branch/master)

This is the branch containing the latest release - no contributions should be made
directly to this branch.

### dev

[![Build status](https://ci.appveyor.com/api/projects/status/cg28qxeco39wgo9l/branch/dev?svg=true)](https://ci.appveyor.com/project/PowerShell/ComputerManagementDsc/branch/dev)
[![codecov](https://codecov.io/gh/PowerShell/ComputerManagementDsc/branch/dev/graph/badge.svg)](https://codecov.io/gh/PowerShell/ComputerManagementDsc/branch/dev)

This is the development branch to which contributions should be proposed by contributors
as pull requests. This development branch will periodically be merged to the master
branch, and be released to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).

## Change log

A full list of changes in each version can be found in the [change log](CHANGELOG.md).
