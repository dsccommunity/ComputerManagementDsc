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
            Name               = 'PowerShellGet'
            Repository         = 'PSGallery'
            RequiredVersion    = '2.2.5'
            Force              = $true
            SkipPublisherCheck = $false
            SingleInstance     = $true
            AllowPrerelease    = $False
        }
        This example shows how to call the resource using Invoke-DscResource.
#>
[DscResource()]
class PSResource : ResourceBase
{
    [DscProperty()]
    [Ensure]
    $Ensure = [Ensure]::Present

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
    [Nullable[System.Boolean]]
    $Latest

    [DscProperty()]
    [Nullable[System.Boolean]]
    $Force

    [DscProperty()]
    [Nullable[System.Boolean]]
    $AllowClobber

    [DscProperty()]
    [Nullable[System.Boolean]]
    $SkipPublisherCheck

    [DscProperty()]
    [Nullable[System.Boolean]]
    $SingleInstance

    [DscProperty()]
    [Nullable[System.Boolean]]
    $AllowPrerelease

    [DscProperty()]
    [PSCredential]
    $Credential

    [DscProperty()]
    [PSCredential]
    $ProxyCredential

    [DscProperty()]
    [System.String]
    $Proxy

    PSResource () : base ()
    {
        # These properties will not be enforced.
        $this.ExcludeDscProperties = @(
            'Name'
            'AllowPrerelease'
            'SkipPublisherCheck'
            'AllowClobber'
            'Force'
            'Repository'
            'Credential'
            'Proxy'
            'ProxyCredential'
        )
    }
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
        The parameter properties will contain the properties that should be enforced and that are not in desired
        state.
    #>
    hidden [void] Modify([System.Collections.Hashtable] $properties)
    {
        $params = @{
            Name = $this.Name
        }

        if ($this.Force)
        {
            $params.Force = $this.Force
        }
        if ($properties.ContainsKey('Ensure') -and $properties.Ensure -eq 'Absent' -and $this.Ensure -eq 'Absent')
        {
            if ($this.RequiredVersion -or $this.MaximumVersion -or $this.MinimumVersion)
            {
                $params.RequiredVersion = $this.RequiredVersion
                $params.MinimumVersion  = $this.MinimumVersion
                $params.MaximumVersion  = $this.MaximumVersion
            }
            else
            {

                $params.AllVersions = $true
            }
        }
    }

    <#
        The parameter properties will contain the key properties.
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
            $resource = $resources[0]
            $currentState.Ensure = [Ensure]::Present

            $version = $this.GetFullVersion($resource)
            $currentState.RequiredVersion = $version
            $currentState.MinimumVersion  = $version
            $currentState.MaximumVersion  = $version

            $currentState.SingleInstance  = $True

            $currentState.AllowPrerelease = $this.TestPrerelease($resource)

            if ($this.latest)
            {
                $currentState.Latest = $this.TestLatestVersion($version)
            }

            $this.SetSingleInstance($currentState.SingleInstance)
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

            if ($this.Latest)
            {
                $currentState.Latest          = $this.TestLatestVersion($currentState.RequiredVersion)
            }
        }

        return $currentState
    }

    <#
        The parameter properties will contain the properties that was
        assigned a value.
    #>
    hidden [void] AssertProperties([System.Collections.Hashtable] $properties)
    {
        Assert-Module -ModuleName PowerShellGet
        Assert-Module -ModuleName PackageManagement

        $powerShellGet = Get-Module -Name PowerShellGet

        if ($powerShellGet.Version -lt [version]'1.6.0' -and $this.AllowPrerelease)
        {
            $errorMessage = $this.localizedData.PowerShellGetVersionTooLowForAllowPrerelease
            New-InvalidArgumentException -ArgumentName 'AllowPrerelease' -message ($errorMessage -f $powerShellGet.Version)
        }

        $assertBoundParameterParameters = @{
            BoundParameterList = $this | Get-DscProperty -Type @('Key', 'Mandatory', 'Optional') -HasValue
            MutuallyExclusiveList1 = @(
                'Latest'
            )
            MutuallyExclusiveList2 = @(
                'MinimumVersion'
                'RequiredVersion'
                'MaximumVersion'
            )
        }

        Assert-BoundParameter @assertBoundParameterParameters

        $assertBoundParameterParameters = @{
            BoundParameterList = $this | Get-DscProperty -Type @('Key', 'Mandatory', 'Optional') -HasValue
            MutuallyExclusiveList1 = @(
                'MinimumVersion'
            )
            MutuallyExclusiveList2 = @(
                'RequiredVersion'
                'MaximumVersion'
            )
        }

        Assert-BoundParameter @assertBoundParameterParameters

        $assertBoundParameterParameters = @{
            BoundParameterList = $this | Get-DscProperty -Type @('Key', 'Mandatory', 'Optional') -HasValue
            MutuallyExclusiveList1 = @(
                'MaximumVersion'
            )
            MutuallyExclusiveList2 = @(
                'RequiredVersion'
                'MinimumVersion'
            )
        }

        Assert-BoundParameter @assertBoundParameterParameters

        $assertBoundParameterParameters = @{
            BoundParameterList = $this | Get-DscProperty -Type @('Key', 'Mandatory', 'Optional') -HasValue
            MutuallyExclusiveList1 = @(
                'RequiredVersion'
            )
            MutuallyExclusiveList2 = @(
                'MaximumVersion'
                'MinimumVersion'
                'AllVersions'
            )
        }

        Assert-BoundParameter @assertBoundParameterParameters

        if ($this.ProxyCredental -and (-not $this.Proxy))
        {
            $errorMessage = $this.localizedData.ProxyCredentialPassedWithoutProxyUri

            New-InvalidArgumentException -ArgumentName 'ProxyCredential' -Message $errorMessage
        }

        if ($this.Proxy -or $this.Credential -and (-not $this.Repository))
        {
            $errorMessage = $this.localizedData.ProxyorCredentialWithoutRepository

            New-InvalidArgumentException -ArgumentName 'Repository' -message $errorMessage
        }
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
        Write-Verbose -Message ($this.LocalizedData.GetLatestVersion -f $this.Name)
        $params = @{
            Name = $this.Name
        }

        if (-not ([System.String]::IsNullOrEmpty($this.Repository)))
        {
            Write-Verbose -Message ($this.LocalizedData.GetLatestVersionFromRepository -f $this.Name, $this.Repository)

            $params.Repository = $this.Repository
        }

        if ($this.AllowPrerelease)
        {
            Write-Verbose -Message ($this.LocalizedData.GetLatestVersionAllowPrerelease -f $this.Name)

            $params.AllowPrerelease = $this.AllowPrerelease
        }

        if ($this.Credential)
        {
            $params.Credential = $this.Credential
        }

        if ($this.Proxy)
        {
            Write-Verbose -Message ($this.LocalizedData.UsingProxyToGetResource -f $this.Proxy, $this.Name)

            $params.Proxy = $this.Proxy
        }

        if ($this.ProxyCredential)
        {
            $params.ProxyCredential = $this.ProxyCredential
        }

        $module = Find-Module @params

        Write-Verbose -Message ($this.LocalizedData.FoundLatestVersion -f $this.Name, $module.Version)

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


    <#
        Sets SingleInstance property when single instance is not explicitly set to True but only a single instance of the resource is present
    #>
    hidden [void] SetSingleInstance ([System.Boolean] $singleInstance)
    {
        if ($singleInstance -and (-not $this.SingleInstance))
        {
            $this.SingleInstance = $True
        }
    }
}
