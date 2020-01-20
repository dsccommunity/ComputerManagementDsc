configuration setToDenied
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost' {
        RemoteDesktopAdmin RemoteDesktopAdmin
        {
            IsSingleInstance = 'Yes'
            Ensure           = 'Absent'
        }
    }
}

configuration setToAllowed
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost' {
        RemoteDesktopAdmin RemoteDesktopAdmin
        {
            IsSingleInstance = 'Yes'
            Ensure           = 'Present'
        }
    }
}

configuration setToAllowedSecure
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost' {
        RemoteDesktopAdmin RemoteDesktopAdmin
        {
            IsSingleInstance     = 'Yes'
            Ensure               = 'Present'
            UserAuthentication   = 'Secure'
        }
    }
}

configuration setToAllowedNonSecure
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost' {
        RemoteDesktopAdmin RemoteDesktopAdmin
        {
            IsSingleInstance     = 'Yes'
            Ensure               = 'Present'
            UserAuthentication   = 'NonSecure'
        }
    }
}
