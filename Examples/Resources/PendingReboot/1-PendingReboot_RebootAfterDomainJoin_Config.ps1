<#PSScriptInfo
.VERSION 1.0.0
.GUID ca17d716-4ded-4822-8f02-6363e9fa2c71
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
        This example joins a computer to a domain and allows the LCM
        node to reboot after the join. The LCM must have been configured
        with the RebootNodeIfNeeded property set to $true.
#>
Configuration PendingReboot_RebootAfterDomainJoin_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [System.Management.Automation.PSCredential]
        $Credential
    )

    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        Computer JoinDomain
        {
            Name       = 'Server01'
            DomainName = 'Contoso'
            Credential = $Credential # Credential to join to domain
        }

        PendingReboot RebootAfterDomainJoin
        {
            Name = 'DomainJoin'
        }
    }
}
