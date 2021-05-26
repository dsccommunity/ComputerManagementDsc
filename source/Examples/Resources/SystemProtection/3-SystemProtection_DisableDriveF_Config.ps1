<#PSScriptInfo
.VERSION 1.0.0
.GUID fbe5e8dd-1327-4d1a-aa08-06b2063b960e
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
        Disables system protection for the F drive.
#>
Configuration SystemProtection_DisableDriveF_Config
{
    Import-DSCResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        SystemProtection DriveF
        {
            Ensure      = 'Absent'
            DriveLetter = 'F'
        }
    }
}
