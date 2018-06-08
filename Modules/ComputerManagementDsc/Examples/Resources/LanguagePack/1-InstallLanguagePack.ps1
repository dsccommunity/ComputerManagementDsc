<#
    .EXAMPLE
    Installs the English (United Kingdom) and German language packs from \\fileserver1\LanguagePacks.
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
        LanguagePack en-GB
        {
            LanguagePackName = 'en-GB'
            LanguagePackLocation = '\\fileserver1\LanguagePacks\'
        }

        LanguagePack de-DE
        {
            LanguagePackName = 'de-DE'
            LanguagePackLocation = '\\fileserver1\LanguagePacks\de-DE.cab'
        }
    }
}
