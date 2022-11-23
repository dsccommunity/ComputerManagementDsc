#Requires -module ComputerManagementDsc

<#
    .DESCRIPTION
        This configuration adds the PSRepository named MyPSRepository to a machine
#>

configuration Register_PSRepository_Present
{
    Import-DscResource -ModuleName 'ComputerManagementDsc'

    node localhost
    {
        PSResourceRepository 'Register MyPSRepository PSRepository'
        {
            Name                      = 'MyPSRepository'
            SourceLocation            = 'https://www.mypsrepository.com/api/v2'
            ScriptSourceLocation      = 'https://www.mypsrepository.com/api/v2/package/'
            PublishLocation           = 'https://www.mypsrepository.com/api/v2/items/psscript'
            ScriptPublishLocation     = 'https://www.mypsrepository.com/api/v2/package/'
            InstallationPolicy        = 'Trusted'
            PackageManagementProvider = 'NuGet'
        }
    }
}
