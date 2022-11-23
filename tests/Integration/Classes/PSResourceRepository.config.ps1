$ConfigurationData = @{
    AllNodes    = , @{
        NodeName        = 'localhost'
        CertificateFile = $Null
    }
    NonNodeData = @{
        PSResourceRepository_Create_Config = @{
            Name           = 'PSGallery'
            Ensure         = 'Present'
            SourceLocation = 'https://www.powershellgallery.com/api/v2'
            Default        = $true
        }
        PSResourceRepository_Modify_Config = @{
            Name                  = 'MyPSRepository'
            Ensure                = 'Present'
            SourceLocation        = 'https://www.google.com/'
            PublishLocation       = 'https://www.google.com/'
            ScriptSourceLocation  = 'https://www.google.com/'
            ScriptPublishLocation = 'https://www.google.com/'
            InstallationPolicy    = 'Trusted'
        }
        PSResourceRepository_Remove_Config = @{
            Name   = 'PSGallery'
            Ensure = 'Absent'
        }

    }
}

<#
    .SYNOPSIS
        Register a PSRepository
#>
configuration PSResourceRepository_Create_Config
{
    Import-DscResource -ModuleName 'ComputerManagementDsc'

    node $AllNodes.NodeName
    {
        PSResourceRepository 'Integration_Test'
        {
            Name    = $ConfigurationData.NonNodeData.PSResourceRepository_Create_Config.Name
            Ensure  = $ConfigurationData.NonNodeData.PSResourceRepository_Create_Config.Ensure
            Default = $ConfigurationData.NonNodeData.PSResourceRepository_Create_Config.Default
        }
    }
}

<#
    .SYNOPSIS
        Modifies an existing PSRepository
#>
configuration PSResourceRepository_Modify_Config
{
    Import-DscResource -ModuleName 'ComputerManagementDsc'

    node $AllNodes.NodeName
    {
        PSResourceRepository 'Integration_Test'
        {
            Name                  = $ConfigurationData.NonNodeData.PSResourceRepository_Modify_Config.Name
            Ensure                = $ConfigurationData.NonNodeData.PSResourceRepository_Modify_Config.Ensure
            SourceLocation        = $ConfigurationData.NonNodeData.PSResourceRepository_Modify_Config.SourceLocation
            ScriptSourceLocation  = $ConfigurationData.NonNodeData.PSResourceRepository_Modify_Config.ScriptSourceLocation
            PublishLocation       = $ConfigurationData.NonNodeData.PSResourceRepository_Modify_Config.PublishLocation
            ScriptPublishLocation = $ConfigurationData.NonNodeData.PSResourceRepository_Modify_Config.ScriptPublishLocation
            InstallationPolicy    = $ConfigurationData.NonNodeData.PSResourceRepository_Modify_Config.InstallationPolicy
        }
    }
}

<#
    .SYNOPSIS
        Unregister an existing PSRepository
#>
configuration PSResourceRepository_Remove_Config
{
    Import-DscResource -ModuleName 'ComputerManagementDsc'

    node $AllNodes.NodeName
    {
        PSResourceRepository 'Integration_Test'
        {
            Name           = $ConfigurationData.NonNodeData.PSResourceRepository_Remove_Config.Name
            Ensure         = $ConfigurationData.NonNodeData.PSResourceRepository_Remove_Config.Ensure
        }
    }
}

