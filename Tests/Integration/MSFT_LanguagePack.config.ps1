# Integration Test Config Template Version: 1.0.0
configuration MSFT_LanguagePack_Config {
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $LangaugePackName,

        [Parameter(Mandatory = $false)]
        [String]
        $LangaugePackLocation,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Present','Absent')]
        [String]
        $Ensure
    )

    Import-DscResource -ModuleName ComputerManagementDsc

    node localhost {
        LanguagePack Integration_Test {
            LanguagePackName = $LangaugePackName
            LanguagePackLocation = $LangaugePackLocation
            Ensure = $Ensure
        }
    }
}
