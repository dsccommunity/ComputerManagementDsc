# Integration Test Config Template Version: 1.0.0
Configuration DSC_SystemRestorePoint_CreateAppInstallRestorePoint
{
    Import-DscResource -ModuleName ComputerManagementDsc
    Node 'localhost'
    {
        SystemRestorePoint Integration_Test
        {
            Ensure           = 'Present'
            Description      = 'DSC Integration Test'
            RestorePointType = 'APPlICAtION_INSTALL'
        }
    }
}

Configuration DSC_SystemRestorePoint_CreateAppUninstallRestorePoint
{
    Import-DscResource -ModuleName ComputerManagementDsc
    Node 'localhost'
    {
        SystemRestorePoint Integration_Test
        {
            Ensure           = 'Present'
            Description      = 'DSC Integration Test'
            RestorePointType = 'APPlICAtION_UNINSTALL'
        }
    }
}

Configuration DSC_SystemRestorePoint_CreateDeviceDriverRestorePoint
{
    Import-DscResource -ModuleName ComputerManagementDsc
    Node 'localhost'
    {
        SystemRestorePoint Integration_Test
        {
            Ensure           = 'Present'
            Description      = 'DSC Integration Test'
            RestorePointType = 'DEVICE_DRIVER_INSTALL'
        }
    }
}

Configuration DSC_SystemRestorePoint_CreateModifySettingsRestorePoint
{
    Import-DscResource -ModuleName ComputerManagementDsc
    Node 'localhost'
    {
        SystemRestorePoint Integration_Test
        {
            Ensure           = 'Present'
            Description      = 'DSC Integration Test'
            RestorePointType = 'MODIFY_SETTINGS'
        }
    }
}

Configuration DSC_SystemRestorePoint_CreateCancelledOperationRestorePoint
{
    Import-DscResource -ModuleName ComputerManagementDsc
    Node 'localhost'
    {
        SystemRestorePoint Integration_Test
        {
            Ensure           = 'Present'
            Description      = 'DSC Integration Test'
            RestorePointType = 'CANCELLED_OPERATION'
        }
    }
}

Configuration DSC_SystemRestorePoint_DeleteAppInstallRestorePoint
{
    Import-DscResource -ModuleName ComputerManagementDsc
    Node 'localhost'
    {
        SystemRestorePoint Integration_Test
        {
            Ensure           = 'Absent'
            Description      = 'DSC Integration Test'
            RestorePointType = 'APPlICAtION_INSTALL'
        }
    }
}

Configuration DSC_SystemRestorePoint_DeleteAppUninstallRestorePoint
{
    Import-DscResource -ModuleName ComputerManagementDsc
    Node 'localhost'
    {
        SystemRestorePoint Integration_Test
        {
            Ensure           = 'Absent'
            Description      = 'DSC Integration Test'
            RestorePointType = 'APPlICAtION_UNINSTALL'
        }
    }
}

Configuration DSC_SystemRestorePoint_DeleteDeviceDriverRestorePoint
{
    Import-DscResource -ModuleName ComputerManagementDsc
    Node 'localhost'
    {
        SystemRestorePoint Integration_Test
        {
            Ensure           = 'Absent'
            Description      = 'DSC Integration Test'
            RestorePointType = 'DEVICE_DRIVER_INSTALL'
        }
    }
}

Configuration DSC_SystemRestorePoint_DeleteModifySettingsRestorePoint
{
    Import-DscResource -ModuleName ComputerManagementDsc
    Node 'localhost'
    {
        SystemRestorePoint Integration_Test
        {
            Ensure           = 'Absent'
            Description      = 'DSC Integration Test'
            RestorePointType = 'MODIFY_SETTINGS'
        }
    }
}

Configuration DSC_SystemRestorePoint_DeleteCancelledOperationRestorePoint
{
    Import-DscResource -ModuleName ComputerManagementDsc
    Node 'localhost'
    {
        SystemRestorePoint Integration_Test
        {
            Ensure           = 'Absent'
            Description      = 'DSC Integration Test'
            RestorePointType = 'CANCELLED_OPERATION'
        }
    }
}

