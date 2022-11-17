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
class PSResource : ResourceBase
{
    [PSResource] Get()
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

}
