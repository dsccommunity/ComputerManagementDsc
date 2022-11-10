<#
    .SYNOPSIS
        Unit test for PSResourceRepository DSC resource.
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

    Describe 'PSResourceRepository' {
        Context 'When class is instantiated' {
            It 'Should not throw an exception' {
                InModuleScope -ScriptBlock {
                    { [PSResourceRepository]::new() } | Should -Not -Throw
                }
            }

            It 'Should have a default or empty constructor' {
                InModuleScope -ScriptBlock {
                    $instance = [PSResourceRepository]::new()
                    $instance | Should -Not -BeNullOrEmpty
                }
            }

            It 'Should be the correct type' {
                InModuleScope -ScriptBlock {
                    $instance = [PSResourceRepository]::new()
                    $instance.GetType().Name | Should -Be 'PSResourceRepository'
                }
            }
        }
    }

    Describe 'PSResourceRepository\Get()' -Tag 'Get' {

        Context 'When the system is in the desired state' {
            Context 'When the repository should be Present' {
                BeforeEach {
                    Mock -CommandName Get-PSRepository -MockWith {
                        return @{
                            Name                      = 'FakePSGallery'
                            SourceLocation            = 'https://www.powershellgallery.com/api/v2'
                            ScriptSourceLocation      = 'https://www.powershellgallery.com/api/v2/items/psscript'
                            PublishLocation           = 'https://www.powershellgallery.com/api/v2/package/'
                            ScriptPublishLocation     = 'https://www.powershellgallery.com/api/v2/package/'
                            InstallationPolicy        = 'Untrusted'
                            PackageManagementProvider = 'NuGet'
                        }
                    }
                }

                It 'Should return the correct result when the Repository is present and all params are passed' {

                    InModuleScope -ScriptBlock {
                        $script:mockPSResourceRepositoryInstance = [PSResourceRepository] @{
                            Name                      = 'FakePSGallery'
                            SourceLocation            = 'https://www.powershellgallery.com/api/v2'
                            ScriptSourceLocation      = 'https://www.powershellgallery.com/api/v2/items/psscript'
                            PublishLocation           = 'https://www.powershellgallery.com/api/v2/package/'
                            ScriptPublishLocation     = 'https://www.powershellgallery.com/api/v2/package/'
                            InstallationPolicy        = 'Untrusted'
                            PackageManagementProvider = 'NuGet'
                        }

                        $currentState = $script:mockPSResourceRepositoryInstance.Get()
                        $currentState.Name                      | Should -Be 'FakePSGallery'
                        $currentState.Ensure                    | Should -Be 'Present'
                        $currentState.SourceLocation            | Should -Be 'https://www.powershellgallery.com/api/v2'
                        $currentState.ScriptSourceLocation      | Should -Be 'https://www.powershellgallery.com/api/v2/items/psscript'
                        $currentState.PublishLocation           | Should -Be 'https://www.powershellgallery.com/api/v2/package/'
                        $currentState.ScriptPublishLocation     | Should -Be 'https://www.powershellgallery.com/api/v2/package/'
                        $currentState.InstallationPolicy        | Should -Be 'Untrusted'
                        $currentState.PackageManagementProvider | Should -Be 'NuGet'

                        Assert-MockCalled Get-PSRepository -Exactly -Times 1 -Scope It
                    }
                }

                It 'Should return the correct result when the Repository is present and the minimum params are passed' {
                    BeforeEach {
                        Mock -CommandName Get-PSRepository -MockWith {
                            return @{
                                Name                      = 'FakePSGallery'
                                SourceLocation            = 'https://www.powershellgallery.com/api/v2'
                                ScriptSourceLocation      = 'https://www.powershellgallery.com/api/v2/items/psscript'
                                PublishLocation           = 'https://www.powershellgallery.com/api/v2/package/'
                                ScriptPublishLocation     = 'https://www.powershellgallery.com/api/v2/package/'
                                InstallationPolicy        = 'Untrusted'
                                PackageManagementProvider = 'NuGet'
                            }
                        }
                    }

                    InModuleScope -ScriptBlock {
                        $script:mockPSResourceRepositoryInstance = [PSResourceRepository] @{
                            Name           = 'FakePSGallery'
                            SourceLocation = 'https://www.powershellgallery.com/api/v2'
                            Ensure         = 'Absent'
                        }
                        $currentState = $script:mockPSResourceRepositoryInstance.Get()
                        $currentState.Name                      | Should -Be 'FakePSGallery'
                        $currentState.Ensure                    | Should -Be 'Present'
                        $currentState.SourceLocation            | Should -Be 'https://www.powershellgallery.com/api/v2'
                        $currentState.ScriptSourceLocation      | Should -Be 'https://www.powershellgallery.com/api/v2/items/psscript'
                        $currentState.PublishLocation           | Should -Be 'https://www.powershellgallery.com/api/v2/package/'
                        $currentState.ScriptPublishLocation     | Should -Be 'https://www.powershellgallery.com/api/v2/package/'
                        $currentState.InstallationPolicy        | Should -Be 'Untrusted'
                        $currentState.PackageManagementProvider | Should -Be 'NuGet'

                        Assert-MockCalled Get-PSRepository -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When the respository should be Absent' {
                BeforeEach {
                    Mock -CommandName Get-PSRepository -MockWith {
                        return $null
                    }
                }

                It 'Should return the correct result when the Repository is Absent' {
                    InModuleScope -ScriptBlock {
                        $script:mockPSResourceRepositoryInstance = [PSResourceRepository] @{
                                Name           = 'FakePSGallery'
                                Ensure         = 'Absent'
                                SourceLocation = 'https://www.powershellgallery.com/api/v2'
                            }

                        $currentState = $script:mockPSResourceRepositoryInstance.Get()
                        $currentState.Name                      | Should -Be 'FakePSGallery'
                        $currentState.SourceLocation            | Should -Be 'https://www.powershellgallery.com/api/v2'
                        $currentState.Ensure                    | Should -Be 'Absent'
                        $currentState.InstallationPolicy        | Should -Be 'Untrusted'
                        $currentState.ScriptSourceLocation      | Should -BeNullOrEmpty
                        $currentState.PublishLocation           | Should -BeNullOrEmpty
                        $currentState.ScriptPublishLocation     | Should -BeNullOrEmpty
                        $currentState.PackageManagementProvider | Should -Be 'NuGet'

                        Assert-MockCalled Get-PSRepository -Exactly -Times 1 -Scope It
                    }
                }
            }
        }

        Context 'When the system is not in the desired state' {
            Context 'When the repository is present but should be absent' {
                BeforeEach {
                    Mock -CommandName Get-PSRepository -MockWith {
                        return @{
                            Name                      = 'FakePSGallery'
                            SourceLocation            = 'https://www.powershellgallery.com/api/v2'
                            ScriptSourceLocation      = 'https://www.powershellgallery.com/api/v2/items/psscript'
                            PublishLocation           = 'https://www.powershellgallery.com/api/v2/package/'
                            ScriptPublishLocation     = 'https://www.powershellgallery.com/api/v2/package/'
                            InstallationPolicy        = 'Untrusted'
                            PackageManagementProvider = 'NuGet'
                        }
                    }
                }

                It 'Should return the correct result when the Repository is present but should be absent' {

                    InModuleScope -ScriptBlock {
                        $script:mockPSResourceRepositoryInstance = [PSResourceRepository] @{
                            Name           = 'FakePSGallery'
                            SourceLocation = 'https://www.powershellgallery.com/api/v2'
                            Ensure         = 'Absent'
                        }
                        $currentState = $script:mockPSResourceRepositoryInstance.Get()
                        $currentState.Name                      | Should -Be 'FakePSGallery'
                        $currentState.Ensure                    | Should -Be 'Present'
                        $currentState.SourceLocation            | Should -Be 'https://www.powershellgallery.com/api/v2'
                        $currentState.ScriptSourceLocation      | Should -Be 'https://www.powershellgallery.com/api/v2/items/psscript'
                        $currentState.PublishLocation           | Should -Be 'https://www.powershellgallery.com/api/v2/package/'
                        $currentState.ScriptPublishLocation     | Should -Be 'https://www.powershellgallery.com/api/v2/package/'
                        $currentState.InstallationPolicy        | Should -Be 'Untrusted'
                        $currentState.PackageManagementProvider | Should -Be 'NuGet'

                        Assert-MockCalled Get-PSRepository -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When the repository is absent but should be present' {
                BeforeEach {
                    Mock -CommandName Get-PSRepository -MockWith {
                        return $null
                    }
                }

                It 'Should return the correct result when the Repository is absent but should be present' {
                    InModuleScope -ScriptBlock {
                        $script:mockPSResourceRepositoryInstance = [PSResourceRepository] @{
                            Name           = 'FakePSGallery'
                            SourceLocation = 'https://www.powershellgallery.com/api/v2'
                            Ensure         = 'Present'
                        }
                        $currentState = $script:mockPSResourceRepositoryInstance.Get()
                        $currentState.Name                      | Should -Be 'FakePSGallery'
                        $currentState.Ensure                    | Should -Be 'Absent'
                        $currentState.SourceLocation            | Should -Be 'https://www.powershellgallery.com/api/v2'
                        $currentState.ScriptSourceLocation      | Should -BeNullOrEmpty
                        $currentState.PublishLocation           | Should -BeNullOrEmpty
                        $currentState.ScriptPublishLocation     | Should -BeNullOrEmpty
                        $currentState.InstallationPolicy        | Should -Be 'Untrusted'
                        $currentState.PackageManagementProvider | Should -Be 'NuGet'

                        Assert-MockCalled Get-PSRepository -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When the repository is present but not in the correct state' {
                BeforeEach {
                    Mock -CommandName Get-PSRepository -MockWith {
                        return @{
                            Name                      = 'FakePSGallery'
                            SourceLocation            = 'https://www.notcorrect.com/api/v2'
                            ScriptSourceLocation      = 'https://www.notcorrect.com/api/v2/items/psscript'
                            PublishLocation           = 'https://www.notcorrect.com/api/v2/package/'
                            ScriptPublishLocation     = 'https://www.notcorrect.com/api/v2/package/'
                            InstallationPolicy        = 'Trusted'
                            PackageManagementProvider = 'Package'
                        }
                    }
                }

                It 'Should return the correct results when the Repository is Present but not in the correct state' {
                    InModuleScope -ScriptBlock {
                        $script:mockPSResourceRepositoryInstance = [PSResourceRepository] @{
                            Name                      = 'FakePSGallery'
                            SourceLocation            = 'https://www.powershellgallery.com/api/v2'
                            ScriptSourceLocation      = 'https://www.powershellgallery.com/api/v2/items/psscript'
                            PublishLocation           = 'https://www.powershellgallery.com/api/v2/package/'
                            ScriptPublishLocation     = 'https://www.powershellgallery.com/api/v2/package/'
                            InstallationPolicy        = 'Untrusted'
                            PackageManagementProvider = 'NuGet'
                            Ensure                    = 'Present'
                        }

                        $currentState = $script:mockPSResourceRepositoryInstance.Get()
                        $currentState.Name                      | Should -Be 'FakePSGallery'
                        $currentState.Ensure                    | Should -Be 'Present'
                        $currentState.SourceLocation            | Should -Be 'https://www.notcorrect.com/api/v2'
                        $currentState.ScriptSourceLocation      | Should -Be 'https://www.notcorrect.com/api/v2/items/psscript'
                        $currentState.PublishLocation           | Should -Be 'https://www.notcorrect.com/api/v2/package/'
                        $currentState.ScriptPublishLocation     | Should -Be 'https://www.notcorrect.com/api/v2/package/'
                        $currentState.InstallationPolicy        | Should -Be 'Trusted'
                        $currentState.PackageManagementProvider | Should -Be 'Package'

                        Assert-MockCalled Get-PSRepository -Exactly -Times 1 -Scope It
                    }
                }

                It 'Should return the correct results when the Repository is Present but should be Absent' {
                    InModuleScope -ScriptBlock {
                        $script:mockPSResourceRepositoryInstance = [PSResourceRepository] @{
                            Name           = 'FakePSGallery'
                            SourceLocation = 'https://www.powershellgallery.com/api/v2'
                            Ensure         = 'Absent'
                        }

                        $currentState = $script:mockPSResourceRepositoryInstance.Get()
                        $currentState.Name                      | Should -Be 'FakePSGallery'
                        $currentState.Ensure                    | Should -Be 'Present'
                        $currentState.SourceLocation            | Should -Be 'https://www.notcorrect.com/api/v2'
                        $currentState.ScriptSourceLocation      | Should -Be 'https://www.notcorrect.com/api/v2/items/psscript'
                        $currentState.PublishLocation           | Should -Be 'https://www.notcorrect.com/api/v2/package/'
                        $currentState.ScriptPublishLocation     | Should -Be 'https://www.notcorrect.com/api/v2/package/'
                        $currentState.InstallationPolicy        | Should -Be 'Trusted'
                        $currentState.PackageManagementProvider | Should -Be 'Package'

                        Assert-MockCalled Get-PSRepository -Exactly -Times 1 -Scope It
                    }
                }
            }
        }
    }

    Describe 'PSResourceRepository\Set()' -Tag 'Set' {
        Context 'When the system is in the desired state' {
        }

        Context 'When the system is not in the desired state' {
        }
    }

    Describe 'PSResourceRepository\Test()' -Tag 'Test' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockPSResourceRepositoryInstance = [PSResourceRepository] @{
                    Name                      = 'FakePSGallery'
                    SourceLocation            = 'https://www.powershellgallery.com/api/v2'
                    ScriptSourceLocation      = 'https://www.powershellgallery.com/api/v2/items/psscript'
                    PublishLocation           = 'https://www.powershellgallery.com/api/v2/package/'
                    ScriptPublishLocation     = 'https://www.powershellgallery.com/api/v2/package/'
                    InstallationPolicy        = 'Untrusted'
                    PackageManagementProvider = 'NuGet'
                }
            }
        }

        Context 'When the system is in the desired state' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockPSResourceRepositoryInstance |
                        # Mock method Compare() which is called by the base method Test ()
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                            return $null
                        }
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    $script:mockPSResourceRepositoryInstance.Test() | Should -BeTrue
                }
            }
        }

        Context 'When the system is not in the desired state' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockPSResourceRepositoryInstance |
                        # Mock method Compare() which is called by the base method Test ()
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                            return @{
                                Property      = 'SourceLocation'
                                ExpectedValue = 'https://www.powershellgallery.com/api/v2'
                                ActualValue   = 'https://www.incorrectpowershellgallery.com/api/v2'
                            }
                        }
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    $script:mockPSResourceRepositoryInstance.Test() | Should -BeFalse
                }
            }
        }
    }

    Describe 'PSResourceRepository\GetCurrentState()' -Tag 'GetCurrentState' {
        Context 'When the system is in the desired state' {
            Context 'When the repository should be Present' {
                BeforeEach {
                    Mock -CommandName Get-PSRepository -MockWith {
                        return @{
                            Name                      = 'FakePSGallery'
                            SourceLocation            = 'https://www.powershellgallery.com/api/v2'
                            ScriptSourceLocation      = 'https://www.powershellgallery.com/api/v2/items/psscript'
                            PublishLocation           = 'https://www.powershellgallery.com/api/v2/package/'
                            ScriptPublishLocation     = 'https://www.powershellgallery.com/api/v2/package/'
                            InstallationPolicy        = 'Untrusted'
                            PackageManagementProvider = 'NuGet'
                        }
                    }
                }

                It 'Should return the correct result when the Repository is present and all params are passed' {

                    InModuleScope -ScriptBlock {
                        $script:mockPSResourceRepositoryInstance = [PSResourceRepository] @{
                            Name                      = 'FakePSGallery'
                            SourceLocation            = 'https://www.powershellgallery.com/api/v2'
                            ScriptSourceLocation      = 'https://www.powershellgallery.com/api/v2/items/psscript'
                            PublishLocation           = 'https://www.powershellgallery.com/api/v2/package/'
                            ScriptPublishLocation     = 'https://www.powershellgallery.com/api/v2/package/'
                            InstallationPolicy        = 'Untrusted'
                            PackageManagementProvider = 'NuGet'
                        }

                        $currentState = $script:mockPSResourceRepositoryInstance.GetCurrentState(@{
                                Name                      = 'FakePSGallery'
                                SourceLocation            = 'https://www.powershellgallery.com/api/v2'
                                ScriptSourceLocation      = 'https://www.powershellgallery.com/api/v2/items/psscript'
                                PublishLocation           = 'https://www.powershellgallery.com/api/v2/package/'
                                ScriptPublishLocation     = 'https://www.powershellgallery.com/api/v2/package/'
                                InstallationPolicy        = 'Untrusted'
                                PackageManagementProvider = 'NuGet'
                            })

                        $currentState.Name                      | Should -Be 'FakePSGallery'
                        $currentState.Ensure                    | Should -Be 'Present'
                        $currentState.SourceLocation            | Should -Be 'https://www.powershellgallery.com/api/v2'
                        $currentState.ScriptSourceLocation      | Should -Be 'https://www.powershellgallery.com/api/v2/items/psscript'
                        $currentState.PublishLocation           | Should -Be 'https://www.powershellgallery.com/api/v2/package/'
                        $currentState.ScriptPublishLocation     | Should -Be 'https://www.powershellgallery.com/api/v2/package/'
                        $currentState.InstallationPolicy        | Should -Be 'Untrusted'
                        $currentState.PackageManagementProvider | Should -Be 'NuGet'

                        Assert-MockCalled Get-PSRepository -Exactly -Times 1 -Scope It
                    }
                }

                It 'Should return the correct result when the Repository is present and the minimum params are passed' {
                    BeforeEach {
                        Mock -CommandName Get-PSRepository -MockWith {
                            return @{
                                Name                      = 'FakePSGallery'
                                SourceLocation            = 'https://www.powershellgallery.com/api/v2'
                                ScriptSourceLocation      = 'https://www.powershellgallery.com/api/v2/items/psscript'
                                PublishLocation           = 'https://www.powershellgallery.com/api/v2/package/'
                                ScriptPublishLocation     = 'https://www.powershellgallery.com/api/v2/package/'
                                InstallationPolicy        = 'Untrusted'
                                PackageManagementProvider = 'NuGet'
                            }
                        }
                    }

                    InModuleScope -ScriptBlock {
                        $script:mockPSResourceRepositoryInstance = [PSResourceRepository] @{
                            Name           = 'FakePSGallery'
                            SourceLocation = 'https://www.powershellgallery.com/api/v2'
                            Ensure         = 'Absent'
                        }
                        $currentState = $script:mockPSResourceRepositoryInstance.GetCurrentState()
                        $currentState.Name                      | Should -Be 'FakePSGallery'
                        $currentState.Ensure                    | Should -Be 'Present'
                        $currentState.SourceLocation            | Should -Be 'https://www.powershellgallery.com/api/v2'
                        $currentState.ScriptSourceLocation      | Should -Be 'https://www.powershellgallery.com/api/v2/items/psscript'
                        $currentState.PublishLocation           | Should -Be 'https://www.powershellgallery.com/api/v2/package/'
                        $currentState.ScriptPublishLocation     | Should -Be 'https://www.powershellgallery.com/api/v2/package/'
                        $currentState.InstallationPolicy        | Should -Be 'Untrusted'
                        $currentState.PackageManagementProvider | Should -Be 'NuGet'

                        Assert-MockCalled Get-PSRepository -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When the respository should be Absent' {
                BeforeEach {
                    Mock -CommandName Get-PSRepository -MockWith {
                        return $null
                    }
                }

                It 'Should return the correct result when the Repository is Absent' {
                    InModuleScope -ScriptBlock {
                        $script:mockPSResourceRepositoryInstance = [PSResourceRepository] @{
                                Name           = 'FakePSGallery'
                                Ensure         = 'Absent'
                                SourceLocation = 'https://www.powershellgallery.com/api/v2'
                            }

                        $currentState = $script:mockPSResourceRepositoryInstance.GetCurrentState()
                        $currentState.Name                      | Should -Be 'FakePSGallery'
                        $currentState.SourceLocation            | Should -Be 'https://www.powershellgallery.com/api/v2'
                        $currentState.Ensure                    | Should -Be 'Absent'
                        $currentState.InstallationPolicy        | Should -Be 'Untrusted'
                        $currentState.ScriptSourceLocation      | Should -BeNullOrEmpty
                        $currentState.PublishLocation           | Should -BeNullOrEmpty
                        $currentState.ScriptPublishLocation     | Should -BeNullOrEmpty
                        $currentState.PackageManagementProvider | Should -Be 'NuGet'

                        Assert-MockCalled Get-PSRepository -Exactly -Times 1 -Scope It
                    }
                }
            }
        }

        Context 'When the system is not in the desired state' {
            Context 'When the repository is present but should be absent' {
                BeforeEach {
                    Mock -CommandName Get-PSRepository -MockWith {
                        return @{
                            Name                      = 'FakePSGallery'
                            SourceLocation            = 'https://www.powershellgallery.com/api/v2'
                            ScriptSourceLocation      = 'https://www.powershellgallery.com/api/v2/items/psscript'
                            PublishLocation           = 'https://www.powershellgallery.com/api/v2/package/'
                            ScriptPublishLocation     = 'https://www.powershellgallery.com/api/v2/package/'
                            InstallationPolicy        = 'Untrusted'
                            PackageManagementProvider = 'NuGet'
                        }
                    }
                }

                It 'Should return the correct result when the Repository is present but should be absent' {

                    InModuleScope -ScriptBlock {
                        $script:mockPSResourceRepositoryInstance = [PSResourceRepository] @{
                            Name           = 'FakePSGallery'
                            SourceLocation = 'https://www.powershellgallery.com/api/v2'
                            Ensure         = 'Absent'
                        }
                        $currentState = $script:mockPSResourceRepositoryInstance.GetCurrentState()
                        $currentState.Name                      | Should -Be 'FakePSGallery'
                        $currentState.Ensure                    | Should -Be 'Present'
                        $currentState.SourceLocation            | Should -Be 'https://www.powershellgallery.com/api/v2'
                        $currentState.ScriptSourceLocation      | Should -Be 'https://www.powershellgallery.com/api/v2/items/psscript'
                        $currentState.PublishLocation           | Should -Be 'https://www.powershellgallery.com/api/v2/package/'
                        $currentState.ScriptPublishLocation     | Should -Be 'https://www.powershellgallery.com/api/v2/package/'
                        $currentState.InstallationPolicy        | Should -Be 'Untrusted'
                        $currentState.PackageManagementProvider | Should -Be 'NuGet'

                        Assert-MockCalled Get-PSRepository -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When the repository is absent but should be present' {
                BeforeEach {
                    Mock -CommandName Get-PSRepository -MockWith {
                        return $null
                    }
                }

                It 'Should return the correct result when the Repository is absent but should be present' {
                    InModuleScope -ScriptBlock {
                        $script:mockPSResourceRepositoryInstance = [PSResourceRepository] @{
                            Name           = 'FakePSGallery'
                            SourceLocation = 'https://www.powershellgallery.com/api/v2'
                            Ensure         = 'Present'
                        }
                        $currentState = $script:mockPSResourceRepositoryInstance.GetCurrentState()
                        $currentState.Name                      | Should -Be 'FakePSGallery'
                        $currentState.Ensure                    | Should -Be 'Absent'
                        $currentState.SourceLocation            | Should -Be 'https://www.powershellgallery.com/api/v2'
                        $currentState.ScriptSourceLocation      | Should -BeNullOrEmpty
                        $currentState.PublishLocation           | Should -BeNullOrEmpty
                        $currentState.ScriptPublishLocation     | Should -BeNullOrEmpty
                        $currentState.InstallationPolicy        | Should -Be 'Untrusted'
                        $currentState.PackageManagementProvider | Should -Be 'NuGet'

                        Assert-MockCalled Get-PSRepository -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When the repository is present but not in the correct state' {
                BeforeEach {
                    Mock -CommandName Get-PSRepository -MockWith {
                        return @{
                            Name                      = 'FakePSGallery'
                            SourceLocation            = 'https://www.notcorrect.com/api/v2'
                            ScriptSourceLocation      = 'https://www.notcorrect.com/api/v2/items/psscript'
                            PublishLocation           = 'https://www.notcorrect.com/api/v2/package/'
                            ScriptPublishLocation     = 'https://www.notcorrect.com/api/v2/package/'
                            InstallationPolicy        = 'Trusted'
                            PackageManagementProvider = 'Package'
                        }
                    }
                }

                It 'Should return the correct results when the Repository is Present but not in the correct state' {
                    InModuleScope -ScriptBlock {
                        $script:mockPSResourceRepositoryInstance = [PSResourceRepository] @{
                            Name                      = 'FakePSGallery'
                            SourceLocation            = 'https://www.powershellgallery.com/api/v2'
                            ScriptSourceLocation      = 'https://www.powershellgallery.com/api/v2/items/psscript'
                            PublishLocation           = 'https://www.powershellgallery.com/api/v2/package/'
                            ScriptPublishLocation     = 'https://www.powershellgallery.com/api/v2/package/'
                            InstallationPolicy        = 'Untrusted'
                            PackageManagementProvider = 'NuGet'
                            Ensure                    = 'Present'
                        }

                        $currentState = $script:mockPSResourceRepositoryInstance.GetCurrentState()
                        $currentState.Name                      | Should -Be 'FakePSGallery'
                        $currentState.Ensure                    | Should -Be 'Present'
                        $currentState.SourceLocation            | Should -Be 'https://www.notcorrect.com/api/v2'
                        $currentState.ScriptSourceLocation      | Should -Be 'https://www.notcorrect.com/api/v2/items/psscript'
                        $currentState.PublishLocation           | Should -Be 'https://www.notcorrect.com/api/v2/package/'
                        $currentState.ScriptPublishLocation     | Should -Be 'https://www.notcorrect.com/api/v2/package/'
                        $currentState.InstallationPolicy        | Should -Be 'Trusted'
                        $currentState.PackageManagementProvider | Should -Be 'Package'

                        Assert-MockCalled Get-PSRepository -Exactly -Times 1 -Scope It
                    }
                }

                It 'Should return the correct results when the Repository is Present but should be Absent' {
                    InModuleScope -ScriptBlock {
                        $script:mockPSResourceRepositoryInstance = [PSResourceRepository] @{
                            Name           = 'FakePSGallery'
                            SourceLocation = 'https://www.powershellgallery.com/api/v2'
                            Ensure         = 'Absent'
                        }

                        $currentState = $script:mockPSResourceRepositoryInstance.GetCurrentState()
                        $currentState.Name                      | Should -Be 'FakePSGallery'
                        $currentState.Ensure                    | Should -Be 'Present'
                        $currentState.SourceLocation            | Should -Be 'https://www.notcorrect.com/api/v2'
                        $currentState.ScriptSourceLocation      | Should -Be 'https://www.notcorrect.com/api/v2/items/psscript'
                        $currentState.PublishLocation           | Should -Be 'https://www.notcorrect.com/api/v2/package/'
                        $currentState.ScriptPublishLocation     | Should -Be 'https://www.notcorrect.com/api/v2/package/'
                        $currentState.InstallationPolicy        | Should -Be 'Trusted'
                        $currentState.PackageManagementProvider | Should -Be 'Package'

                        Assert-MockCalled Get-PSRepository -Exactly -Times 1 -Scope It
                    }
                }
            }
        }
    }

    Describe 'PSResourceRepository\Modify()' -Tag 'Modify' {
        Context 'When the system is not in the desired state' {
        }
    }

    # Describe 'PSResourceRepository\CheckProxyConfiguration()' -Tag 'CheckProxyConfiguration' {
    #     Context 'When ProxyCredential is passed with Proxy' {
    #         BeforeAll {
    #             $securePassword = New-Object -Type SecureString
    #             $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'USER', $securePassword
    #             InModuleScope -ScriptBlock {
    #                 $script:mockPSResourceRepositoryInstanceFull = [PSResourceRepository] @{
    #                     Name            = 'FakePSGallery'
    #                     SourceLocation  = 'https://www.powershellgallery.com/api/v2'
    #                     Proxy           = 'https://fakeproxy.com'
    #                     ProxyCredential = $credential
    #                 }

    #                 $script:mockPSResourceRepositoryInstanceCred = [PSResourceRepository] @{
    #                     Name            = 'FakePSGallery'
    #                     SourceLocation  = 'https://www.powershellgallery.com/api/v2'
    #                     ProxyCredential = $credential
    #                 }

    #                 $script:mockPSResourceRepositoryInstanceProxy = [PSResourceRepository] @{
    #                     Name           = 'FakePSGallery'
    #                     SourceLocation = 'https://www.powershellgallery.com/api/v2'
    #                     Proxy          = 'https://fakeproxy.com'
    #                 }
    #             }
    #         }

    #         It 'Should not throw when ProxyCredential is passed with Proxy' {
    #             InModuleScope -ScriptBlock {
    #                 $script:mockPSResourceRepositoryInstanceFull.CheckProxyConfiguration() | Should -Not -Throw
    #             }
    #         }

    #         It 'Should throw when ProxyCredential is passed without Proxy' {
    #             InModuleScope -ScriptBlock {
    #                 $script:mockPSResourceRepositoryInstanceCred.CheckProxyConfiguration() | Should -Throw
    #             }
    #         }

    #         It 'Should not throw when Proxy is passed without ProxyCredential' {
    #             InModuleScope -ScriptBlock {
    #                 $script:mockPSResourceRepositoryInstanceProxy.CheckProxyConfiguration() | Should -Not -Throw
    #             }
    #         }
    #     }
    # }

    Describe 'PSResourceRepository\AssertProperties()' -Tag 'AssertProperties' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockPSResourceRepositoryInstance = [PSResourceRepository] @{}
            }
        }
        Context 'When passing dependant parameters' {
            Context 'When passing ProxyCredential without Proxy' {
                It 'Should throw the correct error' {
                    InModuleScope -ScriptBlock {
                        {
                            $securePassword = New-Object -Type SecureString
                            $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'USER', $securePassword
                            $mockPSResourceRepositoryInstance.ProxyCredental = $credential
                            $mockPSResourceRepositoryInstance.AssertProperties() | Should -Throw -ExpectedMessage 'Proxy Credential passed without Proxy Uri.'
                        }
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
