# ComputerManagementDsc

[![Build Status](https://dev.azure.com/dsccommunity/ComputerManagementDsc/_apis/build/status/dsccommunity.ComputerManagementDsc?branchName=master)](https://dev.azure.com/dsccommunity/ComputerManagementDsc/_build/latest?definitionId=16&branchName=master)
![Code Coverage](https://img.shields.io/azure-devops/coverage/dsccommunity/ComputerManagementDsc/16/master)
[![Azure DevOps tests](https://img.shields.io/azure-devops/tests/dsccommunity/ComputerManagementDsc/16/master)](https://dsccommunity.visualstudio.com/ComputerManagementDsc/_test/analytics?definitionId=16&contextType=build)
[![PowerShell Gallery (with prereleases)](https://img.shields.io/powershellgallery/vpre/ComputerManagementDsc?label=ComputerManagementDsc%20Preview)](https://www.powershellgallery.com/packages/ComputerManagementDsc/)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/ComputerManagementDsc?label=ComputerManagementDsc)](https://www.powershellgallery.com/packages/ComputerManagementDsc/)

## Code of Conduct

This project has adopted [this code of conduct](CODE_OF_CONDUCT.md).

## Releases

For each merge to the branch `master` a preview release will be
deployed to [PowerShell Gallery](https://www.powershellgallery.com/).
Periodically a release version tag will be pushed which will deploy a
full release to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

Please check out common DSC Community [contributing guidelines](https://dsccommunity.org/guidelines/contributing).

## Change log

A full list of changes in each version can be found in the [change log](CHANGELOG.md).

## Resources

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
- **SystemLocale**: this resource is used to set the system locale on a
  Windows machine
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
check out the [ComputerManagementDsc wiki](https://github.com/dsccommunity/ComputerManagementDsc/wiki).
