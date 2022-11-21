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

    .PARAMETER Credential
        Specifies credentials of an account that has rights to register a repository.

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
    [Ensure]
    $Ensure = [Ensure]::Present

    [DscProperty(Key)]
    [System.String]
    $Name

    [DscProperty(Mandatory)]
    [System.String]
    $SourceLocation

    [DscProperty()]
    [PSCredential]
    $Credential

    [DscProperty()]
    [System.String]
    $ScriptSourceLocation

    [DscProperty()]
    [System.String]
    $PublishLocation

    [DscProperty()]
    [System.String]
    $ScriptPublishLocation

    [DscProperty()]
    [System.String]
    $Proxy

    [DscProperty()]
    [pscredential]
    $ProxyCredential

    [DscProperty()]
    [InstallationPolicy]
    $InstallationPolicy = [InstallationPolicy]::Untrusted

    [DscProperty()]
    [System.String]
    $PackageManagementProvider = 'NuGet'

    # [DscProperty(NotConfigurable)]
    # [System.Boolean]
    # $Trusted

    # [DscProperty(NotConfigurable)]
    # [System.Boolean]
    # $Registered

    PSResourceRepository () : base ()
    {
        # These properties will not be enforced.
        $this.ExcludeDscProperties = @(
            'Name'
        )
    }

    [PSResourceRepository] Get()
    {
        return ([ResourceBase]$this).Get()
    }

    [void] Set()
    {
        ([ResourceBase]$this).Set()
    }

    [Boolean] Test()
    {
        return ([ResourceBase] $this).Test()
    }

    # <#
    #     Set read-only Registered and Trusted properties on PSRepositoryObject
    # #>
    # hidden [void] SetReadProperties()
    # {
    #     $repository = Get-PSRepository -Name $this.Name -ErrorAction SilentlyContinue

    #     if ($repository)
    #     {
    #         $this.Registered = $repository.Registered
    #         $this.Trusted    = $repository.Trusted
    #     }
    # }

    hidden [void] Modify([System.Collections.Hashtable] $properties)
    {
        $params = @{
            Name = $this.Name
        }

        if ($properties.ContainsKey('Ensure') -and $properties.Ensure -eq 'Present' -and $this.Ensure -eq 'Absent')
        {
            # Ensure was not in desired state so the repository should be removed
            Write-Verbose -Message ($this.localizedData.RemoveExistingRepository -f $this.Name)

            Unregister-PSRepository @params

            return
        }
        elseif ($properties.ContainsKey('Ensure') -and $properties.Ensure -eq 'Absent' -and $this.Ensure -eq 'Present')
        {
            # Ensure was not in desired state so the repository should be created
            $register = $True

        }
        else
        {
            # Repository exist but one or more properties are not in desired state
            $register = $False
        }

        foreach ($key in $properties.Keys)
        {
            if (-not ($key -eq 'Ensure'))
            {
                Write-Verbose -Message ($this.localizedData.PropertyOutOfSync -f $key, $($properties.$key), $($this.$key))
                $params[$key] = $properties.$key
            }
        }

        if ( $register )
        {
            if (-not ($params.Keys -contains 'SourceLocation'))
            {
                $params['SourceLocation'] = $this.SourceLocation
            }

            Write-Verbose -Message ($this.localizedData.RegisterRepository -f $this.Name, $this.SourceLocation)

            Register-PSRepository @params
        }
        else
        {
            Write-Verbose -Message ($this.localizedData.UpdateRepository -f $this.Name, $this.SourceLocation)

            Set-PSRepository @params
        }


        # if (($properties.Keys -contains 'Ensure') -and ($properties.Ensure -eq 'Absent'))
        # {
        #     Write-Verbose -Message ($this.localizedData.RemoveExistingRepository -f $this.Name)

        #     Unregister-PSRepository -Name $this.Name

        #     return
        # }

        <#
            Update any properties not in desired state if the PSResourceRepository
            should be present. At this point it is assumed the PSResourceRepository
            exist since Ensure property was in desired state.
            If the desired state happens to be Absent then ignore any properties not
            in desired state (user have in that case wrongly added properties to an
            "absent configuration").
        #>
        # if ($this.Ensure -eq [Ensure]::Present)
        # {
        #     $params = @{
        #         Name = $this.Name
        #     }

        #     $this.SetReadProperties()

        #     foreach ($key in $properties.Keys)
        #     {
        #         if (-not ($key -eq 'Ensure'))
        #         {
        #             Write-Verbose -Message ($this.localizedData.PropertyOutOfSync -f $key, $($properties.$key), $($this.$key))
        #             $params[$key] = $properties.$key
        #         }
        #     }
        #     if (-not $this.Registered)
        #     {
        #         if (-not ($params.Keys -contains 'SourceLocation'))
        #         {
        #             $params['SourceLocation'] = $this.SourceLocation
        #         }

        #         Write-Verbose -Message ($this.localizedData.RegisterRepository -f $this.Name, $this.SourceLocation)
        #         Register-PSRepository @params
        #     }
        #     else
        #     {
        #         #* Dont waste time running Set-PSRepository if params only has the 'Name' key.
        #         if ($params.Keys.Count -gt 1)
        #         {
        #             Write-Verbose -Message ($this.localizedData.UpdateRepository -f $this.Name, $this.SourceLocation)

        #             Set-PSRepository @params
        #         }
        #     }
        # }
    }

    hidden [System.Collections.Hashtable] GetCurrentState ([System.Collections.Hashtable] $properties)
    {
        $returnValue = @{
            Ensure                    = [Ensure]::Absent
            Name                      = $this.Name
            SourceLocation            = $this.SourceLocation
        }

        Write-Verbose -Message ($this.localizedData.GetTargetResourceMessage -f $this.Name)

        $repository = Get-PSRepository -Name $this.Name -ErrorAction SilentlyContinue

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

        return $returnValue
    }

    <#
        The parameter properties will contain the properties that was
        assigned a value.
    #>
    hidden [void] AssertProperties([System.Collections.Hashtable] $properties)
    {
        Assert-Module -ModuleName PowerShellGet
        Assert-Module -ModuleName PackageManagement

        if ($this.ProxyCredental -and (-not $this.Proxy))
        {
            $errorMessage = $this.localizedData.ProxyCredentialPassedWithoutProxyUri

            New-InvalidArgumentException -ArgumentName 'ProxyCredential' -Message $errorMessage
        }
    }
}
