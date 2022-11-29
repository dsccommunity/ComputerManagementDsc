$ConfigurationData = @{
    AllNodes    = , @{
        NodeName        = 'localhost'
        CertificateFile = $Null
    }
    NonNodeData = @{
        PSResourceRepository_Remove_PSGallery = @{
            Name   = 'PSGallery'
            Ensure = 'Absent'
        }
        PSResourceRepository_Create_Default_Config = @{
            Name    = 'PSGallery'
            Ensure  = 'Present'
            Default = $true
        }
        #!Delete this
        PSResourceRepository_Create_Default_Config_ShouldThrow = @{
            Name           = 'PSGallery'
            Ensure         = 'Present'
            SourceLocation = 'https://www.powershellgallery.com/api/v2'
            Default        = $true
        }
        #!Delete this
        PSResourceRepository_Create_Config = @{
            Name           = 'PSTestGallery'
            Ensure         = 'Present'
            SourceLocation = 'https://www.nuget.org/api/v2'
        }
        PSResourceRepository_Modify_Config = @{
            Name                      = 'PSTestGallery'
            Ensure                    = 'Present'
            SourceLocation            = 'https://www.nuget.org/api/v2'
            PublishLocation           = 'https://www.nuget.org/api/v2/package/'
            ScriptSourceLocation      = 'https://www.nuget.org/api/v2/items/psscript/'
            ScriptPublishLocation     = 'https://www.nuget.org/api/v2/package/'
            InstallationPolicy        = 'Trusted'
            PackageManagementProvider = 'NuGet'
        }
        PSResourceRepository_Remove_Config = @{
            Name   = 'PSTestGallery'
            Ensure = 'Absent'
        }
    }
}

<#
    .SYNOPSIS
        Unregister PSRepository PSGallery
#>
configuration PSResourceRepository_Remove_PSGallery
{
    Import-DscResource -ModuleName 'ComputerManagementDsc'

    node $AllNodes.NodeName
    {
        PSResourceRepository 'Integration_Test'
        {
            Name           = $ConfigurationData.NonNodeData.PSResourceRepository_Remove_PSGallery.Name
            Ensure         = $ConfigurationData.NonNodeData.PSResourceRepository_Remove_PSGallery.Ensure
        }
    }
}

<#
    .SYNOPSIS
        Register Default PSRepository PSGallery
#>
configuration PSResourceRepository_Create_Default_Config
{
    Import-DscResource -ModuleName 'ComputerManagementDsc'

    node $AllNodes.NodeName
    {
        PSResourceRepository 'Integration_Test'
        {
            Name    = $ConfigurationData.NonNodeData.PSResourceRepository_Create_Default_Config.Name
            Ensure  = $ConfigurationData.NonNodeData.PSResourceRepository_Create_Default_Config.Ensure
            Default = $ConfigurationData.NonNodeData.PSResourceRepository_Create_Default_Config.Default
        }
    }
}

#!Delete this
configuration PSResourceRepository_Create_Default_Config_ShouldThrow
{
    Import-DscResource -ModuleName 'ComputerManagementDsc'

    node $AllNodes.NodeName
    {
        PSResourceRepository 'Integration_Test'
        {
            Name    = $ConfigurationData.NonNodeData.PSResourceRepository_Create_Default_Config_ShouldThrow.Name
            Ensure  = $ConfigurationData.NonNodeData.PSResourceRepository_Create_Default_Config_ShouldThrow.Ensure
            Default = $ConfigurationData.NonNodeData.PSResourceRepository_Create_Default_Config_ShouldThrow.Default
            SourceLocation = $ConfigurationData.NonNodeData.PSResourceRepository_Create_Default_Config_ShouldThrow.SourceLocation
        }
    }
}
#!Delete this

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
        PSResourceRepository 'Integration_Test'
        {
            Name                      = $ConfigurationData.NonNodeData.PSResourceRepository_Modify_Config.Name
            Ensure                    = $ConfigurationData.NonNodeData.PSResourceRepository_Modify_Config.Ensure
            SourceLocation            = $ConfigurationData.NonNodeData.PSResourceRepository_Modify_Config.SourceLocation
            ScriptSourceLocation      = $ConfigurationData.NonNodeData.PSResourceRepository_Modify_Config.ScriptSourceLocation
            PublishLocation           = $ConfigurationData.NonNodeData.PSResourceRepository_Modify_Config.PublishLocation
            ScriptPublishLocation     = $ConfigurationData.NonNodeData.PSResourceRepository_Modify_Config.ScriptPublishLocation
            InstallationPolicy        = $ConfigurationData.NonNodeData.PSResourceRepository_Modify_Config.InstallationPolicy
            PackageManagementProvider = $ConfigurationData.NonNodeData.PSResourceRepository_Modify_Config.PackageManagementProvider
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

