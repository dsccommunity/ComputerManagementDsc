# Change log for ComputerManagementDsc

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- None

### Changed

- SmbShare:
  - Add parameter ScopeName to support creating shares in a different
    scope. Fixes [Issue #284](https://github.com/dsccommunity/ComputerManagementDsc/issues/284)
- Added `.gitattributes` to ensure CRLF is used when pulling repository - Fixes
  [Issue #290](https://github.com/dsccommunity/ComputerManagementDsc/issues/290).
- SystemLocale:
  - Migrated SystemLocale from [SystemLocaleDsc](https://github.com/PowerShell/SystemLocaleDsc).
- RemoteDesktopAdmin:
  - Correct Context messages in integration tests by adding 'When'.

### Deprecated

- None

### Removed

- None

### Fixed

- None

### Security

- None
