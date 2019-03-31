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

                ShareName       = 'DscTestShare'
                SharePath       = 'C:\DscTestShare'
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
        File DirectoryCopy
        {
            Ensure = 'Present'
            Type = 'Directory'
            DestinationPath = $Node.SharePath
        }
    }
}

<#
    .SYNOPSIS
        Create the share with default values.
#>
Configuration MSFT_SmbShare_CreateShare_Config
{
    Import-DscResource -ModuleName 'ComputerManagementDsc'

    node $AllNodes.NodeName
    {
        SmbShare 'Integration_Test'
        {
            Name = $Node.ShareName
            Path = $Node.SharePath
        }
    }
}

<#
    .SYNOPSIS
        Remove the share.
#>
Configuration MSFT_SmbShare_RemoveShare_Config
{
    Import-DscResource -ModuleName 'ComputerManagementDsc'

    node $AllNodes.NodeName
    {
        SmbShare 'Integration_Test'
        {
            Ensure = 'Absent'
            Name   = $Node.ShareName
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
        File DirectoryCopy
        {
            Ensure = 'Absent'
            Type = 'Directory'
            DestinationPath = $Node.SharePath
        }
    }
}
