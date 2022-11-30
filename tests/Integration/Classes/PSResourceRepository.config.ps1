$ConfigurationData = @{
    AllNodes    = , @{
        NodeName        = 'localhost'
        CertificateFile = $Null
    }
    NonNodeData = @{
        PSResourceRepository_Remove_PSGallery = @{
            Name   = 'PSGallery'
            Ensure = 'Absent'
        }
        PSResourceRepository_Create_Default_Config = @{
            Name    = 'PSGallery'
            Ensure  = 'Present'
            Default = $true
        }
        PSResourceRepository_Create_Config = @{
            Name           = 'PSTestGallery'
            Ensure         = 'Present'
            SourceLocation = 'https://www.nuget.org/api/v2'
        }
        PSResourceRepository_Modify_Config = @{
            Name                      = 'PSTestGallery'
            Ensure                    = 'Present'
            SourceLocation            = 'https://www.nuget.org/api/v2'
            PublishLocation           = 'https://www.nuget.org/api/v2/package/'
            ScriptSourceLocation      = 'https://www.nuget.org/api/v2/items/psscript/'
            ScriptPublishLocation     = 'https://www.nuget.org/api/v2/package/'
            InstallationPolicy        = 'Trusted'
            PackageManagementProvider = 'NuGet'
        }
        PSResourceRepository_Remove_Config = @{
            Name   = 'PSTestGallery'
            Ensure = 'Absent'
        }
    }
}

<#
    .SYNOPSIS
        Unregister PSRepository PSGallery
#>
configuration PSResourceRepository_Remove_PSGallery
{
    Import-DscResource -ModuleName 'ComputerManagementDsc'

    node $AllNodes.NodeName
    {
        PSResourceRepository 'Integration_Test'
        {
            Name           = $ConfigurationData.NonNodeData.PSResourceRepository_Remove_PSGallery.Name
            Ensure         = $ConfigurationData.NonNodeData.PSResourceRepository_Remove_PSGallery.Ensure
        }
    }
}

<#
    .SYNOPSIS
        Register Default PSRepository PSGallery
#>
configuration PSResourceRepository_Create_Default_Config
{
    Import-DscResource -ModuleName 'ComputerManagementDsc'

    node $AllNodes.NodeName
    {

        Script 'ForcePowerShellGetandPackageManagement'
        {
            SetScript = {
                # Make sure we use TLS 1.2.
                [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

                # Install NuGet package provider and latest version of PowerShellGet.
                Install-PackageProvider -Name NuGet -Force
                Install-Module PowerShellGet -AllowClobber -Force

                # Remove any loaded module to hopefully get those that was installed above.
                Get-Module -Name @('PackageManagement', 'PowerShellGet') -All | Remove-Module -Force

                # Forcibly import the newly installed modules.
                Import-Module -Name 'PackageManagement' -MinimumVersion '1.4.8.1' -Force

                $psGet = Get-Module -Name PowerShellGet -ListAvailable

                if (($psget | Sort-Object Version -Descending)[0].version -lt '2.2.5'){
                    Write-Verbose "installing psget 2.2.5"
                    Install-Module PowerShellGet -RequiredVersion 2.2.5 -Force
                }

                Import-Module -Name 'PowerShellGet' -MinimumVersion '2.2.5' -Force

                # Forcibly import the newly installed modules.
                Write-Verbose -Message (
                    Get-Module -Name @('PackageManagement', 'PowerShellGet') |
                    Select-Object -Property @('Name', 'Version') |
                    Out-String
                )
            }
            TestScript = {
                Write-Verbose "in test this doesnt matter just a way to make set happen"
                return $false
            }
            GetScript = {
                return @{
                    Result = 'whocares'
                }
            }
        }

        PSResourceRepository 'Integration_Test'
        {
            Name    = $ConfigurationData.NonNodeData.PSResourceRepository_Create_Default_Config.Name
            Ensure  = $ConfigurationData.NonNodeData.PSResourceRepository_Create_Default_Config.Ensure
            Default = $ConfigurationData.NonNodeData.PSResourceRepository_Create_Default_Config.Default
        }
    }
}

#!Delete this
configuration PSResourceRepository_Create_Default_Config_ShouldThrow
{
    Import-DscResource -ModuleName 'ComputerManagementDsc'

    node $AllNodes.NodeName
    {
        PSResourceRepository 'Integration_Test'
        {
            Name    = $ConfigurationData.NonNodeData.PSResourceRepository_Create_Default_Config_ShouldThrow.Name
            Ensure  = $ConfigurationData.NonNodeData.PSResourceRepository_Create_Default_Config_ShouldThrow.Ensure
            Default = $ConfigurationData.NonNodeData.PSResourceRepository_Create_Default_Config_ShouldThrow.Default
            SourceLocation = $ConfigurationData.NonNodeData.PSResourceRepository_Create_Default_Config_ShouldThrow.SourceLocation
        }
    }
}
#!Delete this

<#
    .SYNOPSIS
        Register a PSRepository
#>
configuration PSResourceRepository_Create_Config
{
    Import-DscResource -ModuleName 'ComputerManagementDsc'

    node $AllNodes.NodeName
    {
        PSResourceRepository 'Integration_Test'
        {
            Name           = $ConfigurationData.NonNodeData.PSResourceRepository_Create_Config.Name
            Ensure         = $ConfigurationData.NonNodeData.PSResourceRepository_Create_Config.Ensure
            SourceLocation = $ConfigurationData.NonNodeData.PSResourceRepository_Create_Config.SourceLocation
        }
    }
}

<#
    .SYNOPSIS
        Modifies an existing PSRepository
#>
configuration PSResourceRepository_Modify_Config
{
    Import-DscResource -ModuleName 'ComputerManagementDsc'

    node $AllNodes.NodeName
    {
        PSResourceRepository 'Integration_Test'
        {
            Name                      = $ConfigurationData.NonNodeData.PSResourceRepository_Modify_Config.Name
            Ensure                    = $ConfigurationData.NonNodeData.PSResourceRepository_Modify_Config.Ensure
            SourceLocation            = $ConfigurationData.NonNodeData.PSResourceRepository_Modify_Config.SourceLocation
            ScriptSourceLocation      = $ConfigurationData.NonNodeData.PSResourceRepository_Modify_Config.ScriptSourceLocation
            PublishLocation           = $ConfigurationData.NonNodeData.PSResourceRepository_Modify_Config.PublishLocation
            ScriptPublishLocation     = $ConfigurationData.NonNodeData.PSResourceRepository_Modify_Config.ScriptPublishLocation
            InstallationPolicy        = $ConfigurationData.NonNodeData.PSResourceRepository_Modify_Config.InstallationPolicy
            PackageManagementProvider = $ConfigurationData.NonNodeData.PSResourceRepository_Modify_Config.PackageManagementProvider
        }
    }
}

<#
    .SYNOPSIS
        Unregister an existing PSRepository
#>
configuration PSResourceRepository_Remove_Config
{
    Import-DscResource -ModuleName 'ComputerManagementDsc'

    node $AllNodes.NodeName
    {
        PSResourceRepository 'Integration_Test'
        {
            Name           = $ConfigurationData.NonNodeData.PSResourceRepository_Remove_Config.Name
            Ensure         = $ConfigurationData.NonNodeData.PSResourceRepository_Remove_Config.Ensure
        }
    }
}

