# Description

The resource is used to define basic run once or recurring scheduled tasks
on the local computer. It can also be used to delete or disable built-in
scheduled tasks.

## Known Issues

When creating a scheduled task with a StartTime, you should always specify both
a date and a time, with the SortableDateTimePattern format (e.g. 1980-01-01T00:00:00).
Not providing a date may result in 'flip flopping' if the remote server enters daylight
savings time. The date and time specified will be set based on the time zone that has been
configured on the device. If you want to synchronize a scheduled task across timezones,
use the SynchronizeAcrossTimeZone parameter, and specify the timezone offset that is needed
(e.g. 1980-01-01T00:00:00-08:00).

One of the values needed for the `MultipleInstances` parameter is missing from the
`Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.MultipleInstancesEnum`
enumerator. There are four valid values defined for the `MultipleInstances` property of the
Task Settings ([TaskSettings.MultipleInstances Property](https://docs.microsoft.com/en-us/windows/win32/taskschd/tasksettings-multipleinstances "TaskSettings.MultipleInstances Property")).
The `MultipleInstancesEnum` enumerator has three values, which can be mapped to three
of the four valid values, but there is no value corresponding to `TASK_INSTANCES_STOP_EXISTING`.
The result of this omission is that a workaround is required to
accommodate the `StopExisting` value for the `MultipleInstances` parameter,
which would not be necessary if the enumerator had all four valid values.

### ExecuteAsCredential

#### When Using a BUILTIN Group

When creating a scheduled task that uses an `ExecuteAsCredential` that
is one of the 'BUILTIN' groups (e.g. 'BUILTIN\Users'), specifying the
username to include the 'BUILTIN' domain name will result in the resource
never going into state. The same behavior will also occur if setting a
'BUILTIN' group in the UI.

To prevent this issue, set the username in the `ExecuteAsCredential` to the
name of the group only (e.g. 'Users').

#### When Using a Domain User/Group

When creating a scheduled task that uses an `ExecuteAsCredential` that
is a domain user or group, (e.g. 'CONTOSO\ServiceUser'), the domain
name must be included, otherwise the resource will not go into state.

To prevent this issue, set the username in the `ExecuteAsCredential` to the
name of the group only (e.g. 'CONTOSO\ServiceUser').
