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

    .PARAMETER Proxy
        Specifies the URI of the proxy to connect to this PSResourceRepository

    .PARAMETER ProxyCredential
        Specifies the Credential to connect to the PSResourceRepository proxy

    .PARAMETER InstallationPolicy
        Specifies the installation policy. Valid values are  'Trusted'
        or 'Untrusted'. The default value is 'Untrusted'.

    .PARAMETER PackageManagementProvider
        Specifies a OneGet package provider. Default value is 'NuGet'.

    .EXAMPLE
        Invoke-DscResource -ModuleName ComputerManagementDsc -Name PSResourceRepository -Method Get -Property @{
            Name                      = 'PSGallery'
            SourceLocation            = 'https://www.powershellgallery.com/api/v2'
            ScriptSourceLocation      = 'https://www.powershellgallery.com/api/v2/items/psscript'
            PublishLocation           = 'https://www.powershellgallery.com/api/v2/package/'
            ScriptPublishLocation     = 'https://www.powershellgallery.com/api/v2/package/'
            InstallationPolicy        = 'Untrusted'
            PackageManagementProvider = 'NuGet'
        }
        This example shows how to call the resource using Invoke-DscResource.
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
            $returnValue['Ensure']                    = [Ensure]::Present
            $returnValue['SourceLocation']            = $repository.SourceLocation
            $returnValue['ScriptSourceLocation']      = $repository.ScriptSourceLocation
            $returnValue['PublishLocation']           = $repository.PublishLocation
            $returnValue['ScriptPublishLocation']     = $repository.ScriptPublishLocation
            $returnValue['Proxy']                     = $repository.Proxy
            $returnValue['ProxyCredential']           = $repository.ProxyCredental
            $returnValue['InstallationPolicy']        = [InstallationPolicy]::$($repository.InstallationPolicy)
            $returnValue['PackageManagementProvider'] = $repository.PackageManagementProvider
            $returnValue['Trusted']                   = $repository.Trusted
            $returnValue['Registered']                = $repository.Registered
        }
        else
        {
            Write-Verbose -Message ($this.localizedData.RepositoryNotFound -f $this.Name)
        }
        return $returnValue
    }

    [void] Set()
    {
        $repository_state = $this.Get()

        Write-Verbose -Message ($this.localizedData.RepositoryState -f $this.name, $this.Ensure)

        if ($this.Ensure -eq [Ensure]::Present)
        {
            $params = @{
                Name           = $this.Name
                SourceLocation = $this.SourceLocation
            }

            $this.CheckProxyConfiguration()

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
                $params = @{
                    Name = $this.Name
                }

                if ($repository_state.SourceLocation -ne $this.SourceLocation)
                {
                    Write-Verbose -Message ($this.localizedData.PropertyOutOfSync -f 'SourceLocation', $repository_state.SourceLocation, $this.SourceLocation)
                    $params['SourceLocation'] = $this.SourceLocation
                }

                if (-not [System.String]::IsNullOrEmpty($this.ScriptSourceLocation))
                {
                    if ($repository_state.ScriptSourceLocation -ne $this.ScriptSourceLocation)
                    {
                        Write-Verbose -Message ($this.localizedData.PropertyOutOfSync -f 'ScriptSourceLocation', $repository_state.ScriptSourceLocation, $this.ScriptSourceLocation)
                        $params['ScriptSourceLocation'] = $this.ScriptSourceLocation
                    }
                }

                if (-not [System.String]::IsNullOrEmpty($this.PublishLocation))
                {
                    if ($repository_state.PublishLocation -ne $this.PublishLocation)
                    {
                        Write-Verbose -Message ($this.localizedData.PropertyOutOfSync -f 'PublishLocation', $repository_state.PublishLocation, $this.PublishLocation)
                        $params['PublishLocation'] = $this.PublishLocation
                    }
                }

                if (-not [System.String]::IsNullOrEmpty($this.ScriptPublishLocation))
                {
                    if ($repository_state.ScriptPublishLocation -ne $this.ScriptPublishLocation)
                    {
                        Write-Verbose -Message ($this.localizedData.PropertyOutOfSync -f 'ScriptPublishLocation', $repository_state.ScriptPublishLocation, $this.ScriptPublishLocation)
                        $params['ScriptPublishLocation'] = $this.ScriptPublishLocation
                    }
                }

                if (-not [System.String]::IsNullOrEmpty($this.Proxy))
                {
                    if ($repository_state.Proxy -ne $this.Proxy)
                    {
                        Write-Verbose -Message ($this.localizedData.PropertyOutOfSync -f 'Proxy', $repository_state.Proxy, $this.Proxy)
                        $params['Proxy'] = $this.Proxy
                    }
                }

                if (-not [System.String]::IsNullOrEmpty($this.ProxyCredential))
                {
                    if ($repository_state.ProxyCredential -ne $this.ProxyCredential)
                    {
                        Write-Verbose -Message ($this.localizedData.PropertyOutOfSync -f 'ProxyCredential', $repository_state.ProxyCredential, $this.ProxyCredential)
                        $params['ProxyCredential'] = $this.ProxyCredential
                    }
                }

                if ($repository_state.InstallationPolicy -ne $this.InstallationPolicy)
                {
                    Write-Verbose -Message ($this.localizedData.PropertyOutOfSync -f 'InstallationPolicy', $repository_state.InstallationPolicy, $this.InstallationPolicy)
                    $params['InstallationPolicy'] = $this.InstallationPolicy
                }

                if ($repository_state.PackageManagementProvider -ne $this.PackageManagementProvider)
                {
                    Write-Verbose -Message ($this.localizedData.PropertyOutOfSync -f 'PackageManagementProvider', $repository_state.PackageManagementProvider, $this.PackageManagementProvider)
                    $params['PackageManagementProvider'] = $this.PackageManagementProvider
                }

                Set-PSRepository @params
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

    #* Throws if ProxyCredential was passed without Proxy uri
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
        # TODO: Add logic to function. Comment to avoid HQRM test to throw on empty function.
    }

    hidden [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $properties)
    {
        return $this.Get()
    }
}
