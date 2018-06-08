<#
    .EXAMPLE
    Configures the system locale, user locale and keyboard to English (United Kingdom) with a fallback to en-US,
    all settings are also copied to the local system account and all new users.
#>
Configuration Example
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost'
    )

    Import-DscResource -Module ComputerManagementDsc

    Node $NodeName
    {
        Language ConfigureLanguage
        {
            IsSingleInstance = 'Yes'
            LocationID = 242
            MUILanguage = 'en-GB'
            MUIFallbackLanguage = 'en-US'
            SystemLocale = 'en-GB'
            AddInputLanguages = @('0809:00000809')
            RemoveInputLanguages = @('0409:00000409')
            UserLocale = 'en-GB'
            CopySystem = $true
            CopyNewUser = $true
        }
    }
}
