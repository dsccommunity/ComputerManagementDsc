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

    <#!
        Does MaximumVersion mean any version higher than given is removed?
        or
        The system is in the correct state as long as a module that is the MaximumVersion
            or lower is present?
    #>
    [DscProperty()]
    [System.String]
    $MaximumVersion

    <#!
        Does MinimumVersion mean any version lower than given is removed?
        or
        The system is in the correct state as long as a module that is the MinimumVersion
            or higher is present?
    #>
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
        if ($this.Ensure -eq 'Present')
        {
            $this.TestRepository()
        }

        if ($properties.ContainsKey('Ensure') -and $properties.Ensure -eq 'Absent' -and $this.Ensure -eq 'Absent')
        {
            $installedResource = $this.GetInstalledResource()

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
            Write-Verbose -Message ($this.localizedData.ShouldBeSingleInstance -f $this.Name)

            #* Too many versions
            $installedResource = $this.GetInstalledResource()

            $resourceToKeep = $this.FindResource()

            if ($resourceToKeep.Version -in $installedResource.Version)
            {
                $resourcesToUninstall = $installedResource | Where-Object {$_.Version -ne $resourceToKeep.Version}
            }
            else
            {
                $resourcesToUninstall = $installedResource
                $this.InstallResource()
            }

            foreach ($resource in $resourcesToUninstall)
            {
                $this.UninstallResource($resource)
            }

            return
        }
        elseif ($properties.ContainsKey('RemoveNonCompliantVersions') -and $this.RemoveNonCompliantVersions)
        {
            $installedResource = $this.GetInstalledResource()

            if ($this.MinimumVersion)
            {
                foreach ($resource in $installedResource)
                {
                    if ($resource.Version -lt [Version]$this.MinimumVersion)
                    {
                        $this.UninstallResource($resource)
                    }
                }

                if ($properties.ContainsKey('MinimumVersion'))
                {
                    $this.InstallResource()
                    return
                }

            }

            if ($this.MaximumVersion)
            {
                foreach ($resource in $installedResource)
                {
                    if ($resource.Version -gt [Version]$this.MaximumVersion)
                    {
                        $this.UninstallResource($resource)
                    }
                }

                if ($properties.ContainsKey('MaximumVersion'))
                {
                    $this.InstallResource()

                    return
                }

            }

            if ($this.RequiredVersion)
            {
                foreach ($resource in $installedResource)
                {
                    if ($resource.Version -ne [Version]$this.RequiredVersion)
                    {
                        $this.UninstallResource($resource)
                    }
                }

                if ($properties.ContainsKey('RequiredVersion'))
                {
                    $this.InstallResource()

                    return
                }
            }

            if ($this.Latest)
            {
                if ($properties.ContainsKey('Latest'))
                {
                    foreach ($resource in $installedResource)
                    {
                        $this.UninstallResource($resource)
                    }

                    $this.InstallResource()

                    return
                }
                else
                {
                    $latestVersion = $this.GetLatestVersion()
                    #* get latest version and remove all others
                    foreach ($resource in $installedResource)
                    {
                        if ($resource.Version -ne $latestVersion)
                        {
                            $this.UninstallResource($resource)
                        }
                    }

                    return
                }

            }
            return
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
            if ($resources.Count -ne 1)
            {
                Write-Verbose -Message ($this.localizedData.ShouldBeSingleInstance -f $this.Name, $resources.Count)

                $returnValue.SingleInstance = $false
            }
            else
            {
                Write-Verbose -Message ($this.localizedData.IsSingleInstance -f $this.Name)

                $returnValue.SingleInstance = $true
            }
        }

        if ($currentState.ContainsKey('Latest') -and $this.Latest -eq $true)
        {
            $latestVersion = $this.GetLatestVersion()

            if ($latestVersion -notin $resources.Version)
            {
                Write-Verbose -Message ($this.localizedData.ShouldBeLatest -f $this.Name, $latestVersion)

                $returnValue.Latest = $false
            }
            else
            {
                Write-Verbose -Message ($this.localizedData.IsLatest -f $this.Name, $latestVersion)

                $returnValue.Latest = $true
            }
        }

        if ($null -eq $resources)
        {
            Write-Verbose -Message ($this.localizedData.ResourceNotInstalled -f $this.Name)
        }
        else
        {
            $returnValue.Ensure = [Ensure]::Present
            if ($currentState.ContainsKey('SingleInstance') -and $this.SingleInstance)
            {
                if ($resources.Count -ne 1)
                {
                    Write-Verbose -Message ($this.localizedData.ShouldBeSingleInstance -f $this.Name, $resources.Count)

                    $returnValue.SingleInstance = $false
                }
                else
                {
                    Write-Verbose -Message ($this.localizedData.IsSingleInstance -f $this.Name)

                    $returnValue.SingleInstance = $true
                }
            }

            if ($currentState.ContainsKey('Latest') -and $this.Latest -eq $true)
            {
                $latestVersion = $this.GetLatestVersion()

                if ($latestVersion -notin $resources.Version)
                {
                    Write-Verbose -Message ($this.localizedData.ShouldBeLatest -f $this.Name, $latestVersion)

                    $returnValue.Latest = $false
                }
                else
                {
                    Write-Verbose -Message ($this.localizedData.IsLatest -f $this.Name, $latestVersion)

                    $returnValue.Latest = $true
                }

                if ($currentState.ContainsKey('RemoveNonCompliantVersions'))
                {
                    $versioningMet = $this.TestVersioning($resources, 'Latest')

                    $returnValue.RemoveNonCompliantVersions = $versioningMet
                }
            }

            if ($currentState.ContainsKey('MinimumVersion'))
            {
                foreach ($resource in $resources)
                {
                    if ($resource.version -ge [version]$this.MinimumVersion)
                    {
                        $returnValue.MinimumVersion = $this.MinimumVersion

                        Write-Verbose -Message ($this.localizedData.MinimumVersionMet -f $this.Name, $returnValue.MinimumVersion)

                        break
                    }
                }

                if ([System.String]::IsNullOrEmpty($returnValue.MinimumVersion))
                {
                    $returnValue.MinimumVersion =  $($resources | Sort-Object Version)[0].Version

                    Write-Verbose -Message ($this.localizedData.MinimumVersionExceeded -f $this.Name, $this.MinimumVersion, $returnValue.MinimumVersion)
                }

                if ($currentState.ContainsKey('RemoveNonCompliantVersions'))
                {
                    $versioningMet = $this.TestVersioning($resources, 'MinimumVersion')

                    $returnValue.RemoveNonCompliantVersions = $versioningMet
                }
            }

            if ($currentState.ContainsKey('RequiredVersion'))
            {
                if ($this.RequiredVersion -in $resources.Version)
                {
                    $returnValue.RequiredVersion = $this.RequiredVersion

                    Write-Verbose -Message ($this.localizedData.RequiredVersionMet -f $this.Name, $returnValue.RequiredVersion)
                }

                if ($currentState.ContainsKey('RemoveNonCompliantVersions'))
                {
                    $versioningMet = $this.TestVersioning($resources, 'RequiredVersion')

                    $returnValue.RemoveNonCompliantVersions = $versioningMet
                }
            }

            if ($currentState.ContainsKey('MaximumVersion'))
            {
                foreach ($resource in $resources)
                {
                    if ($resource.version -le [version]$this.MaximumVersion)
                    {
                        $returnValue.MaximumVersion = $this.MaximumVersion

                        Write-Verbose -Message ($this.localizedData.MaximumVersionMet -f $this.Name, $returnValue.MaximumVersion)

                        break
                    }
                }

                if ([System.String]::IsNullOrEmpty($returnValue.MaximumVersion))
                {
                    $returnValue.MaximumVersion =  $($resources | Sort-Object Version -Descending)[0].Version

                    Write-Verbose -Message ($this.localizedData.MaximumVersionExceeded -f $this.Name, $this.MaximumVersion, $returnValue.MaximumVersion)
                }

                if ($currentState.ContainsKey('RemoveNonCompliantVersions'))
                {
                    $versioningMet = $this.TestVersioning($resources, 'MaximumVersion')

                    $returnValue.RemoveNonCompliantVersions = $versioningMet
                }
            }
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

        if ($powerShellGet.Version -lt [version]'1.6.0' -and $this.AllowPrerelease)
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

        if ($this.Ensure -eq 'Absent' -and ($this.MinimumVersion -or $this.MaximumVersion -or $this.Latest))
        {
            $errorMessage = $this.localizedData.EnsureAbsentWithVersioning

            New-InvalidArgumentException -ArgumentName 'Ensure' -Message $errorMessage
        }

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
    hidden [Version] GetLatestVersion()
    {
        Write-Verbose -Message ($this.LocalizedData.GetLatestVersion -f $this.Name)
        $resource = $this.FindResource()

        Write-Verbose -Message ($this.LocalizedData.FoundLatestVersion -f $this.Name, $resource.Version)

        return $resource.Version
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

    <#
        Tests whether the repository the resource will install from is trusted and if not if Force is set
    #>
    hidden [void] TestRepository ()
    {
        if (-not $this.Force)
        {
            $resource = Find-Module -Name $this.Name

            $resourceRepository = Get-PSRepository -Name $resource.Repository

            if ($resourceRepository.InstallationPolicy -eq  'Untrusted')
            {
                $errorMessage = $this.localizedData.UntrustedRepositoryWithoutForce

                New-InvalidArgumentException -Message ($errorMessage -f ($resourceRepository.Name)) -ArgumentName 'Force'
            }
        }
    }

    <#
        Find the latest resource on a PSRepository
    #>
    hidden [PSCustomObject] FindResource()
    {
        $params = $this | Get-DscProperty -ExcludeName @('Latest','SingleInstance','Ensure', 'SkipPublisherCheck', 'Force', 'RemoveNonCompliantVersions') -Type Key,Optional -HasValue
        return Find-Module @params
    }

    hidden [void] InstallResource()
    {
        $params = $this | Get-DscProperty -ExcludeName @('Latest','SingleInstance','Ensure','RemoveNonCompliantVersions') -Type Key,Optional -HasValue
        Install-Module @params
    }

    <#
        Uninstall the given resource
    #>
    hidden [void] UninstallResource ([System.Management.Automation.PSModuleInfo]$resource)
    {
        $params = $this | Get-DscProperty -ExcludeName @('Latest','SingleInstance','Ensure', 'SkipPublisherCheck', 'RemoveNonCompliantVersions','MinimumVersion', 'MaximumVersion', 'RequiredVersion') -Type Optional -HasValue
        $params.RequiredVersion = $resource.Version

        Write-Verbose -Message ($this.localizedData.UninstallModule -f $resource.Name,$resource.Version)

        $resource | Uninstall-Module @params
    }

    <#
        Checks whether all the installed resources meet the given versioning requirements of either MinimumVersion, MaximumVersion, or RequiredVersion
    #>
    hidden [System.Boolean] TestVersioning ([System.Management.Automation.PSModuleInfo[]] $resources, [System.String] $requirement)
    {

        Write-Verbose -Message ($this.localizedData.testversioning -f $requirement)
        $return = $true

        switch ($requirement) {
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
                        Write-Verbose -Message ($this.localizedData.InstalledResourceDoesNotMeetMinimumVersion -f ($this.Name, $resource.Version, $this.MaximumVersion))

                        $return = $false
                    }
                }
            }
            'RequiredVersion' {
                foreach ($resource in $resources)
                {
                    if ($resource.Version -ne [Version]$this.MaximumVersion)
                    {
                        Write-Verbose -Message ($this.localizedData.InstalledResourceDoesNotMeetRequiredVersion -f ($this.Name, $resource.Version, $this.RequiredVersion))

                        $return = $false
                    }
                }
            }
            'Latest' {
                $latestVersion = $this.GetLatestVersion()
                $nonCompliantVersions = ($resources | Where-Object {$_.Version -ne $latestVersion}).Count
                if ($nonCompliantVersions -gt 1)
                {
                    Write-Verbose -Message ($this.localizedData.InstalledResourcesDoNotMeetLatestVersion -f ($nonCompliantVersions, $this.Name))

                    $return = $false
                }
            }
        }

        return $return
    }
}
