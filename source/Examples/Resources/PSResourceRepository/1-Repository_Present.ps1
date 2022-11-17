#Requires -module ComputerManagementDsc

<#
    .DESCRIPTION
        This configuration adds the PSGallery PSRepository to a machine
#>

configuration PSResourceRepository_Create_Config
{
    Import-DscResource -ModuleName 'ComputerManagementDsc'

    node localhost
    {
        PSResourceRepository 'Repository_Present'
        {
            Name                      = 'PSGallery'
            Ensure                    = 'Present'
            SourceLocation            = 'https://www.powershellgallery.com/api/v2'
            ScriptSourceLocation      = 'https://www.powershellgallery.com/api/v2/package/'
            PublishLocation           = 'https://www.powershellgallery.com/api/v2/items/psscript'
            ScriptPublishLocation     = 'https://www.powershellgallery.com/api/v2/package/'
            InstallationPolicy        = 'Trusted'
            PackageManagementProvider = 'NuGet'
        }
    }
}
