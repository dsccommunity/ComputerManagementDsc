# culture="en-US"
ConvertFrom-StringData -StringData @'
    GettingEventlogLogSize              = The current Eventlog size for '{0}' is '{1}'.
    GettingEventlogName                 = The current Eventlog is '{0}'.
    GettingEventlogIsEnabled            = The current state for Eventlog '{0}' is '{1}'.
    GettingEventlogLogMode              = The current Logmode for Eventlog '{0}' is '{1}'.
    GettingEventlogSecurityDescriptor   = The current SecurityDescriptor for Eventlog '{0}' is '{1}'.
    GettingEventlogLogFilePath          = The current LogfilePath for Eventlog '{0}' is '{1}'.
    SettingEventlogLogMode              = Setting the LogMode for Eventlog from '{0}' to '{1}'.
    SettingEventlogLogSize              = Setting the LogSize for Eventlog from '{0}' to '{1}'.
    SettingEventlogSecurityDescriptor   = Setting the SecurityDescriptor for Eventlog from '{0}' to '{1}'.
    SettingEventlogIsEnabled            = Setting the IsEnabled configuration for Eventlog from '{0}' to '{1}'.
    SettingEventlogLogFilePath          = Setting the LogFilePath for Eventlog from '{0}' to '{1}'.
    WinEventlogLogSizeAlreadySetMessage = LogSize already set to {0} for Eventlog {1}.
    WinEventlogLogModeAlreadySetMessage = LogMode already set to {0} for Eventlog {1}.
    UpdateWinEventlogLogSizeSuccess     = Updating LogSize for Eventlog '{0}' to '{1}' successfully.
    UpdateWinEventlogLogSizeFailed      = Updating LogSize for Eventlog '{0}' to '{1}' failed.
    UpdateWinEventlogLogModeSuccess     = Updating LogMode for Eventlog '{0}' to '{1}' successfully.
    UpdateWinEventlogLogModeFailed      = Updating LogMode for Eventlog '{0}' to '{1}' failed.
    TestingWinEventlogLogSize           = Testing the current LogSize for Eventlog '{0}' is '{1}'.
    TestingWinEventlogLogMode           = Testing the current LogMode for Eventlog '{0}' is '{1}'.
'@
