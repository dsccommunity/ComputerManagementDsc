<#PSScriptInfo
.VERSION 1.0.0
.GUID f177571b-c54b-46f2-9d55-903b794ecccd
.AUTHOR Microsoft Corporation
.COMPANYNAME Microsoft Corporation
.COPYRIGHT (c) Microsoft Corporation. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/PowerShell/ComputerManagementDsc/blob/master/LICENSE
.PROJECTURI https://github.com/PowerShell/ComputerManagementDsc
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
        This configuration will enable Remote Desktop for Administration and set
        the User Authentication to secure, i.e. to require Network Level Authentication
#>

Configuration RemoteDesktopAdmin_SetSecureRemoteDesktopAdmin_Config
{
    Import-DscResource -Module ComputerManagementDsc

    Node ('localhost')
    {
        RemoteDesktopAdmin RemoteDesktopSettings
        {
            IsSingleInstance   = 'yes'
            Ensure             = 'Present'
            UserAuthentication = 'Secure'
        }
    }
}
