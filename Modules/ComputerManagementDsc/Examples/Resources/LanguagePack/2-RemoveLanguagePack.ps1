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
        LanguagePack removeEN-US
        {
            LanguagePackName = "en-US"
            Ensure = "Absent"
        }
    }
}
