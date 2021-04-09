# Description

This resource is used to configure the settings of an event log.

## RestrictGuestAccess and Event Log DACLs

If you choose to restrict guest access to an event log, the
RestrictGuestAccess registry key will be configured and the event
log's DACL will be checked and updated to ensure the built-in
Guests group has been removed. Conversely, if you choose to
allow guest access, the registry key will be configured and the
DACL will be checked and updated to ensure the built-in Guests
group has been added.

This DACL behavior also applies if you configure your own custom
DACL via the SecurityDescriptor property and a warning will be
displayed to notify you of the change.

## RegisteredSource and Resource Files

The PowerShell cmdlets that define event log sources do not check
for the presence of the resource file on the computer and this
resource follows the same paradigm. If you choose to create your
own resource files and want to register them with the event source,
you must ensure the files have been copied to the computer via a
DSC File resource definition or equivalent.
