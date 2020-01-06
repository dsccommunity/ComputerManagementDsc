ConvertFrom-StringData @'
    GetScheduledTaskMessage = Getting scheduled task '{0}' in '{1}'.
    TaskNotFoundMessage = Task '{0}' not found in '{1}'. Returning an empty task with Ensure = "Absent".
    TaskFoundMessage = Task '{0}' found in '{1}'. Retrieving settings, first action, first trigger and repetition settings.
    TriggerTypeUnknown = Trigger type '{0}' not recognized.
    DetectedScheduleTypeMessage = Detected schedule type '{0}' for first trigger.
    SetScheduledTaskMessage = Setting scheduled task '{0}' in '{1}'.
    DisablingExistingScheduledTask = Disabling existing scheduled task '{0}' in '{1}'.
    RepetitionDurationLessThanIntervalError = Repetition duration '{0}' is less than repetition interval '{1}'. Please set RepeatInterval to a value lower or equal to RepetitionDuration.
    DaysIntervalError = DaysInterval must be greater than zero (0) for Daily schedules. DaysInterval specified is '{0}'.
    WeeksIntervalError = WeeksInterval must be greater than zero (0) for Weekly schedules. WeeksInterval specified is '{0}'.
    WeekDayMissingError = At least one weekday must be selected for Weekly schedule.
    OnEventSubscriptionError = No (valid) XML Event Subscription was provided. This is required when the scheduletype is OnEvent.
    gMSAandCredentialError = Both ExecuteAsGMSA and (ExecuteAsCredential or BuiltInAccount) parameters have been specified. A task can run as a gMSA (Group Managed Service Account), a builtin service account or as a custom credential. Please modify your configuration to include just one of the three options.
    SynchronizeAcrossTimeZoneInvalidScheduleType = Setting SynchronizeAcrossTimeZone to true when the ScheduleType is not Once, Daily or Weekly is not a valid configuration. Please keep the default value of false when using other schedule types.
    TriggerCreationError = Error creating new scheduled task trigger.
    ConfigureTriggerRepetitionMessage = Configuring trigger repetition.
    RepetitionIntervalError = Repetition interval is set to '{0}' but repetition duration is '{1}'.
    CreateRepetitionPatternMessage = Creating MSFT_TaskRepetitionPattern CIM instance to configure repetition in trigger.
    CreateTemporaryTaskMessage = Creating temporary task and trigger to get MSFT_TaskRepetitionPattern CIM instance.
    CreateTemporaryTriggerMessage = Creating temporary trigger to get MSFT_TaskRepetitionPattern CIM instance.
    TriggerUnexpectedTypeError = Trigger object that was created was of unexpected type '{0}'.
    CreateScheduledTaskPrincipalMessage = Creating scheduled task principal for account '{0}' using logon type '{1}'.
    CreateNewScheduledTaskMessage = Creating new scheduled task '{0}' in '{1}'.
    ConfigureTaskEventTrigger = Setting up an event based trigger on task {0}.
    IgnoreRandomDelayWithTriggerTypeOnEvent = The parameter RandomDelay in task {0} is ignored. A random delay is not supported when the trigger type is set to OnEvent.
    SetRepetitionTriggerMessage = Setting repetition trigger settings on task '{0}' in '{1}'.
    RetrieveScheduledTaskMessage = Retrieving the scheduled task '{0}' from '{1}'.
    RemoveScheduledTaskMessage = Removing scheduled task '{0}' from '{1}'.
    UpdateScheduledTaskMessage = Updating scheduled task '{0}' in '{1}'.
    TestScheduledTaskMessage = Testing scheduled task '{0}' in '{1}'.
    GettingCurrentTaskValuesMessage = Getting current scheduled task values for task '{0}' in '{1}'.
    CurrentTaskValuesRetrievedMessage = Current scheduled task values for task '{0}' in '{1}' retrieved.
    CurrentTaskValuesNullMessage = Current scheduled values were null.
    TestingDscParameterStateMessage = Testing DSC parameter state.
'@
