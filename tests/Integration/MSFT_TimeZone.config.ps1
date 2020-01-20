configuration MSFT_TimeZone_Config {
    Import-DscResource -ModuleName ComputerManagementDsc

    node localhost {
        TimeZone Integration_Test {
            TimeZone         = $Node.TimeZone
            IsSingleInstance = $Node.IsSingleInstance
        }
    }
}
