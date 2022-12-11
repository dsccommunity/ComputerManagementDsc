#Requires -module ComputerManagementDsc

<#
    .DESCRIPTION
        This configuration removes the PSGallery PSRepository from a machine
#>

configuration Repository_Absent
{
    Import-DscResource -ModuleName 'ComputerManagementDsc'

    node localhost
    {
        PSResourceRepository 'Remove PSGallery PSRepository'
        {
            Name           = 'PSGallery'
            Ensure         = 'Absent'
        }
    }
}
