<#
    .EXAMPLE
    Example script that disables the given Windows Event Log.
#>
Configuration Example
{
    Import-DSCResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        WindowsEventLog Enable-DscAnalytic
        {
            LogName             = 'Microsoft-Windows-Dsc/Analytic'
            IsEnabled           = $false
        } # End of Windows Event Log Resource
    } # End of Node
} # End of Configuration
