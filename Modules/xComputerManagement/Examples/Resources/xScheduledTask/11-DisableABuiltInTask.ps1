<#
    .EXAMPLE
    This example disables the built-in scheduled task called
    'CreateExplorerShellUnelevatedTask'.
#>
Configuration Example
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost'
    )

    Import-DscResource -ModuleName xComputerManagement

    Node $NodeName
    {
        xScheduledTask DisableCreateExplorerShellUnelevatedTask
        {
            TaskName            = 'CreateExplorerShellUnelevatedTask'
            TaskPath            = '\'
            Enable              = $false
        }
    }
}
