<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        class PSResource.
#>

ConvertFrom-StringData -StringData @'
    PowerShellGetVersionTooLowForAllowPrerelease = The installed version of PowerShellGet does not support AllowPrerelease.
    GetLatestVersion = 'Getting latest version of resource '{0}'.
    GetLatestVersionFromRepository = 'Getting latest version of resource '{0}' from repository '{1}'.
    GetLatestVersionAllowPrerelease = 'Getting latest version of resource '{0}', including prerelease versions.
    FoundLatestVersion = 'Latest version of resource '{0}' found is '{1}'.
'@
