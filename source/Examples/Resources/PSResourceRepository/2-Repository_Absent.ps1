#Requires -module ComputerManagementDsc

<#
    .DESCRIPTION
        This configuration removes the PSGallery PSRepository from a machine
#>

configuration PSResourceRepository_Create_Config
{
    Import-DscResource -ModuleName 'ComputerManagementDsc'

    node localhost
    {
        PSResourceRepository 'Remove PSGallery PSRepository'
        {
            Name                  = 'PSGallery'
            Ensure                = 'Absent'
            SourceLocation        = 'https://www.powershellgallery.com/api/v2'
        }
    }
}
