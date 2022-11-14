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

    hidden [void] Modify([System.Collections.Hashtable] $properties)
    {
        Write-Verbose "In Modify"

        # TODO: Add logic to function. Comment to avoid HQRM test to throw on empty function.
        if ($properties.Keys -contains 'Ensure')
        {
            Write-Verbose "key contains Ensure"
            switch ($properties.Ensure)
            {
                'Absent' {
                    Write-Verbose -Message ($this.localizedData.RemoveExistingRepository -f $this.Name)
                    Unregister-PSRepository -Name $this.Name
                }
            }
        }
        else
        {
            <#
                Update any properties not in desired state if the PSResourceRepository
                should be present. At this point it is assumed the PSResourceRepository
                exist since Ensure property was in desired state.
                If the desired state happens to be Absent then ignore any properties not
                in desired state (user have in that case wrongly added properties to an
                "absent configuration").
            #>
            if ($this.Ensure -eq [Ensure]::Present)
            {
                $params = @{
                    Name = $this.Name
                }

                Write-Verbose "this.reg'd equals $($this.registered)"

                foreach ($property in $properties)
                {
                    #? Registered & Trusted are both hidden, does Compare() return them?
                    if (! $property.Property -in @('Ensure','Registered','Trusted'))
                    {
                        Write-Verbose -Message ($this.localizedData.PropertyOutOfSync -f $property.Property, $property.ActualValue, $property.ExpectedValue)
                        $params[$property.Property] = $property.ExpectedValue
                    }
                }
                if (-not $this.Registered)
                {
                    write-verbose "we should be about to register-psrepository"
                    Write-Verbose -Message ($this.localizedData.RegisterRepository -f $this.Name)
                    Register-PSRepository @params
                }
                else
                {
                    #* Dont waste time running Set-PSRepository if params only has the 'Name' key.
                    if ($params.Keys.Count -gt 1)
                    {
                        Write-Verbose -Message ($this.localizedData.UpdateRepository -f $this.Name)
                        Set-PSRepository @params
                    }
                }
            }
        }
    }

    hidden [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $properties)
    {
        $returnValue = @{
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
        return $returnValue
    }

    <#
        The parameter properties will contain the properties that was
        assigned a value.
    #>
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidEmptyNamedBlocks', '')]
    hidden [void] AssertProperties([System.Collections.Hashtable] $properties)
    {
        Assert-Module PowerShellGet
        Assert-Module PackageManagement

        if ($this.ProxyCredental -and (-not $this.Proxy))
        {
            $errorMessage = $this.localizedData.ProxyCredentialPassedWithoutProxyUri
            New-InvalidArgumentException -ArgumentName 'ProxyCredential' -Message $errorMessage
        }
    }

}
