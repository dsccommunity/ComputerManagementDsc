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

    .PARAMETER AllowPrerelease
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
    $AllowPrerelease = $False

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
            Name               = $this.Name
            Ensure             = [Ensure]::Absent
            Repository         = $this.Repository
            SingleInstance     = $False
            AllowPrerelease    = $False
            Latest             = $False
            AllowClobber       = $this.AllowClobber
            SkipPublisherCheck = $this.SkipPublisherCheck
            Force              = $this.Force
        }

        $resources = $this.GetInstalledResource()

        if ($resources.Count -eq 1)
        {
            $currentState.Ensure = [Ensure]::Present

            $version = $this.GetFullVersion($resources)
            $currentState.RequiredVersion = $version
            $currentState.MinimumVersion  = $version
            $currentState.MaximumVersion  = $version

            $currentState.SingleInstance  = $True

            $currentState.AllowPrerelease = $this.TestPrerelease($resources)

            $latestVersion = $this.GetLatestVersion()

            $currentState.Latest = $this.TestLatestVersion($version)
        }
        elseif ($resources.count -gt 1)
        {
            #* multiple instances of resource found on system.
            $resourceInfo = @()

            foreach ($resource in $resources)
            {
                $resourceInfo += @{
                    Version    = $this.GetFullVersion($resource)
                    Prerelease = $this.TestPrerelease($resource)
                }
            }

            $currentState.Ensure          = [Ensure]::Present
            $currentState.RequiredVersion = ($resourceInfo | Sort-Object Version -Descending)[0].Version
            $currentState.MinimumVersion  = ($resourceInfo | Sort-Object Version)[0].Version
            $currentState.MaximumVersion  = $currentState.RequiredVersion
            $currentState.AllowPrerelease = ($resourceInfo | Sort-Object Version -Descending)[0].Prerelease
            $currentState.Latest          = $this.TestLatestVersion($currentState.RequiredVersion)
        }
        return $currentState
    }

    <#
        Returns true if only one instance of the resource is installed on the system
    #>
    hidden [System.Boolean] TestSingleInstance()
    {
        $count = (Get-Module -Name $this.Name -ListAvailable -ErrorAction SilentlyContinue).Count

        if ($count -eq 1)
        {
            return $true
        }
        else
        {
            return $false
        }
    }

    <#
        Get the latest version of the resource
    #>
    hidden [System.String] GetLatestVersion()
    {
        $params = @{
            Name = $this.Name
        }

        if (-not ([System.String]::IsNullOrEmpty($this.Repository)))
        {
            $params.Repository = $this.Repository
        }

        if ($this.AllowPrerelease)
        {
            $params.AllowPrerelease = $this.AllowPrerelease
        }

        $module = Find-Module @params
        return $module.Version
    }

    <#
        Get all instances of installed resource on the system
    #>
    hidden [System.Management.Automation.PSModuleInfo[]] GetInstalledResource()
    {
        return $(Get-Module -Name $this.Name -ListAvailable)
    }


    <#
        Get full version as a string checking for prerelease version
    #>
    hidden [System.String] GetFullVersion([System.Management.Automation.PSModuleInfo] $resource)
    {
        $version = [System.String]$resource.Version
        $prerelease = $resource.PrivateData.PSData.Prerelease
        if (-not ([System.String]::IsNullOrEmpty($prerelease)))
        {
            $version = "$($version)-$($prerelease)"
        }
        return $version
    }

    <#
        Test whether a given resource is prerelease
    #>
    hidden [System.Boolean] TestPrerelease ([System.Management.Automation.PSModuleInfo] $resource)
    {
        $prerelease = $False
        if (-not ([System.String]::IsNullOrEmpty($resource.PrivateData.PSData.Prerelease)))
        {
            $prerelease = $True
        }
        return $prerelease
    }

    <#
        tests whether the given resource version is the latest version available
    #>
    hidden [System.Boolean] TestLatestVersion ([System.String] $version)
    {
        $latestVersion = $this.GetLatestVersion()
        if ($latestVersion -eq $version)
        {
            return $true
        }
        return $false
    }
}
