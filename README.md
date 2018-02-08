# xComputerManagement

The **xComputerManagement** module contains the following resources:

- **xComputer**: allows you to configure a computer by changing its name and
  description and modifying its Active Directory domain or workgroup membership.
- **xOfflineDomainJoin**: allows you to join computers to an Active Directory
  domain using an [Offline Domain Join](https://technet.microsoft.com/en-us/library/offline-domain-join-djoin-step-by-step(v=ws.10).aspx)
  request file.
- **xPowerPlan**: allows specifying a power plan to activate.
- **xScheduledTask**: is used to define basic run once or recurring scheduled tasks
  on the local computer. It can also be used to delete or disable built-in
  scheduled tasks.
- **xVirtualMemory**: allows configuration of properties of the paging file on
  the local computer.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/)
or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any
additional questions or comments.

## Documentation and Examples

For a full list of resources in xComputerManagement and examples on their use, check
out the [xComputerManagement wiki](https://github.com/PowerShell/xComputerManagement/wiki).

## Branches

### master

[![Build status](https://ci.appveyor.com/api/projects/status/cg28qxeco39wgo9l/branch/master?svg=true)](https://ci.appveyor.com/project/PowerShell/xComputerManagement/branch/master)
[![codecov](https://codecov.io/gh/PowerShell/xComputerManagement/branch/master/graph/badge.svg)](https://codecov.io/gh/PowerShell/xComputerManagement/branch/master)

This is the branch containing the latest release - no contributions should be made
directly to this branch.

### dev

[![Build status](https://ci.appveyor.com/api/projects/status/cg28qxeco39wgo9l/branch/dev?svg=true)](https://ci.appveyor.com/project/PowerShell/xComputerManagement/branch/dev)
[![codecov](https://codecov.io/gh/PowerShell/xComputerManagement/branch/dev/graph/badge.svg)](https://codecov.io/gh/PowerShell/xComputerManagement/branch/dev)

This is the development branch to which contributions should be proposed by contributors
as pull requests. This development branch will periodically be merged to the master
branch, and be released to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).
