ConvertFrom-StringData @'
# General
Success=Test Successful!
Failure=Test Failed! Expected property '{0}' to be '{1}', but it is actually '{2}'. System not in desired state!
InDesiredState=Resource is in desired state!
NotInDesiredState=System is not in the desired state!

# Get-TargetResource
GetTargetResourceStartVerboseMessage=Executing Get function on xComputer resource.
GetTargetResourceEndVerboseMessage=Finished executing Get function on xComputer resource.

# Test-TargetResource
TestTargetResourceStartVerboseMessage=Executing Test function on xComputer resource.
TestTargetResourceEndVerboseMessage=Finished executing Test function on xComputer resource. Result: {0}
TestNameIsValidStart=Testing if name '{0}' is a valid name.
TestNameIsValidSuccess='{0}' is a valid name. Continuing.
TestNameIsValidFailureError='{0}' is not a valid computer name! Reason: {1}
TestNameIsValidFailureDisallowedCharacters=The name has one or more of the following disallowed characters: backslash (\), slash mark (/), colon (:), asterisk (*), question mark (?), quotation mark ("), less than sign (<), greater than sign (>), vertical bar (|).
TestNameIsValidFailureStartsWithPeriod=The name starts with a period. A computer name cannot start with a period.
TestNameIsValidFailureOnlyNumbers=The name only consists of numbers. A computer name must have a character in it.
TestNameIsValidFailureTooLong=The name is too long, a computer name can be no longer than 15 characters.
TestNameIsValidFailureTooShort=The name is too short, a computer name needs at least 1 character.
TestNameISValidFailureWhiteSpace=The name provided is null, or consists of whitespace only. Please supply at least one character.
TestNameIsValidFailureReservedName=This name is reserved by the system.
TestNameStart=Testing current computer name is the desired name.
TestNameFailure=Current computer name is not in desired state: '{0}' -ne '{1}'
TestnameFailureCertAuth=The current computer is a certificate authority computer. You cannot change the state of a certificate authority server!
TestNameIsLocalHost=Name specified is 'localhost', Resolved name as '{0}'.
TestDomainOrWorkGroupFailure=You cannot specify both 'Domain' and 'WorkGroup' parameters. Please specify only one.
TestDomainCredentialsNotSpecifiedFailure=Please provide credentials that has the permission to join this computer to domain: '{0}'
TestDomainAlreadyMemberStart=Checking if the machine is already a member of '{0}'
TestDomainComputerNotMemberOfAny=Test failed! Computer is not a member of a domain. Expected to be a member of '{0}'.
TestWorkGroupStart=Testing if WorkGroup is in the desired state.

# Set-TargetResource
SetTargetResourceStartVerboseMessage=Executing Set Function on xComputer resource.
SetNameIsLocalHost=Name 'localhost' provided. Resolved name as '{0}'
SetNameRename=Renamed computer name to '{0}'
SetNameRenameAndJoinDomain=Renamed computer name to '{0}', and added to domain '{1}'
SetNameRenameAndJoinWorkGroup=Renamed computer name to '{0}' and added to WorkGroup '{1}'
SetDomainJoin=Added computer to domain '{0}'
SetDomainJoinNoCredential=No Credential was provided while working on a domain. Please provide credentials with sufficient rights for domain '{0}'
SetWorkGroupJoin=Added compter to workgroup '{0}'
'@
