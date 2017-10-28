<#
    .EXAMPLE
    This example creates a scheduled task called 'Test task Logon' in the folder
    task folder 'MyTasks' that starts a new powershell process when the machine
    is logged on repeating every 15 minutes for 8 hours.
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
        xScheduledTask xScheduledTaskLogonAdd
        {
            TaskName           = 'Test task Logon'
            TaskPath           = '\MyTasks'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType       = 'AtLogOn'
            RepeatInterval     = '00:15:00'
            RepetitionDuration = '08:00:00'
        }
    }
}
