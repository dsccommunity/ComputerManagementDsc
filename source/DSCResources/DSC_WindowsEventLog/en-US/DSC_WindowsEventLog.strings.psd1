# Culture = "en-US"
ConvertFrom-StringData -StringData @'
    GetTargetResource                            = Getting the current state of event log '{0}'.
    GetWindowsEventLogFailure                    = Unable to retrieve event log '{0}' because it was not found.
    GetWindowsEventLogRetentionDaysFailure       = Unable to retrieve the current retention for event log '{0}' because it was not found.
    ModifySystemProvidedSecurityDescriptor       = The SecurityDescriptor property (provided by the system) will be modified to ensure alignment with the RestrictGuestAccess property.
    ModifyUserProvidedSecurityDescriptor         = The SecurityDescriptor property (provided by the user) will be modified to ensure alignment with the RestrictGuestAccess property.
    RegisterWindowsEventLogSourceFailure         = An error occurred trying to register '{1}' for event log '{0}'.
    RegisterWindowsEventLogSourceInvalidPath     = Unable to register '{1}' for event source '{0}' because the path is invalid.
    SaveWindowsEventLogFailure                   = An error occurred trying to save the properties for event log '{0}'.
    SetWindowsEventLogRestrictGuestAccessFailure = An error occurred trying to configure restricted guest access for event log '{0}'.
    SetWindowsEventLogRetentionDaysFailure       = An error occurred trying to configure retention for event log '{0}'.
    SetWindowsEventLogRetentionDaysWrongMode     = Unable to configure retention for event log '{0}' because LogMode must be set to AutoBackup.
    SetWindowsEventLogRetentionDaysNotClassic    = Unable to configure retention for event log '{0}' because it not a classic event log.
    SetTargetResourceProperty                    = Setting the '{1}' property of event log '{0}'. Current value '{2}'. Requested value '{3}'.
    TestTargetResourcePropertyNotInDesiredState  = The '{1}' property of event log '{0}' is not in the desired state. Current value '{2}'. Requested value '{3}'.
'@
