# Change log for ComputerManagementDsc

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- ComputerManagementDsc
  - Added build task `Generate_Conceptual_Help` to generate conceptual help
    for the DSC resource.
  - Added build task `Generate_Wiki_Content` to generate the wiki content
    that can be used to update the GitHub Wiki.

### Changed

- ComputerManagementDsc
  - Updated CI pipeline files.
  - No longer run integration tests when running the build task `test`, e.g.
    `.\build.ps1 -Task test`. To manually run integration tests, run the
    following:
    ```powershell
    .\build.ps1 -Tasks test -PesterScript 'tests/Integration' -CodeCoverageThreshold 0
    ```

### Fixed

- ScheduledTask:
  - Added missing 'NT Authority\' domain prefix when testing tasks that use
    the BuiltInAccount property - Fixes [Issue #317](https://github.com/dsccommunity/ComputerManagementDsc/issues/317)

## [8.0.0] - 2020-02-14

### Added

- Added new resource IEEnhancedSecurityConfiguration (moved from module
  xSystemSecurity).
- Added new resource UserAccountControl (moved from module
  xSystemSecurity).

### Changed

- SmbShare:
  - Add parameter ScopeName to support creating shares in a different
    scope - Fixes [Issue #284](https://github.com/dsccommunity/ComputerManagementDsc/issues/284).
- Added `.gitattributes` to ensure CRLF is used when pulling repository - Fixes
  [Issue #290](https://github.com/dsccommunity/ComputerManagementDsc/issues/290).
- SystemLocale:
  - Migrated SystemLocale from [SystemLocaleDsc](https://github.com/PowerShell/SystemLocaleDsc).
- RemoteDesktopAdmin:
  - Correct Context messages in integration tests by adding 'When'.
- WindowsCapability:
  - Change `Test-TargetResource` to remove test for valid LogPath.
- BREAKING CHANGE: Changed resource prefix from MSFT to DSC.
- Updated to use continuous delivery pattern using Azure DevOps - Fixes
  [Issue #295](https://github.com/dsccommunity/ComputerManagementDsc/issues/295).

### Deprecated

- None

### Removed

- None

### Fixed

- WindowsCapability:
  - Fix `A parameter cannot be found that matches parameter name 'Ensure'.`
    error in `Test-TargetResource` - Fixes [Issue #297](https://github.com/dsccommunity/ComputerManagementDsc/issues/297).

### Security

- None
