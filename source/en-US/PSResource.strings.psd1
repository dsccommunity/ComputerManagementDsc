<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        class PSResource.
#>

ConvertFrom-StringData -StringData @'
    PowerShellGetVersionTooLowForAllowPrerelease  = The installed version of PowerShellGet does not support AllowPrerelease. Version 1.6.6 and higher is required.
    GetLatestVersion                              = Getting latest version of resource '{0}'.
    GetLatestVersionFromRepository                = Getting latest version of resource '{0}' from repository '{1}'.
    GetLatestVersionAllowPrerelease               = Getting latest version of resource '{0}', including prerelease versions.
    FoundLatestVersion                            = Latest version of resource '{0}' found is '{1}'.
    ProxyCredentialPassedWithoutProxyUri          = Proxy Credential passed without Proxy Uri.
    UsingProxyToGetResource                       = Using proxy '{0}' to get resource '{1}'.
    ProxyorCredentialWithoutRepository            = Parameters Credential and Proxy may not be used without Repository.
    ShouldBeSingleInstance                        = Resource '{0}' should be SingleInstance but is not. '{1}' instances of the resource are installed.
    IsSingleInstance                              = Resource '{0}' is SingleInstance.
    UntrustedRepositoryWithoutForce               = Untrusted repository '{0}' requires the Force parameter to be true.
    UninstallResource                             = Uninstalling resource '{0}' version '{1}'.
    ShouldBeLatest                                = Resource '{0}' should have latest version '{1}' installed but doesn't.
    IsLatest                                      = Resource '{0}' has latest version '{1}' installed.
    ResourceNotInstalled                          = Resource '{0}' is not present on system.
    MinimumVersionMet                             = Resource '{0}' meets criteria of MinimumVersion '{1}'.
    MinimumVersionExceeded                        = Resource '{0}' exceeds criteria of MinimumVersion '{1}', with version '{2}'.
    MaximumVersionMet                             = Resource '{0}' meets criteria of MaximumVersion '{1}'.
    MaximumVersionExceeded                        = Resource '{0}' exceeds criteria of MaximumVersion '{1}', with version '{2}'.
    RequiredVersionMet                            = Resource '{0}' meets criteria of RequiredVersion '{1}'.
    TestVersionRequirement                        = Testing if installed resources meets versioning requirement of '{0}'.
    InstalledResourceDoesNotMeetMinimumVersion    = Installed resource '{0}' with version '{1}' does not meet MinimumVersion requirement of '{2}'.
    InstalledResourceDoesNotMeetMaximumVersion    = Installed resource '{0}' with version '{1}' does not meet MaximumVersion requirement of '{2}'.
    InstalledResourceDoesNotMeetRequiredVersion   = Installed resource '{0}' with version '{1}' does not meet RequiredVersion requirement of '{2}'.
    InstalledResourcesDoNotMeetLatestVersion      = '{0}' installed resources of resource '{1}' do not meet Latest requirement.
    EnsureAbsentWithVersioning                    = Parameters MinimumVersion, MaximumVersion, or Latest may not be used when Ensure is Absent.
    TestRepositoryInstallationPolicy              = Testing repository installation policy.
    FindResource                                  = Finding resource '{0}'.
    InstallResource                               = Installing resource '{0}'.
    GetInstalledResource                          = Getting all installed versions of resource '{0}'.
    GetRequiredVersionFromVersionRequirementError = GetRequiredVersionFromVersionRequirement should only be used with 'MinimumVersion', 'MaximumVersion, and 'RequiredVersion', not '{0}'.
    NonCompliantVersionCount                      = Found '{0}' instances of resource '{1}' that do not match version requirement of '{2}'.
    RemoveNonCompliantVersionsWithoutVersioning   = Argument 'RemoveNonCompliantVersions' requires one of parameters 'MinimumVersion', 'MaximumVersion', 'RequiredVersion' or 'Latest'.
    VersionRequirementFound                       = Version requirement for resource '{0}' is '{1}'.
    UninstallNonCompliantResource                 = Uninstalling version '{0}' of resource '{1}' because it does not match version requirement of '{2}'.
    # GetMinimumAndMaximumInstalledVersion strings
    MinimumAndMaximumVersionMet                   = Installed resource '{0}' version '{1}' meets MinimumVersion and MaximumVersion requirements.
    # Modify() strings
    ResourceShouldBeAbsentRequiredVersion         = Resource '{0}' version '{1}' should be Absent but is Present.
    ResourceShouldBeAbsent                        = Resource '{0}' should be Absent but is Present.
    ResourceShouldBePresent                       = Resource '{0}' should be Present but is Absent.

'@
