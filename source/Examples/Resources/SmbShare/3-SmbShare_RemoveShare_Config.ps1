<#PSScriptInfo
.VERSION 1.0.0
.GUID f11d7558-0748-4a72-b743-34424cbf4407
.AUTHOR DSC Community
.COMPANYNAME DSC Community
.COPYRIGHT Copyright the DSC Community contributors. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/dsccommunity/ComputerManagementDsc/c/blob/master/LICENSE
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
        This example removes a SMB share named 'Temp'.

    .NOTES
        Path must be specified because it is a mandatory parameter,
        but it can be set to any value.
#>
Configuration SmbShare_RemoveShare_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        SmbShare 'TempShare'
        {
            Ensure = 'Absent'
            Name = 'Temp'
            Path = 'NotUsed'
        }
    }
}
