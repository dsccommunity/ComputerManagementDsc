# culture      ="en-US"
ConvertFrom-StringData -StringData @'
    SetResourceIsInDesiredState    = Windows Capability '{0}' is in desired state.
    SetResourceIsNotInDesiredState = Windows Capability '{0}' is not in desired state.
    GetTargetResourceStartMessage  = Begin executing Get functionality on Windows Capability '{0}'.
    GetTargetResourceEndMessage    = End executing Get functionality on Windows Capability '{0}'.
    SetTargetResourceStartMessage  = Begin executing Set functionality on Windows Capability '{0}'.
    SetTargetRemoveMessage         = Executing Remove functionality on Windows Capability '{0}'.
    SetTargetAddMessage            = Executing Add functionality on Windows Capability '{0}'.
    TestTargetResourceStartMessage = Begin executing Test functionality on Windows Capability '{0}'.
    CapabilityNameFound            = Specified Windows Capability '{0}' found.
    CapabilityNameNotFound         = Specified Windows Capability '{0}' not found.
'@
