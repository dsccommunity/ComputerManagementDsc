<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        class PSResource.
#>

ConvertFrom-StringData -StringData @'
    PowerShellGetVersionTooLowForAllowPrerelease = The PowerShellGet '{0}' does not support AllowPrerelease. Version 1.6.6 and higher is required.
    GetLatestVersion = Getting latest version of resource '{0}'.
    GetLatestVersionFromRepository = Getting latest version of resource '{0}' from repository '{1}'.
    GetLatestVersionAllowPrerelease = Getting latest version of resource '{0}', including prerelease versions.
    FoundLatestVersion = Latest version of resource '{0}' found is '{1}'.
    ProxyCredentialPassedWithoutProxyUri = Proxy Credential passed without Proxy Uri.
'@
