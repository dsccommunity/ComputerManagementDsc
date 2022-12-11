<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        class PSResourceRepository.
#>

ConvertFrom-StringData -StringData @'
    GetTargetResourceMessage              = Return the current state of the repository '{0}'.
    RepositoryNotFound                    = The repository '{0}' was not found.
    RemoveExistingRepository              = Removing the repository '{0}'.
    ProxyCredentialPassedWithoutProxyUri  = Proxy Credential passed without Proxy Uri.
    RegisterRepository                    = Registering repository '{0}' with SourceLocation '{1}'.
    UpdateRepository                      = Updating repository '{0}' with SourceLocation '{1}'.
    RegisterDefaultRepository             = Registering default repository '{0}' with -Default parameter.
    SourceLocationRequiredForRegistration = SourceLocation is a required parameter to register a repository.
    NoDefaultSettingsPSGallery            = The parameter Default must be set to True for a repository named PSGallery.
    DefaultSettingsNoPSGallery            = The parameter Default may only be used with repositories named PSGallery.
'@
