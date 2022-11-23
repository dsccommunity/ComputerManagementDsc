#Requires -module ComputerManagementDsc

<#
    .DESCRIPTION
        This configuration adds the PSGallery PSRepository to a machine
#>

configuration Register_PSGallery_Present
{
    Import-DscResource -ModuleName 'ComputerManagementDsc'

    node localhost
    {
        PSResourceRepository 'Register PSGallery PSRepository'
        {
            Name    = 'PSGallery'
            Ensure  = 'Present'
            Default = $true
        }
    }
}
