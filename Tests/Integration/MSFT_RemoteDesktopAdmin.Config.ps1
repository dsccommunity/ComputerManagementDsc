Configuration setToDenied
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node "localhost" {
        RemoteDesktopAdmin RemoteDesktopAdmin
        {
            Ensure = 'Absent'
        }
    }
}

Configuration setToAllowed
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node "localhost" {
        RemoteDesktopAdmin RemoteDesktopAdmin
        {
            Ensure = 'Present'
        }
    }
}

Configuration setToAllowedSecure
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node "localhost" {
        RemoteDesktopAdmin RemoteDesktopAdmin
        {
            Ensure         = 'Present'
            Authentication = 'Secure'
        }
    }
}

Configuration setToAllowedNonSecure
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node "localhost" {
        RemoteDesktopAdmin RemoteDesktopAdmin
        {
            Ensure         = 'Present'
            Authentication = 'NonSecure'
        }
    }
}
