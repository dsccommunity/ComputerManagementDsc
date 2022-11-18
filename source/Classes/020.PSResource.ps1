<#
    .SYNOPSIS
        The `PSResource` Dsc resource is used to manage PowerShell resources on a server.

    .PARAMETER Ensure
        If the resource should be present or absent on the server
        being configured. Default values is 'Present'.

    .PARAMETER Name
        Specifies the name of the resource to manage.

    .PARAMETER Repository
         Specifies the name of the PSRepository where the resource can be found.

    .PARAMETER RequiredVersion
         Specifies the version of the resource you want to install or uninstall

    .PARAMETER MaximumVersion
        Specifies the maximum version of the resource you want to install or uninstall.

    .PARAMETER MinimumVersion
        Specifies the minimum version of the resource you want to install or uninstall.

    .PARAMETER Latest
        Specifies whether to use the latest available version of the resource.

    .PARAMETER Force
        Forces the installation of resource. If a resource of the same name and version already exists on the computer,
        this parameter overwrites the existing resource with one of the same name that was found by the command.

    .PARAMETER AllowClobber
        Allows the installation of resource regardless of if other existing resource on the computer have cmdlets
        of the same name.

    .PARAMETER SkipPublisherCheck
        Allows the installation of resource that have not been catalog signed.

    .PARAMETER SingleInstance
        Specifies whether only one version of the resource should installed be on the server.

    .PARAMETER AllowPreRelease
        Specifies whether to allow pre-release versions of the resource.

    .EXAMPLE
        Invoke-DscResource -ModuleName ComputerManagementDsc -Name PSResource -Method Get -Property @{
            Name                  = 'PowerShellGet'
            Repository            = 'PSGallery'
            RequiredVersion       = '2.2.5'
            Force                 = $true
            ScriptPublishLocation = $false
            SingleInstance        = $true
        }
        This example shows how to call the resource using Invoke-DscResource.
#>
[DscResource()]
class PSResource : ResourceBase
{
    [DscProperty()]
    [Ensure] $Ensure = [Ensure]::Present

    [DscProperty(Key)]
    [System.String]
    $Name

    [DscProperty()]
    [System.String]
    $Repository

    [DscProperty()]
    [System.String]
    $RequiredVersion

    [DscProperty()]
    [System.String]
    $MaximumVersion

    [DscProperty()]
    [System.String]
    $MinimumVersion

    [DscProperty()]
    [System.Boolean]
    $Latest = $False

    [DscProperty()]
    [System.Boolean]
    $Force = $False

    [DscProperty()]
    [System.Boolean]
    $AllowClobber = $False

    [DscProperty()]
    [System.Boolean]
    $SkipPublisherCheck = $False

    [DscProperty()]
    [System.Boolean]
    $SingleInstance = $False

    [DscProperty()]
    [System.Boolean]
    $AllowPreRelease = $False

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

    <#
        This method must be overridden by a resource. The parameter properties will
        contain the key properties.
    #>
    hidden [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $properties)
    {
        $currentState = @{
            Name = $this.Name
            Ensure = [Ensure]::Absent
            Repository = $null
            RequiredVersion =
            Force = $this.Force
            SingleInstance = $this.SingleInstance
        }
        return $currentState
    }

    hidden [System.Boolean] CheckSingleInstance ()
    {

    }

}
