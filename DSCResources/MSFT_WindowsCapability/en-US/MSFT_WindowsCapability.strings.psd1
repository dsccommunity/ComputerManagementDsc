# culture      ="en-US"
ConvertFrom-StringData -StringData @'
    SetResourceIsInDesiredState    = Windows Capability '{0}' is in desired state.
    SetResourceIsNotInDesiredState = Windows Capability '{0}' is not in desired state.
    GetTargetResourceStartMessage  = Begin executing Get functionality on the {0} Windows Capability.
    GetTargetResourceEndMessage    = End executing Get functionality on the {0} Windows Capability.
    SetTargetResourceStartMessage  = Begin executing Set functionality on the {0} Windows Capability.
    SetTargetResourceEndMessage    = End executing Set functionality on the {0} Windows Capability.
    TestTargetResourceStartMessage = Begin executing Test functionality on the {0} Windows Capability.
    TestTargetResourceEndMessage   = End executing Test functionality on the {0} Windows Capability.
'@
