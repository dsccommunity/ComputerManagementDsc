<#
    .SYNOPSIS
        Determines if the repository is in the desired state.
    .PARAMETER Ensure
        If the repository should be present or absent on the server
        being configured. Default values is 'Present'.
    .PARAMETER Name
        Specifies the name of the repository to manage.
    .PARAMETER SourceLocation
        Specifies the URI for discovering and installing modules from
        this repository. A URI can be a NuGet server feed, HTTP, HTTPS,
        FTP or file location.
    .PARAMETER ScriptSourceLocation
        Specifies the URI for the script source location.
    .PARAMETER PublishLocation
        Specifies the URI of the publish location. For example, for
        NuGet-based repositories, the publish location is similar
        to http://someNuGetUrl.com/api/v2/Packages.
    .PARAMETER ScriptPublishLocation
        Specifies the URI for the script publish location.
    .PARAMETER InstallationPolicy
        Specifies the installation policy. Valid values are  'Trusted'
        or 'Untrusted'. The default value is 'Untrusted'.
    .PARAMETER PackageManagementProvider
        Specifies a OneGet package provider. Default value is 'NuGet'.
#>
[DscResource()]
class PSResourceRepository : ResourceBase
{

    [DscProperty()]
    [Ensure]$Ensure = [Ensure]::Present


    [DscProperty(Key)]
    [String] $Name

    [DscProperty()]
    [String] $URL

    [DscProperty()]
    [String] $Priority

    [DscProperty()]
    [InstallationPolicy] $InstallationPolicy

    [DscProperty(NotConfigurable)]
    [Boolean] $Trusted;

    [DscProperty(NotConfigurable)]
    [Boolean] $Registered;

    [PSResourceRepository] Get()
    {
        $returnValue = [PSResourceRepository]@{
            Ensure                    = [Ensure]::Absent
            Name                      = $this.Name
            URL                       = $null
            Priority                  = $null
            #InstallationPolicy        = $null
            #Trusted                   = $false
            Registered                = $false
        }

        Write-Verbose -Message ($localizedData.GetTargetResourceMessage -f $this.Name)
        $repository = Get-PSRepository -Name $this.name -ErrorAction SilentlyContinue

        if ($repository)
        {
            $returnValue.Ensure                    = [Ensure]::Present
            $returnValue.SourceLocation            = $repository.SourceLocation
            $returnValue.ScriptSourceLocation      = $repository.ScriptSourceLocation
            $returnValue.PublishLocation           = $repository.PublishLocation
            $returnValue.ScriptPublishLocation     = $repository.ScriptPublishLocation
            $returnValue.InstallationPolicy        = [InstallationPolicy]::$($repository.InstallationPolicy)
            $returnValue.PackageManagementProvider = $repository.PackageManagementProvider
            $returnValue.Trusted                   = $repository.Trusted
            $returnValue.Registered                = $repository.Registered
        }
        else
        {
            Write-Verbose -Message ($localizedData.RepositoryNotFound -f $this.Name)
        }
        return returnValue
    }

    [void] Set()
    {

    }

    [Boolean] Test()
    {
        $result = $false
        return $result
    }

    hidden [void] Modify([System.Collections.Hashtable] $properties)
    {

    }

    hidden [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $properties)
    {

    }
}
