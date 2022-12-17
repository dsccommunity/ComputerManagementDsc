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

    .PARAMETER Credential
        Specifies credentials of an account that has rights to the repository.

    .PARAMETER Proxy
        Specifies the URI of the proxy to connect to the repository.

    .PARAMETER ProxyCredential
        Specifies the Credential to connect to the repository proxy.

    .PARAMETER RemoveNonCompliantVersions
        Specifies whether to remove resources that do not meet criteria of MinimumVersion, MaximumVersion, or RequiredVersion

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
    [System.String]
    $Proxy

    [DscProperty()]
    [PSCredential]
    $ProxyCredential

    [DscProperty()]
    [Nullable[System.Boolean]]
    $RemoveNonCompliantVersions

    <#
        Property for holding the latest version of the resource available
    #>
    hidden [Version]
    $LatestVersion

    <#
        Property for holding the given version requirement (MinimumVersion, MaximumVersion, RequiredVersion or Latest) if passed
    #>
    hidden [System.String]
    $VersionRequirement

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

        $this.VersionRequirement = $null
        $this.LatestVersion      = $null
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
        $installedResource = $this.GetInstalledResource()

        if ($properties.ContainsKey('Ensure') -and $properties.Ensure -eq 'Absent' -and $this.Ensure -eq 'Absent')
        {
            if ($properties.ContainsKey('RequiredVersion') -and $this.RequiredVersion)
            {
                $resourceToUninstall = $installedResource | Where-Object {$_.Version -eq [Version]$this.RequiredVersion}
                $this.UninstallModule($resourceToUninstall)
            }
            foreach ($resource in installedResource)
            {
                $this.UninstallResource($resource)
            }
        }
        elseif ($properties.ContainsKey('Ensure') -and $properties.Ensure -eq 'Present' -and $this.Ensure -eq 'Present')
        {
            #* Module does not exist at all
            $this.InstallResource()
        }
        elseif ($properties.ContainsKey('SingleInstance'))
        {
            $this.ResolveSingleInstance($installedResource)

            return
        }
        elseif ($properties.ContainsKey('RemoveNonCompliantVersions') -and $this.RemoveNonCompliantVersions)
        {
            $this.UninstallNonCompliantVersions($installedResource)

            if ($this.VersionRequirement -in $properties.Keys)
            {
                $this.InstallResource()
                return
            }
        }
        else
        {
            $this.InstallResource()
        }
    }

    <#
        The parameter properties will contain the key properties.
    #>
    hidden [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $properties)
    {
        $currentState = $this | Get-DscProperty -ExcludeName $this.ExcludeDscProperties -Type @('Key', 'Mandatory', 'Optional') -HasValue

        $resources = $this.GetInstalledResource()

        $returnValue = @{
            Name   = $this.Name
            Ensure = [Ensure]::Absent
        }

        if ($currentState.ContainsKey('SingleInstance') -and $this.SingleInstance)
        {
            $returnValue.SingleInstance = $this.TestSingleInstance($resources)
        }

        if ($currentState.ContainsKey('Latest') -and $this.Latest -eq $true)
        {
            $returnValue.Latest = $this.TestLatestVersion($resources)
        }

        if ($null -eq $resources)
        {
            Write-Verbose -Message ($this.localizedData.ResourceNotInstalled -f $this.Name)
        }
        else
        {
            $returnValue.Ensure = [Ensure]::Present

            if (-not [System.String]::IsNullOrEmpty($this.VersionRequirement) -and -not $currentState.ContainsKey('Latest'))
            {
                $returnValue.$($this.VersionRequirement) = $this.GetRequiredVersionFromVersionRequirement($resources, $this.VersionRequirement)
            }
        }

        if (-not [System.String]::IsNullOrEmpty($this.VersionRequirement) -and $currentState.ContainsKey('RemoveNonCompliantVersions'))
        {
            $returnValue.RemoveNonCompliantVersions = $this.TestVersionRequirement($resources, $this.VersionRequirement)
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

        $powerShellGet = Get-Module -Name PowerShellGet

        if ($powerShellGet.Version -lt [version]'1.6.0' -and $properties.ContainsKey('AllowPrerelease'))
        {
            $errorMessage = $this.localizedData.PowerShellGetVersionTooLowForAllowPrerelease
            New-InvalidArgumentException -ArgumentName 'AllowPrerelease' -message ($errorMessage -f $powerShellGet.Version)
        }

        $assertBoundParameterParameters = @{
            BoundParameterList = $properties
            MutuallyExclusiveList1 = @(
                'RemoveNonCompliantVersions'
            )
            MutuallyExclusiveList2 = @(
                'SingleInstance'
            )
        }

        Assert-BoundParameter @assertBoundParameterParameters

        $assertBoundParameterParameters = @{
            BoundParameterList = $properties
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
            BoundParameterList = $properties
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
            BoundParameterList = $properties
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
            BoundParameterList = $properties
            MutuallyExclusiveList1 = @(
                'RequiredVersion'
            )
            MutuallyExclusiveList2 = @(
                'MaximumVersion'
                'MinimumVersion'
            )
        }

        Assert-BoundParameter @assertBoundParameterParameters

        if ($this.Ensure -eq 'Absent' -and (
                $properties.ContainsKey('MinimumVersion') -or
                $properties.ContainsKey('MaximumVersion') -or
                $properties.ContainsKey('Latest')
            )
        )
        {
            $errorMessage = $this.localizedData.EnsureAbsentWithVersioning

            New-InvalidArgumentException -ArgumentName 'Ensure' -Message $errorMessage
        }

        if ($properties.ContainsKey('ProxyCredental') -and (-not $properties.ContainsKey('Proxy')))
        {
            $errorMessage = $this.localizedData.ProxyCredentialPassedWithoutProxyUri

            New-InvalidArgumentException -ArgumentName 'ProxyCredential' -Message $errorMessage
        }

        if ($properties.ContainsKey('Proxy') -or $properties.ContainsKey('Credential') -and (-not $properties.ContainsKey('Repository')))
        {
            $errorMessage = $this.localizedData.ProxyorCredentialWithoutRepository

            New-InvalidArgumentException -ArgumentName 'Repository' -message $errorMessage
        }

        if ($properties.ContainsKey('RemoveNonCompliantVersions') -and
            -not (
                $properties.ContainsKey('MinimumVersion') -or
                $Properties.ContainsKey('MaximumVersion') -or
                $Properties.ContainsKey('RequiredVersion') -or
                $Properties.ContainsKey('Latest')
            )
        )
        {
            $errorMessage = $this.localizedData.RemoveNonCompliantVersionsWithoutVersioning

            New-InvalidArgumentException -ArgumentName 'RemoveNonCompliantVersions' -message $errorMessage
        }

        <#
            Is this the correct place to set hidden properties? I want to set them once rather than multiple times as required in the code
            Assert() calls this before Get/Set/Test, so this ensures they're always set if necessary.
        #>
        if ($properties.ContainsKey('Latest'))
        {
            $this.LatestVersion = $this.GetLatestVersion()
        }

        if ($properties.ContainsKey('MinimumVersion') -or
            $Properties.ContainsKey('MaximumVersion') -or
            $Properties.ContainsKey('RequiredVersion') -or
            $Properties.ContainsKey('Latest')
        )
        {
            $this.VersionRequirement = $this.GetVersionRequirement()
        }
    }

    <#
        Returns true if only the correct instance of the resource is installed on the system

        hidden [System.Boolean] TestSingleInstance([System.Management.Automation.PSModuleInfo[]]$resources)
    #>
    hidden [System.Boolean] TestSingleInstance([System.Collections.Hashtable[]]$resources)
    {
        $return = $false #! Is this the correct default if somehow the if/else isn't triggered?

        if ($resources.Count -ne 1)
        {
            Write-Verbose -Message ($this.localizedData.ShouldBeSingleInstance -f $this.Name, $resources.Count)

            $return = $false
        }
        else
        {
            #* SingleInstance should not rely on VersionRequirements to report correctly
            $return = $true
        }

        return $return
    }

    <#
        Get the latest version of the resource
    #>
    hidden [Version] GetLatestVersion()
    {
        Write-Verbose -Message ($this.LocalizedData.GetLatestVersion -f $this.Name)
        $resource = $this.FindResource()

        Write-Verbose -Message ($this.LocalizedData.FoundLatestVersion -f $this.Name, $resource.Version)

        return $resource.Version
    }

    <#
        Get all instances of installed resource on the system

        hidden [System.Management.Automation.PSModuleInfo[]] GetInstalledResource()
    #>
    hidden [System.Collections.Hashtable[]] GetInstalledResource()
    {
        return $(Get-Module -Name $this.Name -ListAvailable)
    }

    <#
        Get full version as a string checking for prerelease version

        hidden [System.String] GetFullVersion([System.Management.Automation.PSModuleInfo] $resource)
    #>
    hidden [System.String] GetFullVersion([System.Collections.Hashtable] $resource)
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

        hidden [System.Boolean] TestPrerelease ([System.Management.Automation.PSModuleInfo] $resource)
    #>
    hidden [System.Boolean] TestPrerelease ([System.Collections.Hashtable] $resource)
    {
        $prerelease = $False
        if (-not ([System.String]::IsNullOrEmpty($resource.PrivateData.PSData.Prerelease)))
        {
            $prerelease = $True
        }
        return $prerelease
    }

    <#
        tests whether the installed resources includes the latest version available
    #>
    hidden [System.Boolean] TestLatestVersion ([System.Management.Automation.PSModuleInfo[]] $resources)
    {
        $return = $false

        if ($this.LatestVersion -notin $resources.Version)
        {
            Write-Verbose -Message ($this.localizedData.ShouldBeLatest -f $this.Name, $this.LatestVersion)
        }
        else
        {
            Write-Verbose -Message ($this.localizedData.IsLatest -f $this.Name, $this.LatestVersion)

            $return = $true
        }

        return $return
    }

    <#
        Tests whether the repository the resource will install from is trusted and if not if Force is set
    #>
    hidden [void] TestRepository ()
    {
        if (-not $this.Force)
        {
            $resource = $this.FindResource()

            $resourceRepository = Get-PSRepository -Name $resource.Repository

            if ($resourceRepository.InstallationPolicy -eq  'Untrusted')
            {
                $errorMessage = $this.localizedData.UntrustedRepositoryWithoutForce

                New-InvalidArgumentException -Message ($errorMessage -f $resourceRepository.Name) -ArgumentName 'Force'
            }
        }
    }

    <#
        Find the latest resource on a PSRepository
    #>
    hidden [PSCustomObject] FindResource()
    {
        $params = $this | Get-DscProperty -ExcludeName @('Latest', 'SingleInstance', 'Ensure', 'SkipPublisherCheck', 'Force', 'RemoveNonCompliantVersions') -Type Key,Optional -HasValue
        return Find-Module @params
    }

    hidden [void] InstallResource()
    {
        $this.TestRepository()

        $params = $this | Get-DscProperty -ExcludeName @('Latest','SingleInstance','Ensure','RemoveNonCompliantVersions') -Type Key,Optional -HasValue
        Install-Module @params
    }

    <#
        Uninstall the given resource

        hidden [void] UninstallResource ([System.Management.Automation.PSModuleInfo]$resource)
    #>
    hidden [void] UninstallResource ([System.Collections.Hashtable]$resource)
    {
        $params = $this | Get-DscProperty -ExcludeName @('Latest','SingleInstance','Ensure', 'SkipPublisherCheck', 'RemoveNonCompliantVersions','MinimumVersion', 'MaximumVersion', 'RequiredVersion') -Type Optional -HasValue
        $params.RequiredVersion = $resource.Version

        Write-Verbose -Message ($this.localizedData.UninstallResource -f $resource.Name,$resource.Version)

        $resource | Uninstall-Module @params
    }

    <#
        Checks whether all the installed resources meet the given versioning requirements of either MinimumVersion, MaximumVersion, or RequiredVersion

        hidden [System.Boolean] TestVersionRequirement ([System.Management.Automation.PSModuleInfo[]] $resources, [System.String] $requirement)
    #>
    hidden [System.Boolean] TestVersionRequirement ([System.Collections.Hashtable[]] $resources, [System.String] $requirement)
    {
        Write-Verbose -Message ($this.localizedData.TestVersionRequirement -f $requirement)

        $return = $true

        switch ($requirement)
        {
            'MinimumVersion' {
                foreach ($resource in $resources)
                {
                    if ($resource.Version -lt [Version]$this.MinimumVersion)
                    {
                        Write-Verbose -Message ($this.localizedData.InstalledResourceDoesNotMeetMinimumVersion -f ($this.Name, $resource.Version, $this.MinimumVersion))

                        $return = $false
                    }
                }
            }
            'MaximumVersion' {
                foreach ($resource in $resources)
                {
                    if ($resource.Version -gt [Version]$this.MaximumVersion)
                    {
                        Write-Verbose -Message ($this.localizedData.InstalledResourceDoesNotMeetMaximumVersion -f ($this.Name, $resource.Version, $this.MaximumVersion))

                        $return = $false
                    }
                }
            }
            'RequiredVersion' {
                foreach ($resource in $resources)
                {
                    if ($resource.Version -ne [Version]$this.RequiredVersion)
                    {
                        Write-Verbose -Message ($this.localizedData.InstalledResourceDoesNotMeetRequiredVersion -f ($this.Name, $resource.Version, $this.RequiredVersion))

                        $return = $false
                    }
                }
            }
            'Latest' {
                $nonCompliantVersions = ($resources | Where-Object {$_.Version -ne $this.LatestVersion}).Count
                if ($nonCompliantVersions -gt 1)
                {
                    Write-Verbose -Message ($this.localizedData.InstalledResourcesDoNotMeetLatestVersion -f ($nonCompliantVersions, $this.Name))

                    $return = $false
                }
            }
        }

        return $return
    }

    <#
        Returns the minimum version of a resource installed on the system.

        If a resource matches the exact minimum version, that version is returned.
        If no resources matches the exact minimum version, the eldest version is returned.

        hidden [System.String] GetMinimumInstalledVersion([System.Management.Automation.PSModuleInfo[]] $resources)
    #>
    hidden [System.String] GetMinimumInstalledVersion([System.Collections.Hashtable[]] $resources)
    {
        $return = $null

        foreach ($resource in $resources)
        {
            if ($resource.version -ge [version]$this.MinimumVersion)
            {
                $return = $this.MinimumVersion

                Write-Verbose -Message ($this.localizedData.MinimumVersionMet -f $this.Name, $return)

                break
            }

        }

        if ([System.String]::IsNullOrEmpty($return))
        {
            $return = $($resources | Sort-Object Version)[0].Version

            Write-Verbose -Message ($this.localizedData.MinimumVersionExceeded -f $this.Name, $this.MinimumVersion, $return)
        }

        return $return
    }

    <#
        Returns the maximum version of a resource installed on the system.

        If a resource matches the exact maximum version, that version is returned.
        If no resources matches the exact maximum version, the youngest version is returned.

        hidden [System.String] GetMaximumInstalledVersion([System.Management.Automation.PSModuleInfo[]] $resources)
    #>
    hidden [System.String] GetMaximumInstalledVersion([System.Collections.Hashtable[]] $resources)
    {
        $return = $null

        foreach ($resource in $resources)
        {
            if ($resource.version -le [version]$this.MaximumVersion)
            {
                $return = $this.MaximumVersion

                Write-Verbose -Message ($this.localizedData.MaximumVersionMet -f $this.Name, $return)

                break
            }
        }

        if ([System.String]::IsNullOrEmpty($return))
        {
            $return =  $($resources | Sort-Object Version -Descending)[0].Version

            Write-Verbose -Message ($this.localizedData.MaximumVersionExceeded -f $this.Name, $this.MaximumVersion, $return)
        }

        return $return
    }

    <#
        Returns the required version of the resource if it is installed on the system.

        hidden [System.String] GetRequiredInstalledVersion([System.Management.Automation.PSModuleInfo[]] $resources)
    #>
    hidden [System.String] GetRequiredInstalledVersion([System.Collections.Hashtable[]] $resources)
    {
        $return = $null

        if ($this.RequiredVersion -in $resources.Version)
        {
            $return = $this.RequiredVersion

            Write-Verbose -Message ($this.localizedData.RequiredVersionMet -f $this.Name, $return)
        }

        return $return
    }

    <#
        Return the resource's version requirement
    #>
    hidden [System.String] GetVersionRequirement ()
    {
        $return = $null

        $versionProperties = @('Latest', 'MinimumVersion', 'MaximumVersion', 'RequiredVersion')

        foreach ($prop in $versionProperties)
        {
            if (-not [System.String]::IsNullOrEmpty($this.$prop))
            {
                $return = $prop
                break
            }
        }

        Write-Verbose -Message ($this.localizedData.VersionRequirementFound -f $this.Name, $return)

        return $return
    }

    <#
        Returns the version that matches the given requirement from the installed resources.

        hidden [System.String] GetRequiredVersionFromVersionRequirement ([System.Management.Automation.PSModuleInfo[]] $resources,[System.String]$requirement)
    #>
    hidden [System.String] GetRequiredVersionFromVersionRequirement ([System.Collections.Hashtable[]] $resources, [System.String]$requirement)
    {
        $return = $null

        switch ($requirement)
        {
            'MinimumVersion'
            {
                $return = $this.GetMinimumInstalledVersion($resources)
            }
            'MaximumVersion'
            {
                $return = $this.GetMaximumInstalledVersion($resources)
            }
            'RequiredVersion'
            {
                $return = $this.GetRequiredInstalledVersion($resources)
            }
            default
            {
                $errorMessage = ($this.localizedData.GetRequiredVersionFromVersionRequirementError -f $requirement)
                New-InvalidArgumentException -Message $errorMessage -Argument 'versionRequirement'
            }
        }

        return $return
    }

    <#
        Uninstall resources that do not match the given version requirement

        hidden [void] UninstallNonCompliantVersions ([System.Management.Automation.PSModuleInfo[]] $resources)
    #>
    hidden [void] UninstallNonCompliantVersions ([System.Collections.Hashtable[]] $resources)
    {
        $resourcesToUninstall = $null

        switch ($this.VersionRequirement)
        {
            'MinimumVersion'
            {
                $resourcesToUninstall = $resources | Where-Object {$_.Version -lt [Version]$this.MinimumVersion}
            }
            'MaximumVersion'
            {
                $resourcesToUninstall = $resources | Where-Object {$_.Version -gt [Version]$this.MaximumVersion}
            }
            'RequiredVersion'
            {
                $resourcesToUninstall = $resources | Where-Object {$_.Version -ne $this.RequiredVersion}
            }
            'Latest'
            {
                #* get latest version and remove all others

                $resourcesToUninstall = $resources | Where-Object {$_.Version -ne $this.LatestVersion}
            }
        }

        Write-Verbose -Message ($this.localizedData.NonCompliantVersionCount -f $resourcesToUninstall.Count, $this.Name)

        foreach ($resource in $resourcesToUninstall)
        {
            $this.UninstallResource($resource)
        }
    }

    <#
        Resolve single instance status. Find the required version, uninstall all others. Install required version is necessary.

        hidden [void] ResolveSingleInstance ([System.Management.Automation.PSModuleInfo[]] $resources)
    #>
    hidden [void] ResolveSingleInstance ([System.Collections.Hashtable[]] $resources)
    {
        Write-Verbose -Message ($this.localizedData.ShouldBeSingleInstance -f $this.Name, $resources.Count)

        #* Too many versions

        $resourceToKeep = $this.FindResource()

        if ($resourceToKeep.Version -in $resources.Version)
        {
            $resourcesToUninstall = $resources | Where-Object {$_.Version -ne $resourceToKeep.Version}
        }
        else
        {
            $resourcesToUninstall = $resources
            $this.InstallResource()
        }

        foreach ($resource in $resourcesToUninstall)
        {
            $this.UninstallResource($resource)
        }
    }
}
