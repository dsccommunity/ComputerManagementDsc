# Localized resources for WindowsOptionalFeature

ConvertFrom-StringData @'
    GetTargetResourceMessage = Getting the current state of the SMB share '{0}'.
    TestTargetResourceMessage = Determining if the SMB share '{0}' is in the desired state.
    ShareNotFound = Unable to find a SMB share with the name '{0}'.
    IsPresent = The SMB share with the name '{0}' exist.
    IsAbsent = The SMB share with the name '{0}' does not exist.
    EvaluatingProperties = Evaluating the properties of the SMB share.
    UpdatingProperties = Updating properties on the SMB share that are not in desired state.
    RemoveShare = Removing the SMB share with the name '{0}'.
    CreateShare = Creating a SMB share with the name '{0}'.
    RecreateShare = Dropping and recreating share with name '{0}'
    RecreateShareError = Failed to recreate share with name '{0}'. The error was: '{1}'.
    NoRecreateShare = The share with name '{0}' exists on path {1}, desired state is on path {2}. Set Force = $true to allow drop and recreate of the share.
    RevokeAccess = Revoking granted permission for account '{0}' on the SMB share with the name '{1}'.
    UnblockAccess = Revoking denied permission for account '{0}' on the SMB share with the name '{1}'.
    GrantAccess = Granting '{0}' permission for account '{1}' on the SMB share with the name '{2}'.
    DenyAccess = Denying permission for account '{0}' on the SMB share with the name '{1}'.
    InvalidAccessParametersCombination = Not allowed to have all access permission parameters set to empty collections. Must either remove the access permission parameters completely, or add at least one member to one of the access permission parameters.
'@
