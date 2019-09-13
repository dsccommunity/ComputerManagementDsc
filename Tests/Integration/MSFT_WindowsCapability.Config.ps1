# Integration Test Config Template Version: 1.0.0
configuration MSFT_WindowsCapability_Default
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        WindowsCapability Integration_Test
        {
            Name   = 'XPS.Viewer~~~~0.0.1.0'
            Ensure = 'Absent'
            Online = $true
        }
    }
}

configuration MSFT_WindowsCapability_EnableCapability_XPSViewer
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        WindowsCapability Integration_Test
        {
            Name   = 'XPS.Viewer~~~~0.0.1.0'
            Ensure = 'Present'
            Online = $true
        }
    }
}

configuration MSFT_WindowsCapability_DisableCapability_XPSViewer
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        WindowsCapability Integration_Test
        {
            Name   = 'XPS.Viewer~~~~0.0.1.0'
            Ensure = 'Absent'
            Online = $true
        }
    }
}
