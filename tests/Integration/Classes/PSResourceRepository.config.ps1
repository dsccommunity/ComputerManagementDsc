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
        }
        PSResourceRepository_Modify_Config = @{
            Name                  = 'PSGallery'
            Ensure                = 'Present'
            SourceLocation        = 'https://www.powershellgallery.com/api/v2'
            PublishLocation       = 'https://www.powershellgallery.com/api/v2/package/'
            ScriptSourceLocation  = 'https://www.powershellgallery.com/api/v2/items/psscript'
            ScriptPublishLocation = 'https://www.powershellgallery.com/api/v2/package/'
            InstallationPolicy    = 'Trusted'
        }
        PSResourceRepository_Remove_Config = @{
            Name           = 'PSGallery'
            Ensure         = 'Absent'
            SourceLocation = 'https://www.powershellgallery.com/api/v2'
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
        PSResourceRepository "Register Repository $($ConfigurationData.NonNodeData.PSResourceRepository_Create_Config.Name)"
        {
            Name           = $ConfigurationData.NonNodeData.PSResourceRepository_Create_Config.Name
            Ensure         = $ConfigurationData.NonNodeData.PSResourceRepository_Create_Config.Ensure
            SourceLocation = $ConfigurationData.NonNodeData.PSResourceRepository_Create_Config.SourceLocation
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
        PSResourceRepository "Modify PSRepository $($ConfigurationData.NonNodeData.PSResourceRepository_Modify_Config.Name)"
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
        PSResourceRepository "Remove PSRepository $($ConfigurationData.NonNodeData.PSResourceRepository_Remove_Config.Name)"
        {
            Name           = $ConfigurationData.NonNodeData.PSResourceRepository_Remove_Config.Name
            Ensure         = $ConfigurationData.NonNodeData.PSResourceRepository_Remove_Config.Ensure
            SourceLocation = $ConfigurationData.NonNodeData.PSResourceRepository_Remove_Config.SourceLocation
        }
    }
}

