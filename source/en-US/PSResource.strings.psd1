<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        class PSResource.
#>

ConvertFrom-StringData -StringData @'
    PowerShellGetVersionTooLowForAllowPrerelease = The PowerShellGet '{0}' does not support AllowPrerelease. Version 1.6.6 and higher is required.
    GetLatestVersion                             = Getting latest version of resource '{0}'.
    GetLatestVersionFromRepository               = Getting latest version of resource '{0}' from repository '{1}'.
    GetLatestVersionAllowPrerelease              = Getting latest version of resource '{0}', including prerelease versions.
    FoundLatestVersion                           = Latest version of resource '{0}' found is '{1}'.
    ProxyCredentialPassedWithoutProxyUri         = Proxy Credential passed without Proxy Uri.
    UsingProxyToGetResource                      = Using proxy '{0}' to get resource '{1}'.
    ProxyorCredentialWithoutRepository           = Parameters Credential and Proxy may not be used without Repository.
    UninstallResource                            = Uninstalling resource '{0}'.
    ShouldBeSingleInstance                       = Resource '{0}' should be SingleInstance but is not.
'@
