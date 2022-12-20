<#
    .SYNOPSIS
        Unit test for PSResource DSC resource.
#>

# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

try
{
    if (-not (Get-Module -Name 'DscResource.Test'))
    {
        # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
        if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
        {
            # Redirect all streams to $null, except the error stream (stream 2)
            & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
        }

        # If the dependencies has not been resolved, this will throw an error.
        Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
    }
}
catch [System.IO.FileNotFoundException]
{
    throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
}

try
{
    $script:dscModuleName = 'ComputerManagementDsc'

    Import-Module -Name $script:dscModuleName

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName

    Describe 'PSResource' {
        Context 'When class is instantiated' {
            It 'Should not throw an exception' {
                InModuleScope -ScriptBlock {
                    { [PSResource]::new() } | Should -Not -Throw
                }
            }

            It 'Should have a default or empty constructor' {
                InModuleScope -ScriptBlock {
                    $instance = [PSResource]::new()
                    $instance | Should -Not -BeNullOrEmpty
                }
            }

            It 'Should be the correct type' {
                InModuleScope -ScriptBlock {
                    $instance = [PSResource]::new()
                    $instance.GetType().Name | Should -Be 'PSResource'
                }
            }
        }
    }

    Describe 'PSResource\Get()' -Tag 'Get' {

        Context 'When the system is in the desired state' {
        }

        Context 'When the system is not in the desired state' {
        }
    }

    Describe 'PSResource\Set()' -Tag 'Set' {
    }

    Describe 'PSResource\Test()' -Tag 'Test' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockPSResourceInstance = [PSResource] @{
                    Name       = 'ComputerManagementDsc'
                    Repository = 'PSGallery'
                }
            }
        }

        Context 'When the system is in the desired state' {
            BeforeAll {
                InModuleScope -ScriptBlock {

                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    $script:mockPSResourceInstance.Test() | Should -BeTrue
                }
            }
        }

        Context 'When the system is not in the desired state' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockPSResourceInstance |
                        # Mock method Compare() which is called by the base method Test ()
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                            return @{
                                Property      = 'Version'
                                ExpectedValue = '8.6.0'
                                ActualValue   = '8.5.0'
                            }
                        }
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    $script:mockPSResourceInstance.Test() | Should -BeFalse
                }
            }
        }
    }

    Describe 'PSResource\GetCurrentState()' -Tag 'GetCurrentState' {
        Context 'When the system is in the desired state' {
        }

        Context 'When the system is not in the desired state' {
        }
    }

    Describe 'PSResource\Modify()' -Tag 'Modify' {
    }

    Describe 'PSResource\AssertProperties()' -Tag 'AssertProperties' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                $script:mockPSResourceInstance = [PSResource] @{}
            }
        }
        Context 'When PowerShellGet version is too low for AllowPrerelease' {
            InModuleScope -ScriptBlock {
                Mock -CommandName Get-Module -MockWith {
                    return @{
                        Name   = 'PowerShellGet'
                        Version = '1.5.0'
                    }
                }
            }
            It 'Should throw the correct error' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceInstance.AllowPrerelease = $true
                        $script:mockPSResourceInstance.AssertProperties(
                            @{AllowPrerelease = $true}
                        ) | Should -Throw -ExpectedMessage $script:mockPSResourceInstance.localizedData.PowerShellGetVersionTooLowForAllowPrerelease
                    }
                }
            }
        }

        Context 'When passing dependant parameters' {
            It 'Should throw when RemoveNonCompliantVersions and SingleInstance are passed together' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceInstance.AssertProperties(
                            @{
                                RemoveNonCompliantVersions = $true
                                SingleInstance             = $true
                            }
                        ) | Should -Throw -ExpectedMessage 'DRC0010'
                    }
                }
            }

            It 'Should throw when Latest and MinimumVersion are passed together' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceInstance.AssertProperties(
                            @{
                                Latest         = $true
                                MinimumVersion = '1.0.0'
                            }
                        ) | Should -Throw -ExpectedMessage 'DRC0010'
                    }
                }
            }

            It 'Should throw when Latest and RequiredVersion are passed together' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceInstance.AssertProperties(
                            @{
                                Latest         = $true
                                RequiredVersion = '1.0.0'
                            }
                        ) | Should -Throw -ExpectedMessage 'DRC0010'
                    }
                }
            }

            It 'Should throw when Latest and MaximumVersion are passed together' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceInstance.AssertProperties(
                            @{
                                Latest         = $true
                                MaximumVersion = '1.0.0'
                            }
                        ) | Should -Throw -ExpectedMessage 'DRC0010'
                    }
                }
            }

            It 'Should throw when MinimumVersion and MaximumVersion are passed together' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceInstance.AssertProperties(
                            @{
                                MinimumVersion = '1.0.0'
                                MaximumVersion = '1.0.0'
                            }
                        ) | Should -Throw -ExpectedMessage 'DRC0010'
                    }
                }
            }

            It 'Should throw when MinimumVersion and RequiredVersion are passed together' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceInstance.AssertProperties(
                            @{
                                MinimumVersion  = '1.0.0'
                                RequiredVersion = '1.0.0'
                            }
                        ) | Should -Throw -ExpectedMessage 'DRC0010'
                    }
                }
            }

            It 'Should throw when RequiredVersion and MaximumVersion are passed together' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceInstance.AssertProperties(
                            @{
                                MaximumVersion  = '1.0.0'
                                RequiredVersion = '1.0.0'
                            }
                        ) | Should -Throw -ExpectedMessage 'DRC0010'
                    }
                }
            }
        }

        Context 'When ensure is Absent' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockPSResourceInstance.Ensure = 'Absent'
                }
            }

            It 'Should throw when ensure is Absent and MinimumVersion is passed' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceInstance.AssertProperties(
                            @{MinimumVersion = '1.0.0'}
                        ) | Should -Throw -ExpectedMessage $script:mockPSResourceInstance.localizedData.EnsureAbsentWithVersioning
                    }
                }
            }

            It 'Should throw when ensure is Absent and MaximumVersion is passed' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceInstance.AssertProperties(
                            @{MaximumVersion = '1.0.0'}
                        ) | Should -Throw -ExpectedMessage $script:mockPSResourceInstance.localizedData.EnsureAbsentWithVersioning
                    }
                }
            }

            It 'Should throw when ensure is Absent and Latest is passed' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceInstance.AssertProperties(
                            @{Latest = $true}
                        ) | Should -Throw -ExpectedMessage $script:mockPSResourceInstance.localizedData.EnsureAbsentWithVersioning
                    }
                }
            }
        }

        Context 'When ProxyCredential is passed without Proxy' {
            It 'Should throw when ProxyCredential is passed without Proxy' {
                InModuleScope -ScriptBlock {
                    {
                        $securePassword = New-Object -Type SecureString
                        $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'USER', $securePassword

                        $script:mockPSResourceInstance.AssertProperties(
                            @{ProxyCredential = $credential}
                        ) | Should -Throw -ExpectedMessage $script:mockPSResourceInstance.localizedData.ProxyCredentialPassedWithoutProxyUri
                    }
                }
            }
        }

        Context 'When Credential or Proxy are passed without Repository' {
            It 'Should throw when Credential is passed without Repository' {
                InModuleScope -ScriptBlock {
                    {
                        $securePassword = New-Object -Type SecureString
                        $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'USER', $securePassword

                        $script:mockPSResourceInstance.AssertProperties(
                            @{Credential = $credential}
                        ) | Should -Throw -ExpectedMessage $script:mockPSResourceInstance.localizedData.ProxyorCredentialWithoutRepository
                    }
                }
            }

            It 'Should throw when Proxy is passed without Repository' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceInstance.AssertProperties(
                            @{Proxy = 'http://psgallery.com/'}
                        ) | Should -Throw -ExpectedMessage $script:mockPSResourceInstance.localizedData.ProxyorCredentialWithoutRepository
                    }
                }
            }
        }

        Context 'When RemoveNonCompliantVersions is passed without a versioning parameter' {
            It 'Should throw when RemoveNonCompliantVersions is passed without a versioning parameter' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceInstance.AssertProperties(
                            @{RemoveNonCompliantVersions = $true}
                        ) | Should -Throw -ExpectedMessage $script:mockPSResourceInstance.localizedData.RemoveNonCompliantVersionsWithoutVersioning
                    }
                }
            }
        }

        Context 'When Latest is passed' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockPSResourceInstance |
                        Add-Member 'ScriptMethod' -Name 'GetLatestVersion' -Value {
                            return '1.5.0'
                        } -Force
                }
            }
            It 'Should correctly set read only LatestVersion property' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceInstance.AssertProperties(
                            @{Latest = $true}
                        )
                        $script:mockPSResourceInstance.LatestVersion | Should -Be '1.5.0'
                    }
                }
            }
        }

        Context 'When a versioning parameter is passed' {
            It 'Should correctly set read only VersionRequirement property when MinimumVersion is passed' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceInstance |
                            Add-Member 'ScriptMethod' -Name 'GetVersionRequirement' -Value {
                                return 'MinimumVersion'
                            }

                        $script:mockPSResourceInstance.AssertProperties(
                            @{MinimumVersion = '1.1.0'}
                        )
                        $script:mockPSResourceInstance.VersionRequirement | Should -Be 'MinimumVersion'
                    }
                }
            }

            It 'Should correctly set read only VersionRequirement property when MaximumVersion is passed' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceInstance |
                            Add-Member 'ScriptMethod' -Name 'GetVersionRequirement' -Value {
                                return 'MaximumVersion'
                            }

                        $script:mockPSResourceInstance.AssertProperties(
                            @{MaximumVersion = '1.1.0'}
                        )
                        $script:mockPSResourceInstance.VersionRequirement | Should -Be 'MaximumVersion'
                    }
                }
            }

            It 'Should correctly set read only VersionRequirement property when RequiredVersion is passed' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceInstance |
                            Add-Member 'ScriptMethod' -Name 'GetVersionRequirement' -Value {
                                return 'RequiredVersion'
                            }

                        $script:mockPSResourceInstance.AssertProperties(
                            @{MaximumVersion = '1.1.0'}
                        )
                        $script:mockPSResourceInstance.VersionRequirement | Should -Be 'RequiredVersion'
                    }
                }
            }

            It 'Should correctly set read only VersionRequirement property when Latest is passed' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceInstance |
                            Add-Member 'ScriptMethod' -Name 'GetVersionRequirement' -Value {
                                return 'Latest'
                            }

                        $script:mockPSResourceInstance.AssertProperties(
                            @{Latest = $true}
                        )
                        $script:mockPSResourceInstance.VersionRequirement | Should -Be 'Latest'
                    }
                }
            }
        }
    }

    # Describe 'PSResource\TestSingleInstance()' -Tag 'TestSingleInstance' {
    #     InModuleScope -ScriptBlock {
    #         $script:mockPSResourceInstance = [PSResource] @{
    #             Name           = 'ComputerManagementDsc'
    #             Ensure         = 'Present'
    #             SingleInstance = $True
    #         }
    #     }

    #     It 'Should not throw and return True when one resource is present' {
    #         InModuleScope -ScriptBlock {
    #             $script:mockPSResourceInstance.TestSingleInstance(
    #                 @(
    #                     @{
    #                         Name    = 'ComputerManagementDsc'
    #                         Version = '8.6.0'
    #                     }
    #                 )
    #             ) | Should -BeTrue
    #         }
    #     }

    #     It 'Should not throw and return False when zero resources are present' {
    #         InModuleScope -ScriptBlock {
    #             $script:mockPSResourceInstance.TestSingleInstance(
    #                 @()
    #             ) | Should -BeFalse
    #         }
    #     }

    #     It 'Should not throw and return False when more than one resource is present' {
    #         InModuleScope -ScriptBlock {
    #             $script:mockPSResourceInstance.TestSingleInstance(
    #                 @(
    #                     @{
    #                         Name    = 'ComputerManagementDsc'
    #                         Version = '8.6.0'
    #                     },
    #                     @{
    #                         Name    = 'ComputerManagementDsc'
    #                         Version = '8.5.0'
    #                     }
    #                 )
    #             ) | Should -BeFalse
    #         }
    #     }
    # }

    Describe 'PSResource\TestSingleInstance()' -Tag 'TestSingleInstance' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockPSResourceInstance = [PSResource] @{
                    Name           = 'ComputerManagementDsc'
                    Ensure         = 'Present'
                    SingleInstance = $True
                }
            }
        }

        Context 'When there are zero resources installed' {
            It 'Should Correctly return False when Zero Resources are Installed' {

                InModuleScope -ScriptBlock {
                    $script:mockPSResourceInstance.TestSingleInstance($null) | Should -BeFalse
                }
            }
        }

        Context 'When there is one resource installed' {
            It 'Should Correctly return True when One Resource is Installed' {
                InModuleScope -ScriptBlock {
                    $script:mockResources = @{Name = 'ComputerManagementDsc'}
                    $script:mockPSResourceInstance.TestSingleInstance($script:mockResources) | Should -BeTrue
                }
            }
        }

        Context 'When there are multiple resources installed' {
            It 'Should Correctly return False' {
                InModuleScope -ScriptBlock {
                    $script:mockResources = @{
                        Name    = 'ComputerManagementDsc'
                        Version = '8.5.0'
                    },
                    @{
                        Name    = 'ComputerManagementDsc'
                        Version = '8.6.0'
                    }
                    $script:mockPSResourceInstance.TestSingleInstance($script:mockResources) | Should -BeFalse
                }
            }
        }
    }

    Describe 'PSResource\GetLatestVersion()' -Tag 'GetLatestVersion' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockPSResourceInstance = [PSResource] @{
                    Name       = 'ComputerManagementDsc'
                    Ensure     = 'Present'
                }
            }
        }

        Context 'When there FindResource finds a resourse' {
            # BeforeEach {
            #     Mock -CommandName Find-Module -MockWith {
            #         return $(New-MockObject -Type 'Version' | Add-Member -MemberType NoteProperty -Name 'Version' -Value '8.6.0')
            #     }
            # }

            It 'Should return the correct version' {
                InModuleScope -ScriptBlock {
                    $script:mockPSResourceInstance |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'FindResource' -Value {
                        return [System.Collections.Hashtable] @{
                            Version = '8.6.0'
                        }
                    }

                    $script:mockPSResourceInstance.GetLatestVersion() | Should -Be '8.6.0'
                }
            }
        }

        Context 'When there FindResource does not find a resourse' {
            It 'Should return null or empty' {
                InModuleScope -ScriptBlock {
                    $script:mockPSResourceInstance |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'FindResource' -Value {
                        return $null
                    }

                    $script:mockPSResourceInstance.GetLatestVersion() | Should -BeNullOrEmpty
                }
            }
        }
    }

    Describe 'PSResource\GetInstalledResource()' -Tag 'GetInstalledResource' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockPSResourceInstance = [PSResource] @{
                    Name       = 'ComputerManagementDsc'
                    Ensure     = 'Present'
                }
            }
        }

        It 'Should return nothing' {
            InModuleScope -ScriptBlock {
                Mock -CommandName Get-Module
                { $script:mockPSResourceInstance.GetInstalledResource() | Should -BeNullOrEmpty }
            }
        }

        It 'Should return one object' {
            InModuleScope -ScriptBlock {
                Mock -CommandName Get-Module -MockWith {
                    return @{
                        Name    = 'PowerShellGet'
                        Version = '3.0.17'
                    }
                }
                {
                    $resources = $script:mockPSResourceInstance.GetInstalledResource().Count
                    $resources.Count  | Should -Be 1
                    $resource.Name    | Should -Be 'PowerShellGet'
                    $resource.Version | Should -Be '3.0.17'
                }
            }
        }

        It 'Should return two objects' {
            InModuleScope -ScriptBlock {
                Mock -CommandName Get-Module -MockWith {
                    return @(
                        @{
                            Name    = 'PowerShellGet'
                            Version = '3.0.17'
                        },
                        @{
                            Name    = 'PowerShellGet'
                            Version = '2.2.5'
                        }
                    )
                }
                {
                    $resources = $script:mockPSResourceInstance.GetInstalledResource().Count
                    $resources.Count  | Should -Be 2
                    $resource[0].Name    | Should -Be 'PowerShellGet'
                    $resource[0].Version | Should -Be '3.0.17'
                    $resource[1].Name    | Should -Be 'PowerShellGet'
                    $resource[1].Version | Should -Be '2.2.5'
                }
            }
        }
    }

    Describe 'PSResource\GetFullVersion()' -Tag 'GetFullVersion' {
    }

    Describe 'PSResource\TestPrerelease()' -Tag 'TestPrerelease' {

    }

    Describe 'PSResource\TestLatestVersion()' -Tag 'TestLatestVersion' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockPSResourceInstance = [PSResource] @{
                    Name          = 'ComputerManagementDsc'
                    LatestVersion = '8.6.0'
                    Ensure        = 'Present'
                }
            }
        }

        It 'Should return true when only one resource is installed and it is the latest version' {
            InModuleScope -ScriptBlock {
                $script:mockInstalledResources = @{
                    Name    = 'PowerShellGet'
                    Version = '8.6.0'
                }
                $script:mockPSResourceInstance.TestLatestVersion($script:mockInstalledResources) | Should -BeTrue
            }
        }

        It 'Should return true when multiple resources are installed, including the latest version' {
            InModuleScope -ScriptBlock {

                $script:mockInstalledResources = @(
                    @{
                        Name    = 'PowerShellGet'
                        Version = '8.1.0'
                    },
                    @{
                        Name    = 'PowerShellGet'
                        Version = '8.6.0'
                    },
                    @{
                        Name    = 'PowerShellGet'
                        Version = '8.7.0'
                    }
                )

                $script:mockPSResourceInstance.TestLatestVersion($script:mockInstalledResources) | Should -BeTrue
            }
        }

        It 'Should return false when only one resource is installed and it is not the latest version' {
            InModuleScope -ScriptBlock {
                $script:mockInstalledResources = @{
                    Name    = 'PowerShellGet'
                    Version = '8.5.0'
                }
                $script:mockPSResourceInstance.TestLatestVersion($script:mockInstalledResources) | Should -BeFalse
            }
        }

        It 'Should return false when multiple resources are installed, not including the latest version' {
            InModuleScope -ScriptBlock {
                $script:mockInstalledResources = @(
                    @{
                        Name    = 'PowerShellGet'
                        Version = '8.1.0'
                    },
                    @{
                        Name    = 'PowerShellGet'
                        Version = '8.5.0'
                    },
                    @{
                        Name    = 'PowerShellGet'
                        Version = '8.7.0'
                    }
                )

                $script:mockPSResourceInstance.TestLatestVersion($script:mockInstalledResources) | Should -BeFalse
            }
        }
    }

    Describe 'PSResource\TestRepository()' -Tag 'TestRepository' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockPSResourceInstance = [PSResource]@{}
            }
        }

        Context 'When the repository is untrusted' {
            It 'Should throw when the repository is untrusted and force is not set' {
                InModuleScope -ScriptBlock {
                    {
                        Mock -CommandName Get-PSRepository -MockWith {
                            return @{
                                Name               = 'PSGallery'
                                InstallationPolicy = 'Untrusted'
                            }
                        }
                        $script:mockPSResourceInstance |
                            Add-Member -Force -MemberType 'ScriptMethod' -Name 'FindResource' -Value {
                                return @{
                                    Name       = 'PowerShellGet'
                                    Version    = '1.5.0'
                                    Repository = 'PSGallery'
                                }
                            } -Force

                        $script:mockPSResourceInstance.TestRepository() | Should -Throw -ExpectedMessage $script:mockPSResourceInstance.localizedData.UntrustedRepositoryWithoutForce
                    }
                }
            }

            It 'Should not throw when the repository is untrusted and force is set' {
                InModuleScope -ScriptBlock {
                    {
                        Mock -CommandName Get-PSRepository -MockWith {
                            return @{
                                Name               = 'PSGallery'
                                InstallationPolicy = 'Untrusted'
                            }
                        }
                        $script:mockPSResourceInstance.Force = $true
                        $script:mockPSResourceInstance |
                            Add-Member -Force -MemberType 'ScriptMethod' -Name 'FindResource' -Value {
                                return @{
                                    Name       = 'PowerShellGet'
                                    Version    = '1.5.0'
                                    Repository = 'PSGallery'
                                }
                            } -Force

                        $script:mockPSResourceInstance.TestRepository() | Should -Not -Throw
                    }
                }
            }
        }

        Context 'When the repository is trusted' {
            It 'Should not throw when the repository is trusted' {
                InModuleScope -ScriptBlock {
                    {
                        Mock -CommandName Get-PSRepository -MockWith {
                            return @{
                                Name               = 'InternalRepo'
                                InstallationPolicy = 'Trusted'
                            }
                        }
                        $script:mockPSResourceInstance.Force = $true
                        $script:mockPSResourceInstance |
                            Add-Member -Force -MemberType 'ScriptMethod' -Name 'FindResource' -Value {
                                return @{
                                    Name       = 'PowerShellGet'
                                    Version    = '1.5.0'
                                    Repository = 'InternalRepo'
                                }
                            } -Force

                        $script:mockPSResourceInstance.TestRepository() | Should -Not -Throw
                    }
                }
            }
        }

    }

    Describe 'PSResource\FindResource' -Tag 'FindResource' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockPSResourceInstance = [PSResource]@{}
            }
        }

        Context 'When FindResource is called' {
            It 'Should not throw and return properties correctly' {
                InModuleScope -ScriptBlock {
                    Mock -CommandName Find-Module -MockWith {
                        return @{
                            Name       = 'ComputerManagementDsc'
                            Version    = '9.0.0'
                            Repository = 'PSGallery'
                        }
                    }

                    {
                        $findResourceResult = $script:mockPSResourceInstance.FindResource()
                        $findResourceResult.Name       | Should -Be 'ComputerManagementDsc'
                        $findResourceResult.Version    | Should -Be '9.0.0'
                        $findResourceResult.Repository | Should -Be 'PSGallery'
                    }
                }
            }
        }
    }

    Describe 'PSResource\InstallResource' -Tag 'InstallResource' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockPSResourceInstance = [PSResource]@{} |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'TestRepository' -Value {
                        return $null #! Do I even need a -Value {} here?
                    }

                Mock -CommandName Install-Module
            }
        }

        Context 'When InstallResource is called' {
            It 'Should not throw when InstallResource is called' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceInstance.InstallResource() | Should -Not -Throw
                    }
                }
            }
        }
    }

    Describe 'PSResource\UninstallResource' -Tag 'UninstallResource' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockPSResourceInstance = [PSResource]@{}

                Mock -CommandName Uninstall-Module
            }
        }

        Context 'When UninstallResource is called' {
            It 'Should not throw when UninstallResource is called' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceInstance.UninstallResource(
                            @{
                                Name    = 'ComputerManagementDsc'
                                Version = '1.6.0'
                            }
                        ) | Should -Not -Throw
                    }
                }
            }
        }
    }

    Describe 'PSResource\TestVersionRequirement()' -Tag 'TestVersionRequirement' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockPSResourceInstance = [PSResource]@{}

                Mock -CommandName Uninstall-Module
            }
        }

        Context 'When versionrequirement is MinimumVersion' {
            It 'Should return true when MinimumVersion requirement is met' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceInstance.MinimumVersion = '8.6.0'
                        $script:mockPSResourceInstance.TestVersionRequirement(
                            @{
                                Version = '8.6.0'
                            },
                            'MinimumVersion'
                        ) | Should -BeTrue
                    }
                }
            }

            It 'Should return false when MinimumVersion requirement is not met' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceInstance.MinimumVersion = '8.7.0'
                        $script:mockPSResourceInstance.TestVersionRequirement(
                            @{
                                Version = '8.6.0'
                            },
                            'MinimumVersion'
                        ) | Should -BeFalse
                    }
                }
            }
        }

        Context 'When versionrequirement is MaximumVersion' {
            It 'Should return true when MaximumVersion requirement is met' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceInstance.MaximumVersion = '8.7.0'
                        $script:mockPSResourceInstance.TestVersionRequirement(
                            @{
                                Version = '8.6.0'
                            },
                            'MaximumVersion'
                        ) | Should -BeTrue
                    }
                }
            }

            It 'Should return false when MaximumVersion requirement is not met' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceInstance.MaximumVersion = '8.7.0'
                        $script:mockPSResourceInstance.TestVersionRequirement(
                            @{
                                Version = '9.0.0'
                            },
                            'MaximumVersion'
                        ) | Should -BeFalse
                    }
                }
            }
        }

        Context 'When versionrequirement is RequiredVersion' {
            It 'Should return true when RequiredVersion requirement is met' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceInstance.RequiredVersion = '9.0.0'
                        $script:mockPSResourceInstance.TestVersionRequirement(
                            @{
                                Version = '9.0.0'
                            },
                            'RequiredVersion'
                        ) | Should -BeTrue
                    }
                }
            }

            It 'Should return false when RequiredVersion requirement is not met' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceInstance.RequiredVersion = '9.0.0'
                        $script:mockPSResourceInstance.TestVersionRequirement(
                            @{
                                Version = '8.0.0'
                            },
                            'RequiredVersion'
                        ) | Should -BeFalse
                    }
                }
            }
        }

        Context 'When versionrequirement is Latest' {
            It 'Should return true when Latest requirement is met' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceInstance.LatestVersion = '9.0.0'
                        $script:mockPSResourceInstance.TestVersionRequirement(
                            @{
                                Version = '9.0.0'
                            },
                            'Latest'
                        ) | Should -BeTrue
                    }
                }
            }

            It 'Should return false when Latest requirement is not met with a single resource' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceInstance.Latest = '9.0.0'
                        $script:mockPSResourceInstance.TestVersionRequirement(
                            @{
                                Version = '8.0.0'
                            },
                            'Latest'
                        ) | Should -BeFalse
                    }
                }
            }

            It 'Should return false when Latest requirement is not met with a multiple resources, including latest' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceInstance.Latest = '9.0.0'
                        $script:mockPSResourceInstance.TestVersionRequirement(
                            @(
                                @{
                                    Version = '8.0.0'
                                },
                                @{
                                    Version = '9.0.0'
                                }
                            ),
                            'Latest'
                        ) | Should -BeFalse
                    }
                }
            }
        }
    }

    Describe 'PSResource\GetMinimumInstalledVersion()' -Tag 'GetMinimumInstalledVersion' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockPSResourceInstance = [PSResource]@{
                    MinimumVersion = '7.0.0'
                }
            }
        }

        Context 'When calling GetMinimumInstalledVersion()' {
            It 'Should return the correct minimum version when an installed resource matches given MinimumVersion' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceInstance.GetMinimumInstalledVersion(
                            @(
                                @{
                                    Version = '6.0.0'
                                },
                                @{
                                    Version = '7.0.0'
                                }
                            )
                        ) | Should -Be '7.0.0'
                    }
                }
            }

            It 'Should return the correct minimum version when an installed resource does not match the given MinimumVersion' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceInstance.GetMinimumInstalledVersion(
                            @(
                                @{
                                    Version = '6.0.0'
                                },
                                @{
                                    Version = '5.0.0'
                                },
                                @{
                                    Version = '4.2.0'
                                }
                            )
                        ) | Should -Be '4.2.0'
                    }
                }
            }
        }
    }

    Describe 'PSResource\GetMaximumInstalledVersion()' -Tag 'GetMaximumInstalledVersion' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockPSResourceInstance = [PSResource]@{
                    MaximumVersion = '7.0.0'
                }
            }
        }

        Context 'When calling GetMaximumInstalledVersion()' {
            It 'Should return the correct maximum version when an installed resource matches given MaximumVersion' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceInstance.GetMaximumInstalledVersion(
                            @(
                                @{
                                    Version = '6.0.0'
                                },
                                @{
                                    Version = '7.0.0'
                                }
                            )
                        ) | Should -Be '7.0.0'
                    }
                }
            }

            It 'Should return the correct maximum version when an installed resource does not match the given MaximumVersion' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceInstance.GetMaximumInstalledVersion(
                            @(
                                @{
                                    Version = '6.0.0'
                                },
                                @{
                                    Version = '7.0.0'
                                },
                                @{
                                    Version = '4.2.0'
                                }
                            )
                        ) | Should -Be '7.0.0'
                    }
                }
            }
        }
    }

    Describe 'PSResource\GetRequiredInstalledVersion()' -Tag 'GetRequiredInstalledVersion' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockPSResourceInstance = [PSResource]@{
                    RequiredVersion = '7.0.0'
                }
            }
        }

        Context 'When calling GetRequiredInstalledVersion()' {
            It 'Should return the RequiredVersion when the required version is installed' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceInstance.GetRequiredInstalledVersion(
                            @(
                                @{
                                    Version = '5.0.0'
                                },
                                @{
                                    Version = '7.0.0'
                                },
                                @{
                                    Version = '6.0.0'
                                }
                            )
                        ) | Should -Be '7.0.0'
                    }
                }
            }

            It 'Should return null when the required version is not installed' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceInstance.GetRequiredInstalledVersion(
                            @(
                                @{
                                    Version = '5.0.0'
                                },
                                @{
                                    Version = '8.0.0'
                                },
                                @{
                                    Version = '6.0.0'
                                }
                            )
                        ) | Should -BeNullOrEmpty
                    }
                }
            }
        }
    }
}
finally
{
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}
