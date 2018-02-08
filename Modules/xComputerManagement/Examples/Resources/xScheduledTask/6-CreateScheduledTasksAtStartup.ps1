<#
    .EXAMPLE
    This example creates a scheduled task called 'Test task Startup' in the folder
    task folder 'MyTasks' that starts a new powershell process when the machine
    is started up repeating every 15 minutes for 8 hours.

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
        xScheduledTask xScheduledTaskStartupAdd
        {
            TaskName           = 'Test task Startup'
            TaskPath           = '\MyTasks'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType       = 'AtStartup'
            RepeatInterval     = '00:15:00'
            RepetitionDuration = '08:00:00'
        }
    }
}
