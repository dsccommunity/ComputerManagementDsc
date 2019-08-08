<#PSScriptInfo
.VERSION 1.0.0
.GUID 27cc4f2a-e366-49cb-93d6-2f094567ebf3
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
        This example creates an SMB share named 'Temp' for the path 'C:\Temp',
        using specific values for each supported property.

    .NOTES
        Any other property not yet súpported will use the default values of the
        cmdlet `New-SmbShare`.To know the default values, see the documentation
        for the cmdlet `New-SmbShare`.
#>
Configuration SmbShare_CreateShareAllProperties_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        SmbShare 'TempShare'
        {
            Name = 'Temp'
            Path = 'C:\Temp'
            Description = 'Some description'
            ConcurrentUserLimit = 20
            EncryptData = $false
            FolderEnumerationMode = 'AccessBased'
            CachingMode = 'Manual'
            ContinuouslyAvailable = $false
            FullAccess = @()
            ChangeAccess = @('AdminUser1')
            ReadAccess = @('Everyone')
            NoAccess = @('DeniedUser1')
        }
    }
}
