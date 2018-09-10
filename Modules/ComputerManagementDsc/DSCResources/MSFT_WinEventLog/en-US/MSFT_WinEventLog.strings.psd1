# culture      ="en-US"
ConvertFrom-StringData -StringData @'
    GettingEventlogLogSize                      = The current Eventlog size for '{0}' is '{1}'.
    GettingEventlogName                         = The current Eventlog is '{0}'.
    GettingEventlogIsEnabled                    = The current state for Eventlog '{0}' is '{1}'.
    GettingEventlogLogMode                      = The current Logmode for Eventlog '{0}' is '{1}'.
    GettingEventlogLogModeRetention             = The current Retention for Eventlog '{0}' is '{1}'.
    GettingEventlogSecurityDescriptor           = The current SecurityDescriptor for Eventlog '{0}' is '{1}'.
    GettingEventlogLogFilePath                  = The current LogfilePath for Eventlog '{0}' is '{1}'.
    SettingEventlogLogMode                      = Setting the LogMode for Eventlog '{0}' to '{1}' with MaximumSize '{2}'.
    SettingEventlogLogRetention                 = Setting the Log Retention for Eventlog '{0}' with LogMode '{1}' to '{2}' days.
    SettingEventlogLogSize                      = Setting the LogSize for Eventlog '{0}' to '{1}'.
    SettingEventlogSecurityDescriptor           = Setting the SecurityDescriptor for Eventlog '{0}' to '{1}'.
    SettingEventlogIsEnabled                    = Setting the IsEnabled configuration for Eventlog '{0}' to '{1}'.
    SettingEventlogLogFilePath                  = Setting the LogFilePath for Eventlog '{0}' to '{1}'.
    WinEventlogLogSizeAlreadySetMessage         = LogSize already set to {0} for Eventlog {1}.
    WinEventlogLogModeAlreadySetMessage         = LogMode already set to {0} for Eventlog {1}.
    TestingWinEventlogLogSize                   = Testing the given LogSize '{1}' for Eventlog '{0}'.
    TestingWinEventlogLogMode                   = Testing the given LogMode '{1}' for Eventlog '{0}'.
    TestingWinEventlogLogRetention              = Testing the given Retention '{1}' days for Eventlog '{0}' in Logmode 'AutoBackup'.
    TestingWinEventlogIsEnabled                 = Testing the given LogSize '{1}' for Eventlog '{0}'.
    TestingWinEventlogSecurityDescriptor        = Testing the given LogSize '{1}' for Eventlog '{0}'.
    TestingWinEventlogLogFilePath               = Testing the given LogSize '{1}' for Eventlog '{0}'.
    SettingWinEventlogMaximumSizeInBytesSuccess = Updating MaximumSizeInBytesFailed for Eventlog '{0}' to '{1}' successfully.
    SettingWinEventlogMaximumSizeInBytesFailed  = Updating MaximumSizeInBytesFailed for Eventlog '{0}' to '{1}' failed.
    SettingWinEventlogSecurityDescriptorSuccess = Updating SecurityDescriptor for Eventlog '{0}' to '{1}' successfully.
    SettingWinEventlogSecurityDescriptorFailed  = Updating SecurityDescriptor for Eventlog '{0}' to '{1}' failed.
    SettingWinEventlogLogModeSuccess            = Updating LogMode for Eventlog '{0}' to '{1}' successfully.
    SettingWinEventlogLogModeFailed             = Updating LogMode for Eventlog '{0}' to '{1}' failed.
    SettingWinEventlogIsEnabledSuccess          = Updating IsEnabled for Eventlog '{0}' to '{1}' successfully.
    SettingWinEventlogIsEnabledFailed           = Updating IsEnabled for Eventlog '{0}' to '{1}' failed.
    SettingWinEventlogLogFilePathSuccess        = Updating LogFilePath for Eventlog '{0}' to '{1}' successfully.
    SettingWinEventlogLogFilePathFailed         = Updating LogFilePath for Eventlog '{0}' to '{1}' failed.

    SetResourceNotInDesiredState                = Put the EventLog '{0}' in the desired state '{1}' with a value '{2}'.
    SetResourceIsInDesiredState                 = EventLog '{0}' is in desired state for configuration '{1}'.
'@
