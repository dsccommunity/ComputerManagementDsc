#Installs the latest version of Chrome in the language specified in the parameter Language.

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
            IsSingleInstance = "Yes"
            LocationID = 242
            MUILanguage = "en-GB"
            MUIFallbackLanguage = "en-US"
            SystemLocale = "en-GB"
            AddInputLanguages = @("0809:00000809")
            RemoveInputLanguages = @("0409:00000409")
            UserLocale = "en-GB"
            CopySystem = $true
            CopyNewUser = $true
        }
    }
}
