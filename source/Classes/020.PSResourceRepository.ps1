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
    [Ensure] $Ensure = [Ensure]::Present

    [DscProperty(Key)]
    [System.String] $Name

    [DscProperty(Mandatory)]
    [System.String] $SourceLocation

    [DscProperty()]
    [pscredential] $Credential

    [DscProperty()]
    [System.String] $ScriptSourceLocation

    [DscProperty()]
    [System.String] $PublishLocation

    [DscProperty()]
    [System.String] $ScriptPublishLocation

    [DscProperty()]
    [System.String] $Proxy

    [DscProperty()]
    [pscredential] $ProxyCredential

    [DscProperty()]
    [InstallationPolicy] $InstallationPolicy = [InstallationPolicy]::Untrusted

    [DscProperty()]
    [System.String] $PackageManagementProvider = 'NuGet'

    [DscProperty(NotConfigurable)]
    [System.Boolean] $Trusted;

    [DscProperty(NotConfigurable)]
    [System.Boolean] $Registered;

    [PSResourceRepository] Get()
    {
        $returnValue = [PSResourceRepository]@{
            Ensure                    = [Ensure]::Absent
            Name                      = $this.Name
            SourceLocation            = $this.SourceLocation
        }

        Write-Verbose -Message ($this.localizedData.GetTargetResourceMessage -f $this.Name)
        $repository = Get-PSRepository -Name $this.name -ErrorAction SilentlyContinue

        if ($repository)
        {
            $returnValue.Ensure                    = [Ensure]::Present
            $returnValue.SourceLocation            = $repository.SourceLocation
            $returnValue.ScriptSourceLocation      = $repository.ScriptSourceLocation
            $returnValue.PublishLocation           = $repository.PublishLocation
            $returnValue.ScriptPublishLocation     = $repository.ScriptPublishLocation
            $returnValue.Proxy                     = $repository.Proxy
            $returnValue.ProxyCredential           = $repository.ProxyCredental
            $returnValue.InstallationPolicy        = [InstallationPolicy]::$($repository.InstallationPolicy)
            $returnValue.PackageManagementProvider = $repository.PackageManagementProvider
            $returnValue.Trusted                   = $repository.Trusted
            $returnValue.Registered                = $repository.Registered
        }
        else
        {
            Write-Verbose -Message ($this.localizedData.RepositoryNotFound -f $this.Name)
        }
        return returnValue
    }

    [void] Set()
    {
        $repository_state = $this.Get()

        Write-Verbose -Message ($this.localizedData.RepositoryState -f $this.name, $this.Ensure)

        if ($this.Ensure -eq [Ensure]::Present)
        {
            $params = @{
                name           = $this.name
                SourceLocation = $this.SourceLocation
            }

            if ($repository_state.Ensure -ne [Ensure]::Present)
            {
                #* repo does not exist, need to add
                if (-not [System.String]::IsNullOrEmpty($this.ScriptSourceLocation))
                {
                    $params.ScriptSourceLocation = $this.ScriptSourceLocation
                }

                if (-not [System.String]::IsNullOrEmpty($this.PublishLocation))
                {
                    $params.PublishLocation = $this.PublishLocation
                }

                if (-not [System.String]::IsNullOrEmpty($this.ScriptPublishLocation))
                {
                    $params.ScriptPublishLocation = $this.ScriptPublishLocation
                }

                $this.CheckProxyConfiguration()

                if (-not [System.String]::IsNullOrEmpty($this.ProxyCredential))
                {
                    $params.ProxyCredential = $this.ProxyCredential
                }

                if (-not [System.String]::IsNullOrEmpty($this.Proxy))
                {
                    $params.Proxy = $this.Proxy
                }

                $params.InstallationPolicy        = $this.InstallationPolicy
                $params.PackageManagementProvider = $this.PackageManagementProvider

                Register-PsRepository @params
            } else
            {
                #* repo does exist, need to enforce each property

            }

        }
        else
        {
            if ($repository_state.Ensure -eq [Ensure]::Present)
            {
                Write-Verbose -Message ($this.localizedData.RemoveExistingRepository -f $this.Name)
                Unregister-PSRepository -Name $this.Name
            }
        }
    }

    [Boolean] Test()
    {
        return ([ResourceBase] $this).Test()
    }

    hidden [void] RemoveExistingRepository()
    {
        Write-Verbose -Message ($this.localizedData.RemoveRepository -f $this.Name)
        Remove-PSRepository -Name $this.name -ErrorAction
    }

    #* Throws if proxy credential was passed without Proxy uri
    hidden [void] CheckProxyConfiguration()
    {
        if (-not [System.String]::IsNullOrEmpty($this.ProxyCredential))
        {
            if ( [System.String]::IsNullOrEmpty($this.Proxy))
            {
                throw $this.localizedData.ProxyCredentialPassedWithoutProxyUri
            }
        }
    }

    hidden [void] Modify([System.Collections.Hashtable] $properties)
    {

    }

    hidden [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $properties)
    {
        return $this.Get()
    }
}
