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
        $params = @{
            Name = $this.Name
        }

        if ($this.Force)
        {
            $params.Force = $this.Force
        }

        if ($properties.ContainsKey('Ensure') -and $properties.Ensure -eq 'Absent' -and $this.Ensure -eq 'Absent')
        {
            #! This is broken, if any of the version req's are valid, need to correctly identify the resources to remove.
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

            $resourcesToUninstall = $this.GetInstalledResource()
            Uninstall-Module @params
        }
        elseif ($properties.ContainsKey('Ensure') -and $properties.Ensure -eq 'Present' -and $this.Ensure -eq 'Present')
        {
            #* Module does not exist at all
            $this.TestRepository()

            $this.InstallResource()
        }
        else
        {
            #* Module is installed but not in the correct state
            #* Either too many
            #* Not latest
            #* Wrong version

            $this.TestRepository()

            if ($properties.ContainsKey('SingleInstance'))
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

            if ($properties.ContainsKey('RemoveNonCompliantVersions') -and $this.RemoveNonCompliantVersions)
            {
                $installedResource = $this.GetInstalledResource()

                if ($this.MinimumVersion)
                {
                    #uninstall all non-compliant versions

                    if ($properties.ContainsKey('MinimumVersion'))
                    {
                        $this.InstallResource()
                        return
                    }

                }

                if ($this.MaximumVersion)
                {
                    #uninstall all non-compliant versions

                    if ($properties.ContainsKey('MaximumVersion'))
                    {
                        $this.InstallResource()

                        return
                    }

                }

                if ($this.RequiredVersion)
                {
                    #uninstall all non-compliant versions

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
                        #* Remove all versions because latest is not in correct state and install LatestVersion

                        $this.InstallResource()

                        return
                    }
                    else
                    {
                        #* get latest version and remove all others

                        return
                    }

                }
                return
            }

            if ($properties.ContainsKey('Latest') -and (-not $properties.ContainsKey('RemoveNonCompliantVersions')))
            {
                $this.InstallResource()

                return
            }

            $this.InstallResource()
        }
    }

    # <#
    #     Install the given version of the resource
    # #>
    # hidden [void] InstallResource([Version] $version)
    # {
    #     Write-Verbose -Message ($this.LocalizedData.GetLatestVersion -f $this.Name)
    #     $params = @{
    #         Name            = $this.Name
    #         AllowClobber    = $this.AllowClobber
    #         Force           = $this.Force
    #         RequiredVersion = $version
    #     }

    #     if (-not ([System.String]::IsNullOrEmpty($this.Repository)))
    #     {
    #         Write-Verbose -Message ($this.LocalizedData.GetLatestVersionFromRepository -f $this.Name, $this.Repository)

    #         $params.Repository = $this.Repository
    #     }

    #     if ($this.AllowPrerelease)
    #     {
    #         Write-Verbose -Message ($this.LocalizedData.GetLatestVersionAllowPrerelease -f $this.Name)

    #         $params.AllowPrerelease = $this.AllowPrerelease
    #     }

    #     if ($this.Credential)
    #     {
    #         $params.Credential = $this.Credential
    #     }

    #     if ($this.Proxy)
    #     {
    #         Write-Verbose -Message ($this.LocalizedData.UsingProxyToGetResource -f $this.Proxy, $this.Name)

    #         $params.Proxy = $this.Proxy
    #     }

    #     if ($this.ProxyCredential)
    #     {
    #         $params.ProxyCredential = $this.ProxyCredential
    #     }
    #     Write-Verbose -Message ($this.localizedData.InstallResource -f $version, $this.name)

    #     Install-Module @params
    # }

    <#
        The parameter properties will contain the key properties.
    #>
    hidden [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $properties)
    {
        $currentState = $this | Get-DscProperty -ExcludeName $this.ExcludeDscProperties -Type @('Key', 'Mandatory', 'Optional') -HasValue
        $currentState.Ensure = [Ensure]::Absent

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
            if ($currentState.ContainsKey('SingleInstance') -and $this.SingleInstance)
            {
                if ($resources.Count -ne 1)
                {
                    Write-Verbose -Message ($this.localizedData.ShouldBeSingleInstance -f $this.Name, $resources.Count)

                    $currentState.SingleInstance = $false
                    $currentState.Ensure = [Ensure]::Absent #! Resource may be absent, or SingleInstance may be greater than 1, is this still false?
                }
                else
                {
                    Write-Verbose -Message ($this.localizedData.IsSingleInstance -f $this.Name)

                    $currentState.SingleInstance = $true
                    $currentState.Ensure = [Ensure]::Present
                }
            }

            if ($currentState.ContainsKey('Latest') -and $this.Latest -eq $true)
            {
                $latestVersion = $this.GetLatestVersion()

                if ($latestVersion -notin $resources.Version)
                {
                    Write-Verbose -Message ($this.localizedData.ShouldBeLatest -f $this.Name, $latestVersion)

                    $currentState.Latest = $false
                    $currentState.Ensure = [Ensure]::Absent
                }
                else
                {
                    Write-Verbose -Message ($this.localizedData.IsLatest -f $this.Name, $latestVersion)

                    $currentState.Latest = $true
                    if (-not $currentState.ContainsKey('SingleInstance'))
                    {
                        #latest is true
                        # single instance can be true, false, or null
                        $currentState.Ensure = [Ensure]::Present
                    }
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
                    }
                    break
                }

                if ([System.String]::IsNullOrEmpty($returnValue.MinimumVersion))
                {
                    $returnValue.MinimumVersion =  $($resources | Sort-Object Version)[0].Version

                    Write-Verbose -Message ($this.localizedData.MinimumVersionExceeded -f $this.Name, $this.MinimumVersion, $returnValue.MinimumVersion)
                }

                if ($currentState.ContainsKey('RemoveNonCompliantVersions'))
                {
                    $versioningMet = $this.TestVersioning($resources, 'MinimumVersion')
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
                }
            }

            if ($currentState.ContainsKey('MaximumVersion'))
            {
                foreach ($resource in $resources)
                {
                    if ($resource.version -le [version]$this.MaximumVersion)
                    {
                        $returnValue.MinimumVersion = $this.MaximumVersion

                        Write-Verbose -Message ($this.localizedData.MaximumVersionMet -f $this.Name, $returnValue.MaximumVersion)
                    }
                    break
                }

                if ([System.String]::IsNullOrEmpty($returnValue.MinimumVersion))
                {
                    $returnValue.MinimumVersion =  $($resources | Sort-Object Version -Descending)[0].Version

                    Write-Verbose -Message ($this.localizedData.MaximumVersionExceeded -f $this.Name, $this.MaximumVersion, $returnValue.MaximumVersion)
                }

                if ($currentState.ContainsKey('RemoveNonCompliantVersions'))
                {
                    $versioningMet = $this.TestVersioning($resources, 'MaximumVersion')

                    $returnValue.RemoveNonCompliantVersions = $versioningMet
                }
            }
        }

        # $currentState = @{
        #     Name               = $this.Name
        #     Ensure             = [Ensure]::Absent
        #     Repository         = $this.Repository
        #     SingleInstance     = $False
        #     AllowPrerelease    = $False
        #     Latest             = $False
        #     AllowClobber       = $this.AllowClobber
        #     SkipPublisherCheck = $this.SkipPublisherCheck
        #     Force              = $this.Force
        # }

        # $resources = $this.GetInstalledResource()

        # if ($resources.Count -eq 1)
        # {
        #     $resource = $resources[0]
        #     $currentState.Ensure = [Ensure]::Present

        #     $version = $this.GetFullVersion($resource)
        #     $currentState.RequiredVersion = $version
        #     $currentState.MinimumVersion  = $version
        #     $currentState.MaximumVersion  = $version

        #     $currentState.SingleInstance  = $True

        #     $currentState.AllowPrerelease = $this.TestPrerelease($resource)

        #     if ($this.latest)
        #     {
        #         $currentState.Latest = $this.TestLatestVersion($version)
        #     }

        #     $this.SetSingleInstance($currentState.SingleInstance)
        # }
        # elseif ($resources.count -gt 1)
        # {
        #     #* multiple instances of resource found on system.
        #     $resourceInfo = @()

        #     foreach ($resource in $resources)
        #     {
        #         $resourceInfo += @{
        #             Version    = $this.GetFullVersion($resource)
        #             Prerelease = $this.TestPrerelease($resource)
        #         }
        #     }

        #     $currentState.Ensure          = [Ensure]::Present
        #     $currentState.RequiredVersion = ($resourceInfo | Sort-Object Version -Descending)[0].Version
        #     $currentState.MinimumVersion  = ($resourceInfo | Sort-Object Version)[0].Version
        #     $currentState.MaximumVersion  = $currentState.RequiredVersion
        #     $currentState.AllowPrerelease = ($resourceInfo | Sort-Object Version -Descending)[0].Prerelease

        #     if ($this.Latest)
        #     {
        #         $currentState.Latest          = $this.TestLatestVersion($currentState.RequiredVersion)
        #     }
        # }

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
        $params = $this | Get-DscProperty -ExcludeName @('Latest','SingleInstance','Ensure', 'SkipPublisherCheck', 'Force') -Type Key,Optional -HasValue
        return Find-Module @params
    }

    hidden [void] InstallResource()
    {
        $params = $this | Get-DscProperty -ExcludeName @('Latest','SingleInstance','Ensure') -Type Key,Optional -HasValue
        Install-Module @params
    }

    <#
        Uninstall the given resource
    #>
    hidden [void] UninstallResource ([System.Management.Automation.PSModuleInfo]$resource)
    {
        $params = $this | Get-DscProperty -ExcludeName @('Latest','SingleInstance','Ensure', 'SkipPublisherCheck') -Type Optional -HasValue

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
        }

        return $return
    }
}
