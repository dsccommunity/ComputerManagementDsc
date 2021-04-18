<#PSScriptInfo
.VERSION 1.0.0
.GUID 7f114f0d-9a93-427d-a81f-2fd991fd4c65
.AUTHOR DSC Community
.COMPANYNAME DSC Community
.COPYRIGHT Copyright the DSC Community contributors. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/dsccommunity/ComputerManagementDsc/blob/master/LICENSE
.PROJECTURI https://github.com/dsccommunity/ComputerManagementDsc
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES First version.
.PRIVATEDATA 2016-Datacenter,2016-Datacenter-Server-Core
#>

#Requires -module ComputerManagementDsc

<#
    .DESCRIPTION
        Deletes all restore points matching the description
        and the APPLICATION_INSTALL restore point type.
#>
Configuration SystemRestorePoint_DeleteApplicationInstalls_Config
{
    Import-DSCResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        SystemRestorePoint DeleteTestApplicationinstalls
        {
            Ensure           = 'Absent'
            Description      = 'Test Restore Point'
            RestorePointType = 'APPLICATION_INSTALL'
        }
    }
}
