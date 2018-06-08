<#
    .EXAMPLE
    Removes the English (United States) language pack from the local system.
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
        LanguagePack removeEN-US
        {
            LanguagePackName = 'en-US'
            Ensure = 'Absent'
        }
    }
}
