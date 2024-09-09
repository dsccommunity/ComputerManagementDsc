@{
    Gallery         = 'PSGallery'
    AllowPrerelease = $false
    WithYAML        = $true

    #UseModuleFast = $true
    #ModuleFastVersion = '0.1.2'
    #ModuleFastBleedingEdge = $true

    #? Setting to $true currenly (2024-06-02) causes integration test failures
    UsePSResourceGet = $true
    #PSResourceGetVersion = '1.0.1'

    #? Setting to $true currenly (2024-06-02) causes integration test failures
    UsePowerShellGetCompatibilityModule = $true
    UsePowerShellGetCompatibilityModuleVersion = '3.0.23-beta23'
}
