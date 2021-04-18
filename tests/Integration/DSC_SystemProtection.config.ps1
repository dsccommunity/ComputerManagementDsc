# Integration Test Config Template Version: 1.0.0
Configuration DSC_SystemProtection_Default
{
    Import-DscResource -ModuleName ComputerManagementDsc
    Node 'localhost'
    {
        SystemProtection Integration_Test
        {
            Ensure      = 'Absent'
            DriveLetter = 'C'
        }
    }
}

Configuration DSC_SystemProtection_EnableDriveC
{
    Import-DscResource -ModuleName ComputerManagementDsc
    Node 'localhost'
    {
        SystemProtection Integration_Test
        {
            Ensure      = 'Present'
            DriveLetter = 'C'
        }
    }
}

Configuration DSC_SystemProtection_EnableDriveC_20Percent
{
    Import-DscResource -ModuleName ComputerManagementDsc
    Node 'localhost'
    {
        SystemProtection Integration_Test
        {
            Ensure      = 'Present'
            DriveLetter = 'C'
            DiskUsage   = 20
        }
    }
}

Configuration DSC_SystemProtection_ReduceDriveC_5Percent
{
    Import-DscResource -ModuleName ComputerManagementDsc
    Node 'localhost'
    {
        SystemProtection Integration_Test
        {
            Ensure      = 'Present'
            DriveLetter = 'C'
            DiskUsage   = 5
            Force       = $true
        }
    }
}

Configuration DSC_SystemProtection_AutoRestorePoints_Zero
{
    Import-DscResource -ModuleName ComputerManagementDsc
    Node 'localhost'
    {
        SystemProtection Integration_Test
        {
            Ensure    = 'Present'
            Frequency = 0
        }
    }
}
