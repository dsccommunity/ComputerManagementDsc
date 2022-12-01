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
        Specifies the URI of the proxy to connect to this PSResourceRepository.

    .PARAMETER ProxyCredential
        Specifies the Credential to connect to the PSResourceRepository proxy.

    .PARAMETER InstallationPolicy
        Specifies the installation policy. Valid values are  'Trusted'
        or 'Untrusted'. The default value is 'Untrusted'.

    .PARAMETER PackageManagementProvider
        Specifies a OneGet package provider. Default value is 'NuGet'.

    .PARAMETER Default
        Specifies whether to set the default properties for the default PSGallery PSRepository.
        Default may only be used in conjunction with a PSRepositoryResource named PSGallery.
        The properties SourceLocation, ScriptSourceLocation, PublishLocation, ScriptPublishLocation, Credential,
        and PackageManagementProvider may not be used in conjunction with Default.
        When the Default parameter is used, properties are not enforced when PSGallery properties are changed outside of Dsc.

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

    [DscProperty()]
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
    $InstallationPolicy

    [DscProperty()]
    [System.String]
    $PackageManagementProvider

    [DscProperty()]
    [Nullable[System.Boolean]]
    $Default

    PSResourceRepository () : base ()
    {
        # These properties will not be enforced.
        $this.ExcludeDscProperties = @(
            'Name',
            'Default'
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

    hidden [void] Modify([System.Collections.Hashtable] $properties)
    {
        $params = @{
            Name = $this.Name
        }

        if ($properties.ContainsKey('Ensure') -and $properties.Ensure -eq 'Absent' -and $this.Ensure -eq 'Absent')
        {
            # Ensure was not in desired state so the repository should be removed
            Write-Verbose -Message ($this.localizedData.RemoveExistingRepository -f $this.Name)

            Unregister-PSRepository @params

            return
        }
        elseif ($properties.ContainsKey('Ensure') -and $properties.Ensure -eq 'Present' -and $this.Ensure -eq 'Present')
        {
            # Ensure was not in desired state so the repository should be created
            $register = $true

        }
        else
        {
            # Repository exist but one or more properties are not in desired state
            $register = $false
        }

        foreach ($key in $properties.Keys.Where({ $_ -ne 'Ensure' }))
        {
            $params[$key] = $properties.$key
        }

        if ($register)
        {
            if ($this.Name -eq 'PSGallery')
            {
                Write-Verbose -Message ($this.localizedData.RegisterDefaultRepository -f $this.Name)

                Register-PSRepository -Default

                #* The user may have specified Proxy & Proxy Credential, or InstallationPolicy params
                Set-PSRepository @params

            }
            else
            {
                if ([System.String]::IsNullOrEmpty($this.SourceLocation))
                {
                    $errorMessage = $this.LocalizedData.SourceLocationRequiredForRegistration

                    New-InvalidArgumentException -ArgumentName 'SourceLocation' -Message $errorMessage
                }

                if ($params.Keys -notcontains 'SourceLocation')
                {
                    $params['SourceLocation'] = $this.SourceLocation
                }

                Write-Verbose -Message ($this.localizedData.RegisterRepository -f $this.Name, $this.SourceLocation)

                Register-PSRepository @params
            }
        }
        else
        {
            Write-Verbose -Message ($this.localizedData.UpdateRepository -f $this.Name, $this.SourceLocation)

            Set-PSRepository @params
        }

        foreach ($key in $properties.Keys.Where({ $_ -ne 'Ensure' }))
        {
            Write-Verbose -Message ($this.localizedData.PropertyOutOfSync -f $key, $($this.$key))

            $params[$key] = $properties.$key
        }

        $moduleToInstall = Find-Module @params

        $this.InstallResource($moduleToInstall.version)
    }

    hidden [System.Collections.Hashtable] GetCurrentState1 ([System.Collections.Hashtable] $properties)
    {
        $returnValue = @{
            Ensure         = [Ensure]::Absent
            Name           = $this.Name
            SourceLocation = $this.SourceLocation
            Default        = $this.Default
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
        }
        else
        {
            Write-Verbose -Message ($this.localizedData.RepositoryNotFound -f $this.Name)
        }

        return $returnValue
    }

    hidden [System.Collections.Hashtable] GetCurrentState ([System.Collections.Hashtable] $properties)
    {
        $returnValue = @{
            Ensure         = [Ensure]::Absent
            Name           = $this.Name
        }

        Write-Verbose -Message ($this.localizedData.GetTargetResourceMessage -f $this.Name)

        $repository = Get-PSRepository -Name $this.Name -ErrorAction SilentlyContinue

        $excludeProperties = $this.ExcludeDscProperties + 'Ensure'
        $currentState = $this | Get-DscProperty -ExcludeName $excludeProperties -Type @('Key', 'Optional', 'Mandatory') -HasValue

        if ($repository)
        {
            $returnValue.Ensure = [Ensure]::Present
            $currentState.Keys | ForEach-Object -Process {
                Write-Verbose -Message ($this.localizedData.CurrentState -f $this.Name, $_, $repository.$_)

                if ($_ -eq 'InstallationPolicy')
                {
                    $returnValue.$_ = [InstallationPolicy]::$($repository.$_)
                }
                else
                {
                    $returnValue.$_ = $repository.$_
                }
            }
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

        $assertBoundParameterParameters = @{
            BoundParameterList = $properties
            MutuallyExclusiveList1 = @(
                'Default'
            )
            MutuallyExclusiveList2 = @(
                'SourceLocation'
                'PackageSourceLocation'
                'ScriptPublishLocation'
                'ScriptSourceLocation'
                'Credential'
                'PackageManagementProvider'
            )
        }

        Assert-BoundParameter @assertBoundParameterParameters

        if ($this.Name -eq 'PSGallery')
        {
            if (-not $this.Default -and $this.Ensure -eq 'Present')
            {
                $errorMessage = $this.localizedData.NoDefaultSettingsPSGallery

                New-InvalidArgumentException -ArgumentName 'Default' -Message $errorMessage
            }
        }
        else
        {
            if ($this.Default)
            {
                $errorMessage = $this.localizedData.DefaultSettingsNoPSGallery

                New-InvalidArgumentException -ArgumentName 'Default' -Message $errorMessage
            }
        }

        if ($this.ProxyCredental -and (-not $this.Proxy))
        {
            $errorMessage = $this.localizedData.ProxyCredentialPassedWithoutProxyUri

            New-InvalidArgumentException -ArgumentName 'ProxyCredential' -Message $errorMessage
        }
    }
}
