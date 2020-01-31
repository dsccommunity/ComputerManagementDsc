# Change log for ComputerManagementDsc

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- None

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
