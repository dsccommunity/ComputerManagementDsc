Configuration xScheduledTask_Add
{
    Import-DscResource -ModuleName xComputerManagement
    node "localhost" {
        xScheduledTask xScheduledTask_Add {
            TaskName = "Test task"
            TaskPath = "\xComputerManagement\"
            ActionExecutable = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
            ScheduleType = "Minutes"
            RepeatInterval = 15
        } 
    }
}

Configuration xScheduledTask_Edit1
{
    Import-DscResource -ModuleName xComputerManagement
    node "localhost" {
        xScheduledTask xScheduledTask_Edit1 {
            TaskName = "Test task"
            TaskPath = "\xComputerManagement\"
            ActionExecutable = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
            ScheduleType = "Minutes"
            RepeatInterval = 45
        } 
    }
}

Configuration xScheduledTask_Edit2
{
    Import-DscResource -ModuleName xComputerManagement
    node "localhost" {
        xScheduledTask xScheduledTask_Edit2 {
            TaskName = "Test task"
            TaskPath = "\xComputerManagement\"
            ActionExecutable = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
            ScheduleType = "Hourly"
            RepeatInterval = 4
        } 
    }
}

Configuration xScheduledTask_Edit3
{
    Import-DscResource -ModuleName xComputerManagement
    node "localhost" {
        xScheduledTask xScheduledTask_Edit3 {
            TaskName = "Test task"
            TaskPath = "\xComputerManagement\"
            ActionExecutable = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
            ScheduleType = "Daily"
            RepeatInterval = 1
        } 
    }
}

Configuration xScheduledTask_Edit4
{
    Import-DscResource -ModuleName xComputerManagement
    node "localhost" {
        xScheduledTask xScheduledTask_Edit3 {
            TaskName = "Test task"
            TaskPath = "\xComputerManagement\"
            ActionExecutable = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
            ActionWorkingPath = "C:\"
            ScheduleType = "Daily"
            RepeatInterval = 1
        } 
    }
}

Configuration xScheduledTask_Edit5
{
    Import-DscResource -ModuleName xComputerManagement
    node "localhost" {
        xScheduledTask xScheduledTask_Edit5 {
            TaskName = "Test task"
            TaskPath = "\xComputerManagement\"
            ActionExecutable = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
            ActionWorkingPath = "C:\"
            ActionArguments = "-Command 'Get-ChildItem'"
            ScheduleType = "Daily"
            RepeatInterval = 1
        } 
    }
}

Configuration xScheduledTask_Remove
{
    Import-DscResource -ModuleName xComputerManagement
    node "localhost" {
        xScheduledTask xScheduledTask_Remove {
            TaskName = "Test task"
            TaskPath = "\xComputerManagement\"
            ActionExecutable = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
            ScheduleType = "Minutes"
            RepeatInterval = 15
            Ensure="Absent"
        } 
    }
}

Configuration xScheduledTask_Enable
{
    Import-DscResource -ModuleName xComputerManagement
    node "localhost" {
        xScheduledTask xScheduledTask_Remove {
            TaskName = "Test task"
            TaskPath = "\xComputerManagement\"
            ActionExecutable = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
            ScheduleType = "Minutes"
            RepeatInterval = 15
            Enable = $true
            Ensure="Present"
        } 
    }
}

Configuration xScheduledTask_Disable
{
    Import-DscResource -ModuleName xComputerManagement
    node "localhost" {
        xScheduledTask xScheduledTask_Remove {
            TaskName = "Test task"
            TaskPath = "\xComputerManagement\"
            ActionExecutable = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
            ScheduleType = "Minutes"
            RepeatInterval = 15
            Enable = $false
            Ensure="Present"
        } 
    }
}