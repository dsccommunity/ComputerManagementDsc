# Integration Test Config Template Version: 1.0.0
configuration MSFT_Language_Config {
    param
    (
        [Parameter(Mandatory = $true)]
        [Int]
        $LocationID,

        [Parameter(Mandatory = $true)]
        [String]
        $MUILanguage,

        [Parameter(Mandatory = $true)]
        [String]
        $MUIFallbackLanguage,

        [Parameter(Mandatory = $true)]
        [String]
        $SystemLocale,

        [Parameter(Mandatory = $true)]
        [String]
        $AddInputLanguages,

        [Parameter(Mandatory = $true)]
        [String]
        $RemoveInputLanguages,

        [Parameter(Mandatory = $true)]
        [String]
        $UserLocale
    )

    Import-DscResource -ModuleName ComputerManagementDsc

    node localhost
    {
        Language Integration_Test
        {
            IsSingleInstance = "Yes"
            LocationID = $LocationID
            MUILanguage = $MUILanguage
            MUIFallbackLanguage = $MUIFallbackLanguage
            SystemLocale = $SystemLocale
            AddInputLanguages = $AddInputLanguages
            RemoveInputLanguages = $RemoveInputLanguages
            UserLocale = $UserLocale
            CopySystem = $true
            CopyNewUser = $true
        }
    }
}
