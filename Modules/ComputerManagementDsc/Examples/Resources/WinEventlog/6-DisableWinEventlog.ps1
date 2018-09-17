<#
    .EXAMPLE
    Example script that disables the given Eventlog
#>
Configuration Example
{
    Import-DSCResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        WinEventLog Enable-DscAnalytic
        {
            LogName             = 'Microsoft-Windows-Dsc/Analytic'
            IsEnabled           = $false
        } # End of WinEventLog Resource
    } # End of Node
} # End of Configuration
