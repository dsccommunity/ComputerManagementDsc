#region HEADER
# Integration Test Config Template Version: 1.2.0
#endregion

$configFile = [System.IO.Path]::ChangeExtension($MyInvocation.MyCommand.Path, 'json')
if (Test-Path -Path $configFile)
{
    <#
        Allows reading the configuration data from a JSON file
        for real testing scenarios outside of the CI.
    #>
    $ConfigurationData = Get-Content -Path $configFile | ConvertFrom-Json
}
else
{
    $ConfigurationData = @{
        AllNodes = @(
            @{
                NodeName        = 'localhost'
                CertificateFile = $env:DscPublicCertificatePath

                ShareName1      = 'DscTestShare1'
                SharePath1      = 'C:\DscTestShare1'

                ShareName2      = 'DscTestShare2'
                SharePath2      = 'C:\DscTestShare2'

                UserName1       = ('{0}\SmbUser1' -f $env:COMPUTERNAME)
                UserName2       = ('{0}\SmbUser2' -f $env:COMPUTERNAME)
                UserName3       = ('{0}\SmbUser3' -f $env:COMPUTERNAME)
                UserName4       = ('{0}\SmbUser4' -f $env:COMPUTERNAME)
                Password        = 'P@ssw0rd1'
            }
        )
    }
}

<#
    .SYNOPSIS
        Creates the prerequisites for the other tests.
        This creates a folder that will be shared.
#>
Configuration MSFT_SmbShare_Prerequisites_Config
{
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    node $AllNodes.NodeName
    {
        File 'CreateFolderToShare1'
        {
            Ensure          = 'Present'
            Type            = 'Directory'
            DestinationPath = $Node.SharePath1
        }

        File 'CreateFolderToShare2'
        {
            Ensure          = 'Present'
            Type            = 'Directory'
            DestinationPath = $Node.SharePath2
        }

        User 'CreateAccountUser1'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $Node.UserName1 -Leaf
            Password = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @(
                (Split-Path -Path $Node.UserName1 -Leaf),
                (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force)
            )
        }

        User 'CreateAccountUser2'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $Node.UserName2 -Leaf
            Password = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @(
                (Split-Path -Path $Node.UserName2 -Leaf),
                (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force)
            )
        }

        User 'CreateAccountUser3'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $Node.UserName3 -Leaf
            Password = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @(
                (Split-Path -Path $Node.UserName3 -Leaf),
                (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force)
            )
        }

        User 'CreateAccountUser4'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $Node.UserName4 -Leaf
            Password = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @(
                (Split-Path -Path $Node.UserName1 -Leaf),
                (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force)
            )
        }
    }
}

<#
    .SYNOPSIS
        Create the SMB share with default values, and no permissions.
#>
Configuration MSFT_SmbShare_CreateShare1_Config
{
    Import-DscResource -ModuleName 'ComputerManagementDsc'

    node $AllNodes.NodeName
    {
        SmbShare 'Integration_Test'
        {
            Name = $Node.ShareName1
            Path = $Node.SharePath1
        }
    }
}

<#
    .SYNOPSIS
        Create the SMB share with default values, and no permissions.
#>
Configuration MSFT_SmbShare_CreateShare2_Config
{
    Import-DscResource -ModuleName 'ComputerManagementDsc'

    node $AllNodes.NodeName
    {
        SmbShare 'Integration_Test'
        {
            Name         = $Node.ShareName2
            Path         = $Node.SharePath2
            FullAccess   = @()
            ChangeAccess = @($Node.UserName1)
            ReadAccess   = @()
            NoAccess     = @()
        }
    }
}

<#
    .SYNOPSIS
        Update all properties of the SMB share.

    .NOTES
        The property ContinuouslyAvailable cannot be set to $true because that
        property requires the share to be a cluster share in a Failover Cluster.

        Log Name:      Microsoft-Windows-SMBServer/Operational
        Event ID:      1800
        Level:         Error
        Description:
        CA failure - Failed to set continuously available property on a new or
        existing file share as the file share is not a cluster share.

#>
Configuration MSFT_SmbShare_UpdateProperties_Config
{
    Import-DscResource -ModuleName 'ComputerManagementDsc'

    node $AllNodes.NodeName
    {
        SmbShare 'Integration_Test'
        {
            Name                  = $Node.ShareName1
            Path                  = $Node.SharePath1
            FolderEnumerationMode = 'AccessBased'
            CachingMode           = 'None'
            ConcurrentUserLimit   = 20
            ContinuouslyAvailable = $false
            Description           = 'A new description'
            EncryptData           = $true
            FullAccess            = @($Node.UserName1)
            ChangeAccess          = @($Node.UserName2)
            ReadAccess            = @($Node.UserName3)
            NoAccess              = @($Node.UserName4)
        }
    }
}

<#
    .SYNOPSIS
        Remove permission, and no other properties should be changed.
#>
Configuration MSFT_SmbShare_RemovePermission_Config
{
    Import-DscResource -ModuleName 'ComputerManagementDsc'

    node $AllNodes.NodeName
    {
        SmbShare 'Integration_Test'
        {
            Name         = $Node.ShareName1
            Path         = $Node.SharePath1
            FullAccess   = @()
            ChangeAccess = @()
            ReadAccess   = @('Everyone')
            NoAccess     = @()
        }
    }
}


<#
    .SYNOPSIS
        Remove the share 1.
#>
Configuration MSFT_SmbShare_RemoveShare1_Config
{
    Import-DscResource -ModuleName 'ComputerManagementDsc'

    node $AllNodes.NodeName
    {
        SmbShare 'Integration_Test'
        {
            Ensure = 'Absent'
            Name   = $Node.ShareName1
            Path   = 'NotUsed_CanBeAnyValue'
        }
    }
}

<#
    .SYNOPSIS
        Remove the share 2.
#>
Configuration MSFT_SmbShare_RemoveShare2_Config
{
    Import-DscResource -ModuleName 'ComputerManagementDsc'

    node $AllNodes.NodeName
    {
        SmbShare 'Integration_Test'
        {
            Ensure = 'Absent'
            Name   = $Node.ShareName2
            Path   = 'NotUsed_CanBeAnyValue'
        }
    }
}

<#
    .SYNOPSIS
        Clean up the prerequisites.
#>
Configuration MSFT_SmbShare_Cleanup_Config
{
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    node $AllNodes.NodeName
    {
        File 'RemoveShareFolder1'
        {
            Ensure          = 'Absent'
            Type            = 'Directory'
            DestinationPath = $Node.SharePath1
        }

        File 'RemoveShareFolder2s'
        {
            Ensure          = 'Absent'
            Type            = 'Directory'
            DestinationPath = $Node.SharePath2
        }

        User 'RemoveAccountUser1'
        {
            Ensure   = 'Absent'
            UserName = Split-Path -Path $Node.UserName1 -Leaf
        }

        User 'RemoveAccountUser2'
        {
            Ensure   = 'Absent'
            UserName = Split-Path -Path $Node.UserName2 -Leaf
        }

        User 'RemoveAccountUser3'
        {
            Ensure   = 'Absent'
            UserName = Split-Path -Path $Node.UserName3 -Leaf
        }

        User 'RemoveAccountUser4'
        {
            Ensure   = 'Absent'
            UserName = Split-Path -Path $Node.UserName4 -Leaf
        }
    }
}
