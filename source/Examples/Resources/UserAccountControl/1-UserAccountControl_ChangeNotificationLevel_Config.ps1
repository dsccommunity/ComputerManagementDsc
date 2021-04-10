<#PSScriptInfo
.VERSION 1.0.0
.GUID f522828d-175f-4a80-9c98-b4faef93f4e9
.AUTHOR DSC Community
.COMPANYNAME DSC Community
.COPYRIGHT DSC Community contributors. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/dsccommunity/ComputerManagementDsc/blob/main/LICENSE
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
        This configuration will change the notification level for the User
        Account Control (UAC).
#>
Configuration UserAccountControl_ChangeNotificationLevel_Config
{
    Import-DscResource -Module ComputerManagementDsc

    Node localhost
    {
        UserAccountControl 'ChangeNotificationLevel'
        {
            IsSingleInstance  = 'Yes'
            NotificationLevel = 'AlwaysNotifyAndAskForCredentials'
        }
    }
}
