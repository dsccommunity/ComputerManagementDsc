# culture      ="en-US"
ConvertFrom-StringData -StringData @'
    GettingEventlogName                        = Getting the Windows Event Log '{0}'.
    TestingWindowsEventlogSecurityDescriptor   = Setting the SecurityDescriptor for Windows Event Log '{0}' to '{1}'.
    TestingWindowsEventlogLogFilePath          = Setting the LogFilePath for Windows Event Log '{0}' to '{1}'.
    TestingEventlogMaximumSizeInBytes          = Testing the given LogSize '{1}' for Windows Event Log '{0}'.
    TestingEventlogLogMode                     = Testing the given LogMode '{1}' for Windows Event Log '{0}'.
    TestingEventlogLogRetentionDays            = Testing the given Retention '{1}' days for Windows Event Log '{0}'.
    TestingEventlogIsEnabled                   = Testing the given State '{1}' for Windows Event Log '{0}'.
    SettingEventlogLogMode                     = Setting the LogMode for Windows Event Log '{0}' to '{1}'.
    SettingEventlogLogRetentionDays            = Setting the Log Retention for Windows Event Log '{0}' to '{1}' days.
    SettingEventlogLogSize                     = Setting the LogSize for Windows Event Log '{0}' to '{1}'.
    SettingEventlogLogFilePath                 = Setting the LogFilePath for Windows Event Log '{0}' to '{1}'.
    SettingEventlogIsEnabled                   = Setting the IsEnabled configuration for Windows Event Log '{0}' to '{1}'.
    SettingEventlogSecurityDescriptor          = Setting the SecurityDescriptor configuration for Windows Event Log '{0}' to '{1}'.
    SettingWindowsEventlogRetentionDaysSuccess = Updating Logfile Retention for Windows Event Log '{0}' successfully to '{1}' days.
    SettingWindowsEventlogRetentionDaysFailed  = Updating Logfile Retention for Windows Event Log '{0}' to '{1}' failed.
    SetResourceIsInDesiredState                = Windows Event Log '{0}' is in desired state for configuration '{1}'.
    EventlogLogRetentionDaysWrongMode          = Setting the Log Retention for Windows Event Log '{0}' failed. LogMode must be AutoBackup.
    SaveWindowsEventlogSuccess                 = Saving Windows Event Log settings successful.
    SaveWindowsEventlogFailure                 = Saving Windows Event Log settings failed.
    WindowsEventLogNotFound                    = Windows Event Log '{0}' is not found.
    WindowsEventLogFound                       = Windows Event Log '{0}' was found.
'@
