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
            Context 'When the repository is Present with default values' {
                It 'Should return the correct result when the Repository is present and default params are passed' {

                    InModuleScope -ScriptBlock {
                        $script:mockPSResourceRepositoryInstance = [PSResourceRepository] @{
                            Name                      = 'FakePSGallery'
                            SourceLocation            = 'https://www.powershellgallery.com/api/v2'
                        }

                        <#
                            This mocks the method GetCurrentState().
                            Method Get() will call the base method Get() which will
                            call back to the derived class method GetCurrentState()
                            to get the result to return from the derived method Get().
                        #>
                        $script:mockPSResourceRepositoryInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return [System.Collections.Hashtable] @{
                                Name                      = 'FakePSGallery'
                                SourceLocation            = 'https://www.powershellgallery.com/api/v2'
                                Ensure                    = 'Present'
                                InstallationPolicy        = 'Untrusted'
                                PackageManagementProvider = 'Nuget'
                            }
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        }

                        $currentState = $script:mockPSResourceRepositoryInstance.Get()
                        $currentState.Name                      | Should -Be 'FakePSGallery'
                        $currentState.Ensure                    | Should -Be 'Present'
                        $currentState.SourceLocation            | Should -Be 'https://www.powershellgallery.com/api/v2'
                        $currentState.ScriptSourceLocation      | Should -BeNullOrEmpty
                        $currentState.PublishLocation           | Should -BeNullOrEmpty
                        $currentState.ScriptPublishLocation     | Should -BeNullOrEmpty
                        $currentState.InstallationPolicy        | Should -Be 'Untrusted'
                        $currentState.PackageManagementProvider | Should -Be 'NuGet'
                    }
                }

                It 'Should return the correct result when the Repository is Present and all properties are passed' {
                    InModuleScope -ScriptBlock {
                        $script:mockPSResourceRepositoryInstance = [PSResourceRepository] @{
                            Name                      = 'FakePSGallery'
                            SourceLocation            = 'https://www.powershellgallery.com/api/v2'
                            Ensure                    = 'Present'
                            ScriptSourceLocation      = 'https://www.powershellgallery.com/api/v2/items/psscript'
                            PublishLocation           = 'https://www.powershellgallery.com/api/v2/package/'
                            ScriptPublishLocation     = 'https://www.powershellgallery.com/api/v2/package/'
                            InstallationPolicy        = 'Untrusted'
                            PackageManagementProvider = 'NuGet'
                        }

                        $script:mockPSResourceRepositoryInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return [System.Collections.Hashtable] @{
                                Name                      = 'FakePSGallery'
                                SourceLocation            = 'https://www.powershellgallery.com/api/v2'
                                ScriptSourceLocation      = 'https://www.powershellgallery.com/api/v2/items/psscript'
                                PublishLocation           = 'https://www.powershellgallery.com/api/v2/package/'
                                ScriptPublishLocation     = 'https://www.powershellgallery.com/api/v2/package/'
                                InstallationPolicy        = 'Untrusted'
                                PackageManagementProvider = 'NuGet'
                                Ensure                    = 'Present'
                            }
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
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
                    }
                }
            }

            Context 'When the respository should be Absent' {
                It 'Should return the correct result when the Repository is Absent' {
                    InModuleScope -ScriptBlock {
                        $script:mockPSResourceRepositoryInstance = [PSResourceRepository] @{
                            Name           = 'FakePSGallery'
                            Ensure         = 'Absent'
                            SourceLocation = 'https://www.powershellgallery.com/api/v2'
                        }
                        $script:mockPSResourceRepositoryInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return [System.Collections.Hashtable] @{
                                Name           = 'FakePSGallery'
                                SourceLocation = 'https://www.powershellgallery.com/api/v2'
                                Ensure         = 'Absent'
                            }
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
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
                    }
                }
            }
        }

        Context 'When the system is not in the desired state' {
            Context 'When the repository is present but should be absent' {
                It 'Should return the correct result when the Repository is present but should be absent' {

                    InModuleScope -ScriptBlock {
                        $script:mockPSResourceRepositoryInstance = [PSResourceRepository] @{
                            Name           = 'FakePSGallery'
                            SourceLocation = 'https://www.powershellgallery.com/api/v2'
                            Ensure         = 'Absent'
                        }
                        $script:mockPSResourceRepositoryInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return [System.Collections.Hashtable] @{
                                Name                      = 'FakePSGallery'
                                Ensure                    = 'Present'
                                SourceLocation            = 'https://www.powershellgallery.com/api/v2'
                                ScriptSourceLocation      = 'https://www.powershellgallery.com/api/v2/items/psscript'
                                PublishLocation           = 'https://www.powershellgallery.com/api/v2/package/'
                                ScriptPublishLocation     = 'https://www.powershellgallery.com/api/v2/package/'
                                InstallationPolicy        = 'Untrusted'
                                PackageManagementProvider = 'NuGet'
                            }
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
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
                    }
                }
            }

            Context 'When the repository is absent but should be present' {
                It 'Should return the correct result when the Repository is absent but should be present' {
                    InModuleScope -ScriptBlock {
                        $script:mockPSResourceRepositoryInstance = [PSResourceRepository] @{
                            Name           = 'FakePSGallery'
                            SourceLocation = 'https://www.powershellgallery.com/api/v2'
                            Ensure         = 'Present'
                        }
                        $script:mockPSResourceRepositoryInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return [System.Collections.Hashtable] @{
                                Name                      = 'FakePSGallery'
                                Ensure                    = 'Absent'
                                SourceLocation            = 'https://www.powershellgallery.com/api/v2'
                                InstallationPolicy        = 'Untrusted'
                                PackageManagementProvider = 'NuGet'
                            }
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
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
                    }
                }
            }

            Context 'When the repository is present but not in the correct state' {
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
                        $script:mockPSResourceRepositoryInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return [System.Collections.Hashtable] @{
                                Name                      = 'FakePSGallery'
                                Ensure                    = 'Present'
                                SourceLocation            = 'https://www.notcorrect.com/api/v2'
                                ScriptSourceLocation      = 'https://www.notcorrect.com/api/v2/items/psscript'
                                PublishLocation           = 'https://www.notcorrect.com/api/v2/package/'
                                ScriptPublishLocation     = 'https://www.notcorrect.com/api/v2/package/'
                                InstallationPolicy        = 'Trusted'
                                PackageManagementProvider = 'Package'
                            }
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
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
                    }
                }

                It 'Should return the correct results when the Repository is Present but should be Absent' {
                    InModuleScope -ScriptBlock {
                        $script:mockPSResourceRepositoryInstance = [PSResourceRepository] @{
                            Name           = 'FakePSGallery'
                            SourceLocation = 'https://www.powershellgallery.com/api/v2'
                            Ensure         = 'Absent'
                        }
                        $script:mockPSResourceRepositoryInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return [System.Collections.Hashtable] @{
                                Name                      = 'FakePSGallery'
                                Ensure                    = 'Present'
                                SourceLocation            = 'https://www.notcorrect.com/api/v2'
                                ScriptSourceLocation      = 'https://www.notcorrect.com/api/v2/items/psscript'
                                PublishLocation           = 'https://www.notcorrect.com/api/v2/package/'
                                ScriptPublishLocation     = 'https://www.notcorrect.com/api/v2/package/'
                                InstallationPolicy        = 'Trusted'
                                PackageManagementProvider = 'Package'
                            }
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
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
                    }
                }
            }
        }
    }

    Describe 'PSResourceRepository\Set()' -Tag 'Set' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockPSResourceRepositoryInstance = [PSResourceRepository] @{
                    Name           = 'FakePSGallery'
                    SourceLocation = 'https://www.powershellgallery.com/api/v2'
                    Ensure         = 'Present'
                } |
                    # Mock method Modify which is called by the base method Set().
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Modify' -Value {
                        $script:mockMethodModifyCallCount += 1
                    } -PassThru
            }
        }

        BeforeEach {
            InModuleScope -ScriptBlock {
                $script:mockMethodModifyCallCount = 0
            }
        }

        Context 'When the system is in the desired state' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockPSResourceRepositoryInstance |
                        # Mock method Compare() which is called by the base method Set()
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                            return $null
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        }
                }
            }

            It 'Should not call method Modify()' {
                InModuleScope -ScriptBlock {
                    $script:mockPSResourceRepositoryInstance.Set()

                    $script:mockMethodModifyCallCount | Should -Be 0
                }
            }
        }

        Context 'When the system is not in the desired state' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockPSResourceRepositoryInstance |
                        # Mock method Compare() which is called by the base method Set()
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                            return @{
                                Property      = 'SourceLocation'
                                ExpectedValue = 'https://www.fakegallery.com/api/v2'
                                ActualValue   = 'https://www.powershellgallery.com/api/v2'
                            }
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        }
                }
            }

            It 'Should call method Modify()' {
                InModuleScope -ScriptBlock {
                    $script:mockPSResourceRepositoryInstance.Set()
                    $script:mockMethodModifyCallCount | Should -Be 1
                }
            }
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
                        $currentState = $script:mockPSResourceRepositoryInstance.GetCurrentState(@{
                                Name           = 'FakePSGallery'
                                SourceLocation = 'https://www.powershellgallery.com/api/v2'
                                Ensure         = 'Absent'
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

                        $currentState = $script:mockPSResourceRepositoryInstance.GetCurrentState(@{
                                Name                      = 'FakePSGallery'
                                Ensure                    = 'Absent'
                                SourceLocation            = 'https://www.powershellgallery.com/api/v2'
                                InstallationPolicy        = 'Untrusted'
                                PackageManagementProvider = 'NuGet'
                            })
                        $currentState.Name                      | Should -Be 'FakePSGallery'
                        $currentState.SourceLocation            | Should -Be 'https://www.powershellgallery.com/api/v2'
                        $currentState.Ensure                    | Should -Be 'Absent'
                        $currentState.InstallationPolicy        | Should -BeNullOrEmpty
                        $currentState.ScriptSourceLocation      | Should -BeNullOrEmpty
                        $currentState.PublishLocation           | Should -BeNullOrEmpty
                        $currentState.ScriptPublishLocation     | Should -BeNullOrEmpty
                        $currentState.PackageManagementProvider | Should -BeNullOrEmpty

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
                        $currentState = $script:mockPSResourceRepositoryInstance.GetCurrentState(@{
                                Name                      = 'FakePSGallery'
                                SourceLocation            = 'https://www.powershellgallery.com/api/v2'
                                Ensure                    = 'Absent'
                                PackageManagementProvider = 'Nuget'
                                InstallationPolicy        = 'Untrusted'
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
                        $currentState = $script:mockPSResourceRepositoryInstance.GetCurrentState(@{
                            Name                      = 'FakePSGallery'
                            SourceLocation            = 'https://www.powershellgallery.com/api/v2'
                            Ensure                    = 'Present'
                            PackageManagementProvider = 'Nuget'
                            InstallationPolicy        = 'Untrusted'
                        })
                        $currentState.Name                      | Should -Be 'FakePSGallery'
                        $currentState.Ensure                    | Should -Be 'Absent'
                        $currentState.SourceLocation            | Should -Be 'https://www.powershellgallery.com/api/v2'
                        $currentState.ScriptSourceLocation      | Should -BeNullOrEmpty
                        $currentState.PublishLocation           | Should -BeNullOrEmpty
                        $currentState.ScriptPublishLocation     | Should -BeNullOrEmpty
                        $currentState.InstallationPolicy        | Should -BeNullOrEmpty
                        $currentState.PackageManagementProvider | Should -BeNullOrEmpty

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

                        $currentState = $script:mockPSResourceRepositoryInstance.GetCurrentState(@{
                                Name                      = 'FakePSGallery'
                                SourceLocation            = 'https://www.powershellgallery.com/api/v2'
                                ScriptSourceLocation      = 'https://www.powershellgallery.com/api/v2/items/psscript'
                                PublishLocation           = 'https://www.powershellgallery.com/api/v2/package/'
                                ScriptPublishLocation     = 'https://www.powershellgallery.com/api/v2/package/'
                                InstallationPolicy        = 'Untrusted'
                                PackageManagementProvider = 'NuGet'
                                Ensure                    = 'Present'
                            })
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

                        $currentState = $script:mockPSResourceRepositoryInstance.GetCurrentState(@{
                            Name           = 'FakePSGallery'
                            SourceLocation = 'https://www.powershellgallery.com/api/v2'
                            Ensure         = 'Absent'
                        })
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
        Context 'When the system is not in the desired state and the repository is not registered' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockPSResourceRepositoryInstance = [PSResourceRepository] @{
                        Name           = 'FakePSGallery'
                        SourceLocation = 'https://www.powershellgallery.com/api/v2'
                        Ensure         = 'Present'
                    }

                    Mock -CommandName Register-PSRepository
                }
            }

            It 'Should call the correct mock' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceRepositoryInstance.Modify(@{
                            Ensure         = 'Present'
                            SourceLocation = 'https://www.fakepsgallery.com/api/v2'
                            }
                        )
                    } | Should -Not -Throw

                    Assert-MockCalled -CommandName Register-PSRepository -Exactly -Times 1 -Scope It
                }
            }

            It 'Should call throw the correct InvalidArgumentException when SourceLocation is not set' {
                InModuleScope -ScriptBlock {
                    {
                        $script:mockPSResourceRepositoryInstance.SourceLocation = $null
                        $script:mockPSResourceRepositoryInstance.Modify(@{
                            Ensure         = 'Present'
                            }
                        )
                    } | Should -Throw -ExpectedMessage 'SourceLocation is a required parameter to register a repository.'
                }
            }
        }

        Context 'When the system is not in the desired state and the repository is registered' {
            Context 'When the repository is present but should be absent' {
                BeforeAll {
                    InModuleScope -ScriptBlock {
                        $script:mockPSResourceRepositoryInstance = [PSResourceRepository]@{
                            Name           = 'FakePSGallery'
                            SourceLocation = 'https://www.powershellgallery.com/api/v2'
                            Ensure         = 'Absent'
                         }
                    }

                    Mock -CommandName Unregister-PSRepository
                }

                It 'Should call the correct mock' {

                    InModuleScope -ScriptBlock {
                        {
                            $script:mockPSResourceRepositoryInstance.Modify(@{
                                Ensure = 'Absent'
                                }
                            )
                        } | Should -Not -Throw

                        Assert-MockCalled -CommandName Unregister-PSRepository -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When the repository is present but not in desired state' {
                BeforeAll {
                    InModuleScope -ScriptBlock {
                        $script:mockPSResourceRepositoryInstance = [PSResourceRepository] @{
                            Name           = 'FakePSGallery'
                            SourceLocation = 'https://www.powershellgallery.com/api/v2'
                            Ensure         = 'Present'
                         }
                    }

                    Mock -CommandName Set-PSRepository
                }

                It 'Should call the correct mock' {
                    InModuleScope -ScriptBlock {
                        {
                            $script:mockPSResourceRepositoryInstance.Modify(@{
                                SourceLocation = 'https://www.fakepsgallery.com/api/v2'
                                }
                            )
                        } | Should -Not -Throw

                        Assert-MockCalled -CommandName Set-PSRepository -Exactly -Times 1 -Scope It
                    }
                }
            }
        }
    }

    Describe 'PSResourceRepository\AssertProperties()' -Tag 'AssertProperties' {
        BeforeEach {
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
                            $script:mockPSResourceRepositoryInstance.ProxyCredental = $credential
                            $script:mockPSResourceRepositoryInstance.AssertProperties() | Should -Throw -ExpectedMessage 'Proxy Credential passed without Proxy Uri.'
                        }
                    }
                }
            }

            Context 'When dealing with PSGallery parameters' {
                It 'Should throw the correct error when Default true is not passed with name PSGallery' {
                    InModuleScope -ScriptBlock {
                        {
                            $script:mockPSResourceRepositoryInstance.Name = 'PSGallery'
                            $script:mockPSResourceRepositoryInstance.Default = $false
                            $script:mockPSResourceRepositoryInstance.AssertProperties() | Should -Throw -ExpectedMessage 'The parameter Default must be set to True for a repository named PSGallery.'
                        }
                    }
                }

                It 'Should not throw when Default is not true and name is PSGallery but ensure is absent' {
                    InModuleScope -ScriptBlock {
                        {
                            $script:mockPSResourceRepositoryInstance.Name = 'PSGallery'
                            $script:mockPSResourceRepositoryInstance.Ensure = 'Absent'
                            $script:mockPSResourceRepositoryInstance.Default = $false
                            $script:mockPSResourceRepositoryInstance.AssertProperties() | Should -Not -Throw
                        }
                    }
                }

                It 'Should throw the correct error when Default true is passed without the name PSGallery' {
                    InModuleScope -ScriptBlock {
                        {
                            $script:mockPSResourceRepositoryInstance.Name = 'NotTheDefaultPSGallery'
                            $script:mockPSResourceRepositoryInstance.Default = $true
                            $script:mockPSResourceRepositoryInstance.AssertProperties() | Should -Throw -ExpectedMessage 'The parameter Default may only be used with repositories named PSGallery'
                        }
                    }
                }

                It 'Should throw the correct error when Default true is passed with SourceLocation' {
                    InModuleScope -ScriptBlock {
                        {
                            $script:mockPSResourceRepositoryInstance.Name = 'PSGallery'
                            $script:mockPSResourceRepositoryInstance.Default = $true
                            $script:mockPSResourceRepositoryInstance.SourceLocation = 'https://notaurl.com/'
                            $script:mockPSResourceRepositoryInstance.AssertProperties() | Should -Throw -ExpectedMessage 'The parameter Default may not be used with parameters other than InstallationPolicy, Proxy, and ProxyCredential.'
                        }
                    }
                }

                It 'Should throw the correct error when Default true is passed with Credential' {
                    InModuleScope -ScriptBlock {
                        {
                            $script:mockPSResourceRepositoryInstance.Name = 'PSGallery'
                            $script:mockPSResourceRepositoryInstance.Default = $true
                            $script:mockPSResourceRepositoryInstance.Credential = $credential
                            $script:mockPSResourceRepositoryInstance.AssertProperties() | Should -Throw -ExpectedMessage 'The parameter Default may not be used with parameters other than InstallationPolicy, Proxy, and ProxyCredential.'
                        }
                    }
                }

                It 'Should throw the correct error when Default true is passed with ScriptSourceLocation' {
                    InModuleScope -ScriptBlock {
                        {
                            $script:mockPSResourceRepositoryInstance.Name = 'PSGallery'
                            $script:mockPSResourceRepositoryInstance.Default = $true
                            $script:mockPSResourceRepositoryInstance.ScriptSourceLocation = 'https://notaurl.com/'
                            $script:mockPSResourceRepositoryInstance.AssertProperties() | Should -Throw -ExpectedMessage 'The parameter Default may not be used with parameters other than InstallationPolicy, Proxy, and ProxyCredential.'
                        }
                    }
                }

                It 'Should throw the correct error when Default true is passed with PublishLocation' {
                    InModuleScope -ScriptBlock {
                        {
                            $script:mockPSResourceRepositoryInstance.Name = 'PSGallery'
                            $script:mockPSResourceRepositoryInstance.Default = $true
                            $script:mockPSResourceRepositoryInstance.PublishLocation = 'https://notaurl.com/'
                            $script:mockPSResourceRepositoryInstance.AssertProperties() | Should -Throw -ExpectedMessage 'The parameter Default may not be used with parameters other than InstallationPolicy, Proxy, and ProxyCredential.'
                        }
                    }
                }

                It 'Should throw the correct error when Default true is passed with ScriptPublishLocation' {
                    InModuleScope -ScriptBlock {
                        {
                            $script:mockPSResourceRepositoryInstance.Name = 'PSGallery'
                            $script:mockPSResourceRepositoryInstance.Default = $true
                            $script:mockPSResourceRepositoryInstance.ScriptPublishLocation = 'https://notaurl.com/'
                            $script:mockPSResourceRepositoryInstance.AssertProperties() | Should -Throw -ExpectedMessage 'The parameter Default may not be used with parameters other than InstallationPolicy, Proxy, and ProxyCredential.'
                        }
                    }
                }

                It 'Should throw the correct error when Default true is passed with PackageManagementProvider' {
                    InModuleScope -ScriptBlock {
                        {
                            $script:mockPSResourceRepositoryInstance.Name = 'PSGallery'
                            $script:mockPSResourceRepositoryInstance.Default = $true
                            $script:mockPSResourceRepositoryInstance.PackageManagementProvider = 'Package'
                            $script:mockPSResourceRepositoryInstance.AssertProperties() | Should -Throw -ExpectedMessage 'The parameter Default may not be used with parameters other than InstallationPolicy, Proxy, and ProxyCredential.'
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
