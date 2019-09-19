# Description

PendingReboot examines three specific registry locations where a Windows Server
might indicate that a reboot is pending and allows DSC to predictably handle
the condition.

DSC determines how to handle pending reboot conditions using the Local Configuration
Manager (LCM) setting `RebootNodeIfNeeded`. When DSC resources require reboot, within
a Set statement in a DSC Resource the global variable `DSCMachineStatus` is set to
value '1'. When this condition occurs and RebootNodeIfNeeded is set to 'True',
DSC reboots the machine after a successful Set. Otherwise, the reboot is postponed.

Note: The expectation is that this resource will be used in conjunction with
knowledge of DSC Local Configuration Manager, which has the ability to manage
whether reboots happen automatically using the RebootIfNeeded parameter. For
more information on configuring the LCM, please reference [this TechNet article](https://technet.microsoft.com/en-us/library/dn249922.aspx).
