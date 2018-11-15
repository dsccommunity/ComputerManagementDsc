<#
    .EXAMPLE
    Example script that sets the Dsc Analytic Windows Event Log
    to size maximum size 4096MB, with logmode 'Retain' and enable it.
#>
Configuration Example
{
    Import-DSCResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        WindowsEventLog Enable-DscAnalytic
        {
            LogName             = 'Microsoft-Windows-Dsc/Analytic'
            IsEnabled           = $True
            LogMode             = 'Retain'
            MaximumSizeInBytes  = 4096kb
            LogFilePath         = "%SystemRoot%\System32\Winevt\Logs\Microsoft-Windows-DSC%4Analytic.evtx"
        } # End of Windows Event Log Resource
    } # End of Node
} # End of Configuration
