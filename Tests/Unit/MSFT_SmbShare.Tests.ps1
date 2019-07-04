#region HEADER
$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'MSFT_SmbShare'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

# Unit Test Template Version: 1.2.4
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath 'DscResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -ResourceType 'Mof' `
    -TestType Unit
#endregion HEADER

function Invoke-TestSetup
{
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

try
{
    Invoke-TestSetup

    InModuleScope $script:DSCResourceName {
        $mockShareName = 'TestShare'
        $mockChangePermissionUserName = @('User1')
        $mockReadPermissionUserName = @('User2')
        $mockFullPermissionUserName = @('User3', 'User4')
        $mockNoPermissionUserName = @('DeniedUser1')

        $mockSmbShare = (
            New-Object -TypeName Object |
            Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockShareName -PassThru |
            Add-Member -MemberType NoteProperty -Name 'Path' -Value 'c:\temp' -PassThru |
            Add-Member -MemberType NoteProperty -Name 'Description' 'Dummy share for unit testing' -PassThru |
            Add-Member -MemberType NoteProperty -Name 'ConcurrentUserLimit' -Value 10 -PassThru |
            Add-Member -MemberType NoteProperty -Name 'EncryptData' -Value $false -PassThru |
            # 0 AccessBased | 1 Unrestricted
            Add-Member -MemberType NoteProperty -Name 'FolderEnumerationMode' -Value 'AccessBased' -PassThru |
            # 0 Pending | 1 Online | 2 Offline
            Add-Member -MemberType NoteProperty -Name 'ShareState' -Value 'Online' -PassThru |
            Add-Member -MemberType NoteProperty -Name 'ShareType' -Value 'FileSystemDirectory' -PassThru |
            Add-Member -MemberType NoteProperty -Name 'ShadowCopy' -Value $false -PassThru |
            Add-Member -MemberType NoteProperty -Name 'CachingMode' -Value 'Manual' -PassThru |
            Add-Member -MemberType NoteProperty -Name 'ContinuouslyAvailable' -Value $true -PassThru |
            Add-Member -MemberType NoteProperty -Name 'Special' -Value $false -PassThru -Force
        )

        $mockSmbShareAccess = @(
            (
                New-Object -TypeName Object |
                Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockShareName -PassThru |
                Add-Member -MemberType NoteProperty -Name 'ScopName' -Value '*' -PassThru |
                Add-Member -MemberType NoteProperty -Name 'AccountName' -Value $mockFullPermissionUserName[0] -PassThru |
                Add-Member -MemberType NoteProperty -Name 'AccessControlType' -Value 'Allow' -PassThru |
                Add-Member -MemberType NoteProperty -Name 'AccessRight' -Value 'Full' -PassThru -Force
            ),
            (
                New-Object -TypeName Object |
                Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockShareName -PassThru |
                Add-Member -MemberType NoteProperty -Name 'ScopName' -Value '*' -PassThru |
                Add-Member -MemberType NoteProperty -Name 'AccountName' -Value $mockFullPermissionUserName[1] -PassThru |
                Add-Member -MemberType NoteProperty -Name 'AccessControlType' -Value 'Allow' -PassThru |
                Add-Member -MemberType NoteProperty -Name 'AccessRight' -Value 'Full' -PassThru -Force
            ),
            (
                New-Object -TypeName Object |
                Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockShareName -PassThru |
                Add-Member -MemberType NoteProperty -Name 'ScopName' -Value '*' -PassThru |
                Add-Member -MemberType NoteProperty -Name 'AccountName' -Value $mockChangePermissionUserName[0] -PassThru |
                Add-Member -MemberType NoteProperty -Name 'AccessControlType' -Value 'Allow' -PassThru |
                Add-Member -MemberType NoteProperty -Name 'AccessRight' -Value 'Change' -PassThru -Force
            ),
            (
                New-Object -TypeName Object |
                Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockShareName -PassThru |
                Add-Member -MemberType NoteProperty -Name 'ScopName' -Value '*' -PassThru |
                Add-Member -MemberType NoteProperty -Name 'AccountName' -Value $mockReadPermissionUserName[0] -PassThru |
                Add-Member -MemberType NoteProperty -Name 'AccessControlType' -Value 'Allow' -PassThru |
                Add-Member -MemberType NoteProperty -Name 'AccessRight' -Value 'Read' -PassThru -Force
            ),
            (
                New-Object -TypeName Object |
                Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockShareName -PassThru |
                Add-Member -MemberType NoteProperty -Name 'ScopName' -Value '*' -PassThru |
                Add-Member -MemberType NoteProperty -Name 'AccountName' -Value $mockNoPermissionUserName[0] -PassThru |
                Add-Member -MemberType NoteProperty -Name 'AccessControlType' -Value 'Deny' -PassThru |
                Add-Member -MemberType NoteProperty -Name 'AccessRight' -Value 'Full' -PassThru -Force
            )
        )

        Describe 'MSFT_SmbShare\Get-TargetResource' -Tag 'Get' {
            Context 'When the system is in the desired state' {
                BeforeAll {
                    Mock -CommandName Get-SmbShare -MockWith {
                        return $mockSmbShare
                    }

                    Mock -CommandName Get-SmbShareAccess -MockWith {
                        return $mockSmbShareAccess
                    }

                    $testParameters = @{
                        Name    = $mockSmbShare.Name
                        Path    = $mockSmbShare.Path
                        Verbose = $true
                    }
                }

                It 'Should return the correct access memberships' {
                    $getTargetResourceResult = Get-TargetResource @testParameters

                    $getTargetResourceResult.ChangeAccess | Should -HaveCount 1
                    $getTargetResourceResult.ChangeAccess[0] | Should -BeIn $mockChangePermissionUserName

                    $getTargetResourceResult.ReadAccess | Should -HaveCount 1
                    $getTargetResourceResult.ReadAccess[0] | Should -BeIn $mockReadPermissionUserName

                    $getTargetResourceResult.FullAccess | Should -HaveCount 2
                    $getTargetResourceResult.FullAccess[0] | Should -BeIn $mockFullPermissionUserName
                    $getTargetResourceResult.FullAccess[1] | Should -BeIn $mockFullPermissionUserName

                    $getTargetResourceResult.NoAccess | Should -HaveCount 1
                    $getTargetResourceResult.NoAccess[0] | Should -BeIn $mockNoPermissionUserName

                    Assert-MockCalled Get-SmbShare -Exactly -Times 1 -Scope It
                    Assert-MockCalled Get-SmbShareAccess -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state' {
                BeforeAll {
                    Mock -CommandName Get-SmbShare

                    $testParameters = @{
                        Name    = $mockSmbShare.Name
                        Path    = $mockSmbShare.Path
                        Verbose = $true
                    }
                }

                It 'Should return the correct values' {
                    $getTargetResourceResult = Get-TargetResource @testParameters

                    $getTargetResourceResult.Ensure | Should -Be 'Absent'
                    $getTargetResourceResult.Name | Should -Be $testParameters.Name
                    $getTargetResourceResult.Path | Should -BeNullOrEmpty
                    $getTargetResourceResult.Description | Should -BeNullOrEmpty
                    $getTargetResourceResult.ConcurrentUserLimit | Should -Be 0
                    $getTargetResourceResult.EncryptData | Should -BeFalse
                    $getTargetResourceResult.FolderEnumerationMode | Should -BeNullOrEmpty
                    $getTargetResourceResult.CachingMode | Should -BeNullOrEmpty
                    $getTargetResourceResult.ContinuouslyAvailable | Should -BeFalse
                    $getTargetResourceResult.ShareState | Should -BeNullOrEmpty
                    $getTargetResourceResult.ShareType | Should -BeNullOrEmpty
                    $getTargetResourceResult.ShadowCopy | Should -BeFalse
                    $getTargetResourceResult.Special | Should -BeFalse
                    $getTargetResourceResult.ChangeAccess | Should -HaveCount 0
                    $getTargetResourceResult.ReadAccess | Should -HaveCount 0
                    $getTargetResourceResult.FullAccess | Should -HaveCount 0
                    $getTargetResourceResult.NoAccess | Should -HaveCount 0

                    Assert-MockCalled Get-SmbShare -Exactly -Times 1 -Scope It
                }
            }
        }

        Describe 'MSFT_SmbShare\Set-TargetResource' -Tag 'Set' {
            Context 'When the system is not in the desired state' {
                BeforeAll {
                    Mock -CommandName New-SmbShare
                    Mock -CommandName Set-SmbShare
                    Mock -CommandName Remove-SmbShareAccessPermission
                    Mock -CommandName Add-SmbShareAccessPermission
                    Mock -CommandName Remove-SmbShare
                }

                Context 'When the configuration should be present' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Name                  = $mockShareName
                                Path                  = $null
                                Description           = $null
                                ConcurrentUserLimit   = [System.UInt32] 0
                                EncryptData           = $false
                                FolderEnumerationMode = $null
                                CachingMode           = $null
                                ContinuouslyAvailable = $false
                                ShareState            = $null
                                ShareType             = $null
                                ShadowCopy            = $false
                                Special               = $false
                                FullAccess            = [System.String[]] @()
                                ChangeAccess          = [System.String[]] @()
                                ReadAccess            = [System.String[]] @()
                                NoAccess              = [System.String[]] @()
                                Ensure                = 'Absent'
                            }
                        }
                    }

                    Context 'When no access permission is given' {
                        It 'Should throw the correct error' {
                            $setTargetResourceParameters = @{
                                Name                  = $mockShareName
                                Path                  = 'TestDrive:\Temp'
                                Description           = 'Some description'
                                ConcurrentUserLimit   = 2
                                EncryptData           = $false
                                FolderEnumerationMode = 'AccessBased'
                                CachingMode           = 'Manual'
                                ContinuouslyAvailable = $true
                                ChangeAccess          = @()
                                ReadAccess            = @()
                                FullAccess            = @()
                                NoAccess              = @()
                                Verbose               = $true
                            }

                            { Set-TargetResource @setTargetResourceParameters } | Should -Throw $script:localizedData.WrongAccessParameters
                        }
                    }

                    Context 'When access permissions are given' {
                        It 'Should call the correct mocks' {
                            $setTargetResourceParameters = @{
                                Name                  = $mockShareName
                                Path                  = 'TestDrive:\Temp'
                                Description           = 'Some description'
                                ConcurrentUserLimit   = 2
                                EncryptData           = $false
                                FolderEnumerationMode = 'AccessBased'
                                CachingMode           = 'Manual'
                                ContinuouslyAvailable = $true
                                ChangeAccess          = $mockChangePermissionUserName
                                ReadAccess            = $mockReadPermissionUserName
                                FullAccess            = $mockFullPermissionUserName
                                NoAccess              = $mockNoPermissionUserName
                                Verbose               = $true
                            }

                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            Assert-MockCalled New-SmbShare -Exactly -Times 1 -Scope It
                            Assert-MockCalled Set-SmbShare -Exactly -Times 0 -Scope It
                            Assert-MockCalled Remove-SmbShare -Exactly -Times 0 -Scope It
                            Assert-MockCalled Remove-SmbShareAccessPermission -Exactly -Times 0 -Scope It
                        }
                    }
                }

                Context 'When the configuration should be absent' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Name   = $mockShareName
                                Ensure = 'Present'
                            }
                        }
                    }

                    It 'Should call the correct mocks' {
                        $setTargetResourceParameters = @{
                            Name    = $mockShareName
                            Path    = 'AnyValue'
                            Ensure  = 'Absent'
                            Verbose = $true
                        }

                        { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                        Assert-MockCalled New-SmbShare -Exactly -Times 0 -Scope It
                        Assert-MockCalled Set-SmbShare -Exactly -Times 0 -Scope It
                        Assert-MockCalled Remove-SmbShare -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When the configuration has a property that is not in desired state' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Name                  = $mockSmbShare.Name
                                Path                  = $mockSmbShare.Path
                                Description           = $mockSmbShare.Description
                                ConcurrentUserLimit   = [System.UInt32] $mockSmbShare.ConcurrentUserLimit
                                EncryptData           = $mockSmbShare.EncryptData
                                FolderEnumerationMode = $mockSmbShare.FolderEnumerationMode
                                CachingMode           = $mockSmbShare.CachingMode
                                # Property that is not in desired state.
                                ContinuouslyAvailable = $false
                                ShareState            = $mockSmbShare.ShareState
                                ShareType             = $mockSmbShare.ShareType
                                ShadowCopy            = $mockSmbShare.ShadowCopy
                                Special               = $mockSmbShare.Special
                                FullAccess            = [System.String[]] $mockFullPermissionUserName
                                ChangeAccess          = [System.String[]] $mockChangePermissionUserName
                                ReadAccess            = [System.String[]] $mockReadPermissionUserName
                                NoAccess              = [System.String[]] $mockNoPermissionUserName
                                Ensure                = 'Present'
                            }
                        }
                    }

                    It 'Should call the correct mocks' {
                        $setTargetResourceParameters = @{
                            Name                  = $mockShareName
                            Path                  = 'TestDrive:\Temp'
                            Description           = 'Some description'
                            ConcurrentUserLimit   = 2
                            EncryptData           = $false
                            FolderEnumerationMode = 'AccessBased'
                            CachingMode           = 'Manual'
                            ContinuouslyAvailable = $true
                            ChangeAccess          = $mockChangePermissionUserName
                            ReadAccess            = $mockReadPermissionUserName
                            FullAccess            = $mockFullPermissionUserName
                            NoAccess              = $mockNoPermissionUserName
                            Verbose               = $true
                        }

                        { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                        Assert-MockCalled Set-SmbShare -Exactly -Times 1 -Scope It
                        Assert-MockCalled Remove-SmbShareAccessPermission -Exactly -Times 1 -Scope It
                        Assert-MockCalled Add-SmbShareAccessPermission -Exactly -Times 1 -Scope It
                        Assert-MockCalled New-SmbShare -Exactly -Times 0 -Scope It
                        Assert-MockCalled Remove-SmbShare -Exactly -Times 0 -Scope It
                    }
                }
            }
        }

        Describe 'MSFT_SmbShare\Test-TargetResource' -Tag 'Test' {
            Context 'When the system is not in the desired state' {
                Context 'When no member are provided in any of the access permission collections' {
                    BeforeAll {
                        $testTargetResourceParameters = @{
                            Name                  = $mockShareName
                            Path                  = 'TestDrive:\Temp'
                            FullAccess            = @()
                            ChangeAccess          = @()
                            ReadAccess            = @()
                            NoAccess              = @()
                            Ensure                = 'Present'
                            Verbose               = $true
                        }
                    }

                    It 'Should throw the correct error' {
                        {
                            Test-TargetResource @testTargetResourceParameters
                        } | Should -Throw $script:localizedData.WrongAccessParameters
                    }
                }

                Context 'When there is a configured SMB share' {
                    BeforeAll {
                        $mockDefaultTestCaseValues = @{
                            TestCase              = ''
                            Name                  = $mockSmbShare.Name
                            Path                  = $mockSmbShare.Path
                            Description           = $mockSmbShare.Description
                            ConcurrentUserLimit   = $mockSmbShare.ConcurrentUserLimit
                            EncryptData           = $mockSmbShare.EncryptData
                            FolderEnumerationMode = $mockSmbShare.FolderEnumerationMode
                            CachingMode           = $mockSmbShare.CachingMode
                            ContinuouslyAvailable = $mockSmbShare.ContinuouslyAvailable
                            FullAccess            = @()
                            ChangeAccess          = @()
                            ReadAccess            = @($mockReadPermissionUserName)
                            NoAccess              = @()
                            Ensure                = 'Present'
                        }

                        $mockTestCase1 = $mockDefaultTestCaseValues.Clone()
                        $testProperty = 'Path'
                        $mockTestCase1['TestCase'] = $testProperty
                        $mockTestCase1[$testProperty] = 'TestDrive:\NewFolder'

                        $mockTestCase2 = $mockDefaultTestCaseValues.Clone()
                        $testProperty = 'Description'
                        $mockTestCase2['TestCase'] = $testProperty
                        $mockTestCase2[$testProperty] = 'New description'

                        $mockTestCase3 = $mockDefaultTestCaseValues.Clone()
                        $testProperty = 'ConcurrentUserLimit'
                        $mockTestCase3['TestCase'] = $testProperty
                        $mockTestCase3[$testProperty] = 2

                        $mockTestCase4 = $mockDefaultTestCaseValues.Clone()
                        $testProperty = 'EncryptData'
                        $mockTestCase4['TestCase'] = $testProperty
                        $mockTestCase4[$testProperty] = $true

                        $mockTestCase5 = $mockDefaultTestCaseValues.Clone()
                        $testProperty = 'FolderEnumerationMode'
                        $mockTestCase5['TestCase'] = $testProperty
                        $mockTestCase5[$testProperty] = 'Unrestricted'

                        $mockTestCase6 = $mockDefaultTestCaseValues.Clone()
                        $testProperty = 'CachingMode'
                        $mockTestCase6['TestCase'] = $testProperty
                        $mockTestCase6[$testProperty] = 'Documents'

                        $mockTestCase7 = $mockDefaultTestCaseValues.Clone()
                        $testProperty = 'ContinuouslyAvailable'
                        $mockTestCase7['TestCase'] = $testProperty
                        $mockTestCase7[$testProperty] = $false

                        $mockTestCase8 = $mockDefaultTestCaseValues.Clone()
                        $testProperty = 'FullAccess'
                        $mockTestCase8['TestCase'] = $testProperty
                        $mockTestCase8[$testProperty] = @('NewUser')

                        $mockTestCase9 = $mockDefaultTestCaseValues.Clone()
                        $testProperty = 'ChangeAccess'
                        $mockTestCase9['TestCase'] = $testProperty
                        $mockTestCase9[$testProperty] = @('NewUser')

                        $mockTestCase10 = $mockDefaultTestCaseValues.Clone()
                        $testProperty = 'ReadAccess'
                        $mockTestCase10['TestCase'] = $testProperty
                        $mockTestCase10[$testProperty] = @('NewUser')

                        $mockTestCase11 = $mockDefaultTestCaseValues.Clone()
                        $testProperty = 'NoAccess'
                        $mockTestCase11['TestCase'] = $testProperty
                        $mockTestCase11[$testProperty] = @('NewUser')

                        $testCases = @(
                            $mockTestCase1
                            $mockTestCase2
                            $mockTestCase3
                            $mockTestCase4
                            $mockTestCase5
                            $mockTestCase6
                            $mockTestCase7
                            $mockTestCase8
                            $mockTestCase9
                            $mockTestCase10
                            $mockTestCase11
                        )

                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Name                  = $mockSmbShare.Name
                                Path                  = $mockSmbShare.Path
                                Description           = $mockSmbShare.Description
                                ConcurrentUserLimit   = [System.UInt32] $mockSmbShare.ConcurrentUserLimit
                                EncryptData           = $mockSmbShare.EncryptData
                                FolderEnumerationMode = $mockSmbShare.FolderEnumerationMode
                                CachingMode           = $mockSmbShare.CachingMode
                                ContinuouslyAvailable = $mockSmbShare.ContinuouslyAvailable
                                ShareState            = $mockSmbShare.ShareState
                                ShareType             = $mockSmbShare.ShareType
                                ShadowCopy            = $mockSmbShare.ShadowCopy
                                Special               = $mockSmbShare.Special
                                FullAccess            = [System.String[]] @()
                                ChangeAccess          = [System.String[]] @()
                                ReadAccess            = [System.String[]] @()
                                NoAccess              = [System.String[]] @()
                                Ensure                = 'Present'
                            }
                        }
                    }

                    It 'Should return $false when property <TestCase> has the wrong value' -TestCases $testCases {
                        param
                        (
                            $Name,
                            $Path,
                            $Description,
                            $ConcurrentUserLimit,
                            $EncryptData,
                            $FolderEnumerationMode,
                            $CachingMode,
                            $ContinuouslyAvailable,
                            $FullAccess,
                            $ChangeAccess,
                            $ReadAccess,
                            $NoAccess,
                            $Ensure
                        )

                        $testTargetResourceParameters = @{
                            Name                  = $Name
                            Path                  = $Path
                            Description           = $Description
                            ConcurrentUserLimit   = $ConcurrentUserLimit
                            EncryptData           = $EncryptData
                            FolderEnumerationMode = $FolderEnumerationMode
                            CachingMode           = $CachingMode
                            ContinuouslyAvailable = $ContinuouslyAvailable
                            FullAccess            = $FullAccess
                            ChangeAccess          = $ChangeAccess
                            ReadAccess            = $ReadAccess
                            NoAccess              = $NoAccess
                            Ensure                = 'Present'
                            Verbose               = $true
                        }

                        $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                        $testTargetResourceResult | Should -BeFalse
                    }

                    It 'Should return $false when the desired state should be ''Absent''' {
                        $testTargetResourceParameters = @{
                            Ensure                = 'Absent'
                            Name                  = $mockSmbShare.Name
                            Path                  = $mockSmbShare.Path
                            Description           = $mockSmbShare.Description
                            ConcurrentUserLimit   = [System.UInt32] $mockSmbShare.ConcurrentUserLimit
                            EncryptData           = $mockSmbShare.EncryptData
                            FolderEnumerationMode = $mockSmbShare.FolderEnumerationMode
                            CachingMode           = $mockSmbShare.CachingMode
                            ContinuouslyAvailable = $mockSmbShare.ContinuouslyAvailable
                            FullAccess            = @()
                            ChangeAccess          = @()
                            ReadAccess            = @($mockReadPermissionUserName)
                            NoAccess              = @()
                            Verbose               = $true
                        }

                        $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                        $testTargetResourceResult | Should -BeFalse
                    }
                }

                Context 'When there are no configured SMB share' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Ensure = 'Absent'
                            }
                        }
                    }

                    It 'Should return $false when the desired state should ''Present''' {
                        $testTargetResourceParameters = @{
                            Ensure  = 'Present'
                            Name    = $mockSmbShare.Name
                            Path    = $mockSmbShare.Path
                            Verbose = $true
                        }

                        $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                        $testTargetResourceResult | Should -BeFalse
                    }
                }
            }

            Context 'When the system is in the desired state' {
                Context 'When there is a configured SMB share' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Name                  = $mockSmbShare.Name
                                Path                  = $mockSmbShare.Path
                                Description           = $mockSmbShare.Description
                                ConcurrentUserLimit   = [System.UInt32] $mockSmbShare.ConcurrentUserLimit
                                EncryptData           = $mockSmbShare.EncryptData
                                FolderEnumerationMode = $mockSmbShare.FolderEnumerationMode
                                CachingMode           = $mockSmbShare.CachingMode
                                ContinuouslyAvailable = $mockSmbShare.ContinuouslyAvailable
                                ShareState            = $mockSmbShare.ShareState
                                ShareType             = $mockSmbShare.ShareType
                                ShadowCopy            = $mockSmbShare.ShadowCopy
                                Special               = $mockSmbShare.Special
                                FullAccess            = [System.String[]] @()
                                ChangeAccess          = [System.String[]] @()
                                ReadAccess            = [System.String[]] @($mockReadPermissionUserName)
                                NoAccess              = [System.String[]] @()
                                Ensure                = 'Present'
                            }
                        }
                    }

                    It 'Should return $true when the desired state should be ''Present''' {
                        $testTargetResourceParameters = @{
                            Ensure                = 'Present'
                            Name                  = $mockSmbShare.Name
                            Path                  = $mockSmbShare.Path
                            Description           = $mockSmbShare.Description
                            ConcurrentUserLimit   = [System.UInt32] $mockSmbShare.ConcurrentUserLimit
                            EncryptData           = $mockSmbShare.EncryptData
                            FolderEnumerationMode = $mockSmbShare.FolderEnumerationMode
                            CachingMode           = $mockSmbShare.CachingMode
                            ContinuouslyAvailable = $mockSmbShare.ContinuouslyAvailable
                            FullAccess            = @()
                            ChangeAccess          = @()
                            ReadAccess            = @($mockReadPermissionUserName)
                            NoAccess              = @()
                            Verbose               = $true
                        }

                        $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                        $testTargetResourceResult | Should -BeTrue
                    }
                }

                Context 'When there are no configured SMB share' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Ensure = 'Absent'
                            }
                        }
                    }

                    It 'Should return $true when the desired state should ''Absent''' {
                        $testTargetResourceParameters = @{
                            Ensure  = 'Absent'
                            Name    = $mockSmbShare.Name
                            Path    = $mockSmbShare.Path
                            Verbose = $true
                        }

                        $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                        $testTargetResourceResult | Should -BeTrue
                    }
                }
            }
        }

        Describe 'MSFT_SmbShare\Add-SmbShareAccessPermission' -Tag 'Helper' {
            BeforeAll {
                Mock -CommandName Grant-SmbShareAccess
                Mock -CommandName Block-SmbShareAccess

                Mock -CommandName Get-SmbShareAccess -MockWith {
                    <#
                        Mocked permission:

                        Full = @('User3', 'User4')
                        Change = @('User1')
                        Read = @('User2')
                        Denied = @('DeniedUser1')
                    #>
                    return $mockSmbShareAccess
                }
            }

            Context 'When adding granted permissions to an SMB share' {
                BeforeAll {
                    $mockExpectedAccountToBeAdded = 'NewUser'
                }

                AfterEach {
                    Assert-MockCalled -CommandName Block-SmbShareAccess -Exactly -Times 0 -Scope 'It'
                }

                Context 'When an account with full access should be added' {
                    BeforeAll {
                        $addSmbShareAccessPermissionParameters = @{
                            Name       = $mockShareName
                            # User3 is an already present account. It should not be added.
                            FullAccess = @('User3', $mockExpectedAccountToBeAdded)
                            Verbose    = $true
                        }
                    }

                    It 'Should not throw an error and call the correct mocks' {
                        { Add-SmbShareAccessPermission @addSmbShareAccessPermissionParameters } | Should -Not -Throw

                        <#
                            Assert that Grant-SmbShareAccess is only called once, and
                            that only time was with the correct parameters.
                        #>
                        Assert-MockCalled -CommandName Grant-SmbShareAccess -Exactly -Times 1 -Scope 'It'
                        Assert-MockCalled -CommandName Grant-SmbShareAccess -ParameterFilter {
                            $Name -eq $mockShareName `
                                -and $AccessRight -eq 'Full' `
                                -and $AccountName -eq $mockExpectedAccountToBeAdded
                        } -Exactly -Times 1 -Scope 'It'
                    }
                }

                Context 'When an account with change access should be added' {
                    BeforeAll {
                        $addSmbShareAccessPermissionParameters = @{
                            Name         = $mockShareName
                            # User1 is an already present account. It should not be added.
                            ChangeAccess = @('User1', $mockExpectedAccountToBeAdded)
                            Verbose      = $true
                        }
                    }

                    It 'Should not throw an error and call the correct mocks' {
                        { Add-SmbShareAccessPermission @addSmbShareAccessPermissionParameters } | Should -Not -Throw

                        <#
                            Assert that Grant-SmbShareAccess is only called once, and
                            that only time was with the correct parameters.
                        #>
                        Assert-MockCalled -CommandName Grant-SmbShareAccess -Exactly -Times 1 -Scope 'It'
                        Assert-MockCalled -CommandName Grant-SmbShareAccess -ParameterFilter {
                            $Name -eq $mockShareName `
                                -and $AccessRight -eq 'Change' `
                                -and $AccountName -eq $mockExpectedAccountToBeAdded
                        } -Exactly -Times 1 -Scope 'It'
                    }
                }

                Context 'When an account with read access should be added' {
                    BeforeAll {
                        $addSmbShareAccessPermissionParameters = @{
                            Name       = $mockShareName
                            # User2 is an already present account. It should not be added.
                            ReadAccess = @('User2', $mockExpectedAccountToBeAdded)
                            Verbose    = $true
                        }
                    }

                    It 'Should not throw an error and call the correct mocks' {
                        { Add-SmbShareAccessPermission @addSmbShareAccessPermissionParameters } | Should -Not -Throw

                        <#
                            Assert that Grant-SmbShareAccess is only called once, and
                            that only time was with the correct parameters.
                        #>
                        Assert-MockCalled -CommandName Grant-SmbShareAccess -Exactly -Times 1 -Scope 'It'
                        Assert-MockCalled -CommandName Grant-SmbShareAccess -ParameterFilter {
                            $Name -eq $mockShareName `
                                -and $AccessRight -eq 'Read' `
                                -and $AccountName -eq $mockExpectedAccountToBeAdded
                        } -Exactly -Times 1 -Scope 'It'
                    }
                }

                Context 'When accounts with different access should be added' {
                    BeforeAll {
                        $mockExpectedAccountToBeAdded1 = 'NweUser1'
                        $mockExpectedAccountToBeAdded2 = 'NweUser2'
                        $mockExpectedAccountToBeAdded3 = 'NweUser3'

                        $addSmbShareAccessPermissionParameters = @{
                            Name         = $mockShareName
                            # User1, User2, and User3 is an already present account. It should not be added.
                            FullAccess   = @('User3', $mockExpectedAccountToBeAdded1)
                            ReadAccess   = @('User2', $mockExpectedAccountToBeAdded2)
                            ChangeAccess = @('User1', $mockExpectedAccountToBeAdded3)
                            Verbose      = $true
                        }
                    }

                    It 'Should not throw an error and call the correct mocks' {
                        { Add-SmbShareAccessPermission @addSmbShareAccessPermissionParameters } | Should -Not -Throw

                        <#
                            Assert that Grant-SmbShareAccess is only called once, and
                            that only time was with the correct parameters.
                        #>
                        Assert-MockCalled -CommandName Grant-SmbShareAccess -Exactly -Times 3 -Scope 'It'
                        Assert-MockCalled -CommandName Grant-SmbShareAccess -ParameterFilter {
                            $Name -eq $mockShareName `
                                -and $AccessRight -eq 'Change' `
                                -and $AccountName -eq $mockExpectedAccountToBeAdded3
                        } -Exactly -Times 1 -Scope 'It'

                        Assert-MockCalled -CommandName Grant-SmbShareAccess -ParameterFilter {
                            $Name -eq $mockShareName `
                                -and $AccessRight -eq 'Full' `
                                -and $AccountName -eq $mockExpectedAccountToBeAdded1
                        } -Exactly -Times 1 -Scope 'It'

                        Assert-MockCalled -CommandName Grant-SmbShareAccess -ParameterFilter {
                            $Name -eq $mockShareName `
                                -and $AccessRight -eq 'Read' `
                                -and $AccountName -eq $mockExpectedAccountToBeAdded2
                        } -Exactly -Times 1 -Scope 'It'
                    }
                }
            }

            Context 'When denying permissions on an SMB share' {
                AfterEach {
                    Assert-MockCalled -CommandName Grant-SmbShareAccess -Exactly -Times 0 -Scope 'It'
                }

                Context 'When an account with denied access should be revoked' {
                    BeforeAll {
                        $mockExpectedAccountToBeBlocked = 'NewDeniedUser'

                        $removeSmbShareAccessPermissionParameters = @{
                            Name     = $mockShareName
                            NoAccess = @('DeniedUser1', $mockExpectedAccountToBeBlocked)
                            Verbose  = $true
                        }
                    }

                    It 'Should not throw an error and call the correct mocks' {
                        { Add-SmbShareAccessPermission @removeSmbShareAccessPermissionParameters } | Should -Not -Throw

                        <#
                            Assert that Block-SmbShareAccess is only called once, and
                            that only time was with the correct parameters.
                        #>
                        Assert-MockCalled -CommandName Block-SmbShareAccess -Exactly -Times 1 -Scope 'It'
                        Assert-MockCalled -CommandName Block-SmbShareAccess -ParameterFilter {
                            $Name -eq $mockShareName `
                                -and $AccountName -eq $mockExpectedAccountToBeBlocked
                        } -Exactly -Times 1 -Scope 'It'
                    }
                }
            }
        }

        Describe 'MSFT_SmbShare\Remove-SmbShareAccessPermission' -Tag 'Helper' {
            BeforeAll {
                Mock -CommandName Revoke-SmbShareAccess
                Mock -CommandName Unblock-SmbShareAccess

                Mock -CommandName Get-SmbShareAccess -MockWith {
                    <#
                        Mocked permission:

                        Full = @('User3', 'User4')
                        Change = @('User1')
                        Read = @('User2')
                        Denied = @('DeniedUser1')
                    #>
                    return $mockSmbShareAccess
                }
            }

            Context 'When revoking granted permissions from an SMB share' {
                AfterEach {
                    Assert-MockCalled -CommandName Unblock-SmbShareAccess -Exactly -Times 0 -Scope 'It'
                }

                Context 'When an account with full access should be removed' {
                    BeforeAll {
                        $mockExpectedAccountToBeRemoved = 'User4'

                        $removeSmbShareAccessPermissionParameters = @{
                            Name       = $mockShareName
                            FullAccess = @('User3')
                            Verbose    = $true
                        }
                    }

                    It 'Should not throw an error and call the correct mocks' {
                        { Remove-SmbShareAccessPermission @removeSmbShareAccessPermissionParameters } | Should -Not -Throw

                        <#
                            Assert that Revoke-SmbShareAccess is only called once, and
                            that only time was with the correct parameters.
                        #>
                        Assert-MockCalled -CommandName Revoke-SmbShareAccess -Exactly -Times 1 -Scope 'It'
                        Assert-MockCalled -CommandName Revoke-SmbShareAccess -ParameterFilter {
                            $Name -eq $mockShareName `
                                -and $AccountName -eq $mockExpectedAccountToBeRemoved
                        } -Exactly -Times 1 -Scope 'It'
                    }
                }

                Context 'When an all accounts with full access should be removed' {
                    BeforeAll {
                        $mockExpectedAccountToBeRemoved1 = 'User3'
                        $mockExpectedAccountToBeRemoved2 = 'User4'

                        $removeSmbShareAccessPermissionParameters = @{
                            Name       = $mockShareName
                            FullAccess = @()
                            Verbose    = $true
                        }
                    }

                    It 'Should not throw an error and call the correct mocks' {
                        { Remove-SmbShareAccessPermission @removeSmbShareAccessPermissionParameters } | Should -Not -Throw

                        <#
                            Assert that Revoke-SmbShareAccess is called twice, and
                            that both times it is called with the correct parameters.
                        #>
                        Assert-MockCalled -CommandName Revoke-SmbShareAccess -Exactly -Times 2 -Scope 'It'
                        Assert-MockCalled -CommandName Revoke-SmbShareAccess -ParameterFilter {
                            $Name -eq $mockShareName `
                                -and $AccountName -eq $mockExpectedAccountToBeRemoved1
                        } -Exactly -Times 1 -Scope 'It'

                        Assert-MockCalled -CommandName Revoke-SmbShareAccess -ParameterFilter {
                            $Name -eq $mockShareName `
                                -and $AccountName -eq $mockExpectedAccountToBeRemoved2
                        } -Exactly -Times 1 -Scope 'It'
                    }
                }

                Context 'When an account with change access should be removed' {
                    BeforeAll {
                        $mockExpectedAccountToBeRemoved = 'User1'

                        $removeSmbShareAccessPermissionParameters = @{
                            Name         = $mockShareName
                            ChangeAccess = @()
                            Verbose      = $true
                        }
                    }

                    It 'Should not throw an error and call the correct mocks' {
                        { Remove-SmbShareAccessPermission @removeSmbShareAccessPermissionParameters } | Should -Not -Throw

                        <#
                            Assert that Revoke-SmbShareAccess is only called once, and
                            that only time was with the correct parameters.
                        #>
                        Assert-MockCalled -CommandName Revoke-SmbShareAccess -Exactly -Times 1 -Scope 'It'
                        Assert-MockCalled -CommandName Revoke-SmbShareAccess -ParameterFilter {
                            $Name -eq $mockShareName `
                                -and $AccountName -eq $mockExpectedAccountToBeRemoved
                        } -Exactly -Times 1 -Scope 'It'
                    }
                }

                Context 'When an account with read access should be removed' {
                    BeforeAll {
                        $mockExpectedAccountToBeRemoved = 'User2'

                        $removeSmbShareAccessPermissionParameters = @{
                            Name       = $mockShareName
                            ReadAccess = @()
                            Verbose    = $true
                        }
                    }

                    It 'Should not throw an error and call the correct mocks' {
                        { Remove-SmbShareAccessPermission @removeSmbShareAccessPermissionParameters } | Should -Not -Throw

                        <#
                            Assert that Revoke-SmbShareAccess is only called for each account,
                            and each time with the correct parameters.
                        #>
                        Assert-MockCalled -CommandName Revoke-SmbShareAccess -Exactly -Times 1 -Scope 'It'
                        Assert-MockCalled -CommandName Revoke-SmbShareAccess -ParameterFilter {
                            $Name -eq $mockShareName `
                                -and $AccountName -eq $mockExpectedAccountToBeRemoved
                        } -Exactly -Times 1 -Scope 'It'


                    }
                }

                Context 'When an all granted access should be removed' {
                    BeforeAll {
                        $removeSmbShareAccessPermissionParameters = @{
                            Name         = $mockShareName
                            FullAccess   = @()
                            ChangeAccess = @()
                            ReadAccess   = @()
                            Verbose      = $true
                        }
                    }

                    It 'Should not throw an error and call the correct mocks' {
                        { Remove-SmbShareAccessPermission @removeSmbShareAccessPermissionParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Revoke-SmbShareAccess -Exactly -Times 4 -Scope 'It'
                        Assert-MockCalled -CommandName Revoke-SmbShareAccess -ParameterFilter {
                            $Name -eq $mockShareName `
                                -and $AccountName -eq 'User1'
                        } -Exactly -Times 1 -Scope 'It'

                        Assert-MockCalled -CommandName Revoke-SmbShareAccess -ParameterFilter {
                            $Name -eq $mockShareName `
                                -and $AccountName -eq 'User2'
                        } -Exactly -Times 1 -Scope 'It'

                        Assert-MockCalled -CommandName Revoke-SmbShareAccess -ParameterFilter {
                            $Name -eq $mockShareName `
                                -and $AccountName -eq 'User3'
                        } -Exactly -Times 1 -Scope 'It'

                        Assert-MockCalled -CommandName Revoke-SmbShareAccess -ParameterFilter {
                            $Name -eq $mockShareName `
                                -and $AccountName -eq 'User4'
                        } -Exactly -Times 1 -Scope 'It'
                    }
                }
            }

            Context 'When revoking denied permissions from an SMB share' {
                AfterEach {
                    Assert-MockCalled -CommandName Revoke-SmbShareAccess -Exactly -Times 0 -Scope 'It'
                }

                Context 'When an account with denied access should be revoked' {
                    BeforeAll {
                        $mockExpectedAccountToBeUnblocked = 'DeniedUser1'

                        $removeSmbShareAccessPermissionParameters = @{
                            Name     = $mockShareName
                            NoAccess = @()
                            Verbose  = $true
                        }
                    }

                    It 'Should not throw an error and call the correct mocks' {
                        { Remove-SmbShareAccessPermission @removeSmbShareAccessPermissionParameters } | Should -Not -Throw

                        <#
                            Assert that Block-SmbShareAccess is only called once, and
                            that only time was with the correct parameters.
                        #>
                        Assert-MockCalled -CommandName Unblock-SmbShareAccess -Exactly -Times 1 -Scope 'It'
                        Assert-MockCalled -CommandName Unblock-SmbShareAccess -ParameterFilter {
                            $Name -eq $mockShareName `
                                -and $AccountName -eq $mockExpectedAccountToBeUnblocked
                        } -Exactly -Times 1 -Scope 'It'
                    }
                }
            }
        }

        Describe 'MSFT_SmbShare\Assert-AccessPermissionParameters' -Tag 'Helper' {
            Context 'When asserting correct provided access permissions parameters' {
                Context 'When providing at least one member in one of the access permission collections' {
                    BeforeAll {
                        $testCases = @(
                            @{
                                TestCase     = 'FullAccess'
                                FullAccess   = @('Member1')
                                ChangeAccess = @()
                                ReadAccess   = @()
                                NoAccess     = @()
                            },
                            @{
                                TestCase     = 'ChangeAccess'
                                FullAccess   = @()
                                ChangeAccess = @('Member1')
                                ReadAccess   = @()
                                NoAccess     = @()
                            },
                            @{
                                TestCase     = 'ReadAccess'
                                FullAccess   = @()
                                ChangeAccess = @()
                                ReadAccess   = @('Member1')
                                NoAccess     = @()
                            },
                            @{
                                TestCase     = 'NoAccess'
                                FullAccess   = @()
                                ChangeAccess = @()
                                ReadAccess   = @('Member1')
                                NoAccess     = @()
                            }
                        )
                    }

                    It 'Should not throw an error when testing a member in <TestCase>' -TestCases $testCases {
                        param
                        (
                            $FullAccess,
                            $ChangeAccess,
                            $ReadAccess,
                            $NoAccess
                        )

                        # We must using splatting to test 'ValueFromRemainingArguments' parameter.
                        $assertAccessPermissionParameters = @{
                            FullAccess     = $FullAccess
                            ChangeAccess   = $ChangeAccess
                            ReadAccess     = $ReadAccess
                            NoAccess       = $NoAccess
                            DummyParameter = 'Testing ValueFromRemainingArguments'
                        }

                        {
                            Assert-AccessPermissionParameters @assertAccessPermissionParameters
                        } | Should -Not -Throw
                    }
                }

                Context 'When not providing any members in any of the access permission collections' {
                    It 'Should throw the correct error' {
                        # We must using splatting to test 'ValueFromRemainingArguments' parameter.
                        $assertAccessPermissionParameters = @{
                            FullAccess     = @()
                            ChangeAccess   = @()
                            ReadAccess     = @()
                            NoAccess       = @()
                            DummyParameter = 'Testing ValueFromRemainingArguments'
                        }

                        {
                            Assert-AccessPermissionParameters @assertAccessPermissionParameters
                        } | Should -Throw $script:localizedData.WrongAccessParameters
                    }
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
