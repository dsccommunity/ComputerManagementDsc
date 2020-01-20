# Description

Ths resource is used set the system locale on a Windows machine.

To get a list of valid Windows System Locales use the command:
`[System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::AllCultures).name`

If the System Locale is changed by this resource, it will require the node
to reboot. If the LCM is not configured to allow restarting, the configuration
will not be able to be applied until a manual restart occurs.
