---
description: Guidelines for a consistent changelog.
applyTo: "CHANGELOG.md"
version: 1.0.0
---

# Changelog Guidelines

- Always update the `## [Unreleased]` section in `CHANGELOG.md`
- One section per change type (`Added`, `Changed`, `Fixed`) under `## [Unreleased]`
- Use Keep a Changelog format
- Describe changes briefly; ≤2 items per change type
- Reference issues using format
  ` - Fixes [Issue #<issue_number>](https://github.com/dsccommunity/ComputerManagementDsc/issues/<issue_number>)`
  - capital `I` in `Issue`; `Fixes` prefix; full stop after closing parenthesis
- No empty lines between list items in same section
- No duplicate sections or items in `## [Unreleased]`; skip if entry already exists
- Mark breaking changes with `BREAKING CHANGE:` prefix on the entry in `### Changed`
  or `### Fixed`
- Group multiple changes for the same resource using two-level indentation:

  ```markdown
  - ResourceName
    - First change description for this resource - Fixes [Issue #<issue_number>](https://github.com/dsccommunity/ComputerManagementDsc/issues/<issue_number>)
    - Second change description for this resource - Fixes [Issue #<issue_number>](https://github.com/dsccommunity/ComputerManagementDsc/issues/<issue_number>)
  ```
