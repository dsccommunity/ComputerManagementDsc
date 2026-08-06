# Description

The resource allows you to configure a computer by changing its name and
description and modifying its Active Directory domain or workgroup membership.

## Parameters

### ReuseExistingComputerAccount

When joining a domain, if a computer account with the same name already exists:

- **Not specified or `$false`** (default): The existing computer account is
  deleted and recreated.
- **`$true`**: The existing computer account is reused. This preserves the
  machine SID, group memberships, GPO links, and other AD attributes. If no
  existing account is found, a new one is created.
