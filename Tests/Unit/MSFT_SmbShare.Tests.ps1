#region HEADER
$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'MSFT_SmbShare'

# Unit Test Template Version: 1.2.4
$script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\ComputerManagementDsc'
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git.exe @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath 'DscResource.Tests'))
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
        $mockChangePermissionUserName = @('User1')
        $mockReadPermissionUserName = @('User2')
        $mockFullPermissionUserName = @('User3', 'User4')
        $mockNoPermissionUserName = @('DeniedUser1')

        $mockSmbShare = (
            New-Object -TypeName Object |
                Add-Member -MemberType NoteProperty -Name 'Name' -Value 'DummyShare' -PassThru |
                Add-Member -MemberType NoteProperty -Name 'Path' -Value 'c:\temp' -PassThru |
                Add-Member -MemberType NoteProperty -Name 'Description' 'Dummy share for unit testing' -PassThru |
                Add-Member -MemberType NoteProperty -Name 'ConcurrentUserLimit' -Value 10 -PassThru |
                Add-Member -MemberType NoteProperty -Name 'EncryptData' -Value $false -PassThru |
                Add-Member -MemberType NoteProperty -Name 'FolderEnumerationMode' -Value 'AccessBased' -PassThru | # 0 AccessBased | 1 Unrestricted, but method expects text
                Add-Member -MemberType NoteProperty -Name 'SharedState' -Value 1 -PassThru | # 0 Pending | 1 Online | 2 Offline
                Add-Member -MemberType NoteProperty -Name 'ShadowCopy' -Value $false -PassThru |
                Add-Member -MemberType NoteProperty -Name 'CachingMode' -Value 'Manual' -PassThru |
                Add-Member -MemberType NoteProperty -Name 'ContinuouslyAvailable' -Value $true -PassThru |
                Add-Member -MemberType NoteProperty -Name 'Special' -Value $false -PassThru -Force
        )

        $mockChangePermissionUserName = 'User1'
        $mockSmbShareAccess = @(
            (
                New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'Name' -Value 'DummyShare' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'ScopName' -Value '*' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccountName' -Value $mockFullPermissionUserName -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessControlType' -Value 'Allow' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessRight' -Value 'Full' -PassThru -Force
            ),
            (
                New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'Name' -Value 'DummyShare' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'ScopName' -Value '*' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccountName' -Value $mockChangePermissionUserName -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessControlType' -Value 'Allow' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessRight' -Value 'Change' -PassThru -Force
            ),
            (
                New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'Name' -Value 'DummyShare' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'ScopName' -Value '*' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccountName' -Value $mockReadPermissionUserName -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessControlType' -Value 'Allow' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessRight' -Value 'Read' -PassThru -Force
            ),
            (
                New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'Name' -Value 'DummyShare' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'ScopName' -Value '*' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccountName' -Value $mockNoPermissionUserName -PassThru |
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

                It 'Should mock call to Get-SmbShare and return membership' {
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
                }

                It 'Should call the mock function Get-SmbShare' {
                    $getTargetResourceResult = Get-TargetResource @testParameters
                    Assert-MockCalled Get-SmbShare -Exactly -Times 1 -Scope It
                }

                It 'Should Call the mock function Get-SmbShareAccess' {
                    $getTargetResourceResult = Get-TargetResource @testParameters
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

                    $getTargetResourceResult.Ensure                | Should -Be 'Absent'
                    $getTargetResourceResult.Name                  | Should -Be $testParameters.Name
                    $getTargetResourceResult.Path                  | Should -BeNullOrEmpty
                    $getTargetResourceResult.Description           | Should -BeNullOrEmpty
                    $getTargetResourceResult.ConcurrentUserLimit   | Should -Be 0
                    $getTargetResourceResult.EncryptData           | Should -BeFalse
                    $getTargetResourceResult.FolderEnumerationMode | Should -BeNullOrEmpty
                    $getTargetResourceResult.CachingMode           | Should -BeNullOrEmpty
                    $getTargetResourceResult.ContinuouslyAvailable | Should -BeFalse
                    $getTargetResourceResult.ShareState            | Should -BeNullOrEmpty
                    $getTargetResourceResult.ShareType             | Should -BeNullOrEmpty
                    $getTargetResourceResult.ShadowCopy            | Should -BeNullOrEmpty
                    $getTargetResourceResult.Special               | Should -BeNullOrEmpty
                    $getTargetResourceResult.ChangeAccess          | Should -HaveCount 0
                    $getTargetResourceResult.ReadAccess            | Should -HaveCount 0
                    $getTargetResourceResult.FullAccess            | Should -HaveCount 0
                    $getTargetResourceResult.NoAccess              | Should -HaveCount 0
                }

            }
        }

        # Describe 'MSFT_SmbShare\Set-TargetResource' -Tag 'Set' {
        #     Context 'When the system is not in the desired state' {
        #         BeforeAll {
        #             # Per context-block initialization
        #         }

        #         # Set the testParameter collection
        #         $testParameters = @{
        #             ChangeAccess = $mockChangePermissionUserName
        #             ReadAccess = $mockReadPermissionUserName
        #             FullAccess = $mockFullPermissionUserName
        #             NoAccess = $mockNoAccess
        #             Name = $mockSmbShare.Name
        #             Path = $mockSmbShare.Path
        #             Description = $mockSmbShare.Description
        #             ConcurrentUserLimit = $mockSmbShare.ConcurrentUserLimit
        #             EncryptData = $mockSmbShare.EncryptData
        #             FolderEnumerationMode = $mockSmbShare.FolderEnumerationMode
        #             Ensure = 'Present'
        #         }

        #         # Init the script variables
        #         $script:ChangeAccess = @()
        #         $script:ReadAccess = @()
        #         $script:FullAccess = @()
        #         $script:NoAccess = @()
        #         $script:ChangeAccess += $mockDefaultChangePermissionUserName
        #         $script:ReadAccess += $mockDefaultReadPermissionUserName
        #         $script:FullAccess += $mockDefaultFullPermissionUserName
        #         $script:NoAccess += $mockDefaultNoPermissionUserName


        #         # Set mock function calls
        #         Mock -CommandName Get-SmbShare -MockWith { return @($mockSmbShare)}
        #         Mock -CommandName Get-SmbShareAccess -MockWith { return @($mockSmbShareAccess)}
        #         Mock -CommandName Set-SmbShare -MockWith { return $null}
        #         Mock -CommandName Grant-SmbShareAccess -MockWith {
        #             # Declare local array -- use of this variable was necessary as the script: context was losing the fact it was an array in the mock
        #             $localArray = @()

        #             switch($AccessPermission)
        #             {
        #                 'Change'
        #                 {
        #                     $localArray += $script:ChangeAccess
        #                     if ($localArray -notcontains $UserName)
        #                     {
        #                         $localArray += $UserName
        #                     }

        #                     $script:ChangeAccess = $localArray
        #                     break
        #                 }
        #                 'Read'
        #                 {
        #                     $localArray += $script:ReadAccess
        #                     if($localArray -notcontains $UserName)
        #                     {
        #                         $localArray += $UserName
        #                     }
        #                     $script:ReadAccess = $localArray
        #                     break
        #                 }
        #                 'Full'
        #                 {
        #                     $localArray += $script:FullAccess
        #                     if($localArray -notcontains $UserName)
        #                     {
        #                         $localArray += $UserName
        #                     }
        #                     $script:FullAccess = $localArray
        #                     break
        #                 }
        #             }
        #         }
        #         Mock Block-SmbShareAccess -MockWith {
        #             $script:NoAccess += $UserName
        #         }
        #         Mock Revoke-SmbShareAccess -MockWith {
        #             switch($AccessPermission)
        #             {
        #                 'Change'
        #                 {
        #                     # Remove from array
        #                     $script:ChangeAccess = $script:ChangeAccess | Where-Object {$_ -ne $UserName}
        #                     break
        #                 }
        #                 'Read'
        #                 {
        #                     $script:ReadAccess = $script:ReadAccess | Where-Object {$_ -ne $UserName}
        #                     break
        #                 }
        #                 'Full'
        #                 {
        #                     $script:FullAccess = $script:FullAccess | Where-Object {$_ -ne $UserName}
        #                     break
        #                 }
        #             }
        #         }
        #         Mock -CommandName Unblock-SmbShareAccess -MockWith {
        #             $script:NoAccess = $script:NoAccess | Where-Object {$_ -ne $UserName}
        #         }



        #         It 'Should alter permissions' {
        #             $result = Set-TargetResource @testParameters
        #             $script:ChangeAccess | Should Be $mockChangePermissionUserName
        #             $script:ReadAccess | Should Be $mockReadPermissionUserName
        #             $script:FullAccess | Should Be $mockFullPermissionUserName
        #             #$script:NoAccess | Should Be $mockNoPermissionUserName
        #         }

        #         It 'Should call the mock function Get-SmbShare' {
        #             $result = Set-TargetResource @testParameters
        #             Assert-MockCalled Get-SmbShare -Exactly -Times 1 -Scope It
        #         }

        #         It 'Should Call the mock function Get-SmbShareAccess' {
        #             $result = Set-TargetResource @testParameters
        #             Assert-MockCalled Get-SmbShareAccess -Exactly -Times 4 -Scope It
        #         }

        #         It 'Should call the mock function Set-SmbShare' {
        #             $result = Set-TargetResource @testParameters
        #             Assert-MockCalled Set-SmbShare -Exactly -Times 1 -Scope It
        #         }
        #     }
        # }

        Describe 'MSFT_SmbShare\Test-TargetResource' -Tag 'Test' {
            Context 'When the system is not in the desired state' {
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
                            ReadAccess            = @()
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
                            ReadAccess            = @()
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
                                Ensure                = 'Absent'
                            }
                        }
                    }

                    It 'Should return $false when the desired state should ''Present''' {
                        $testTargetResourceParameters = @{
                            Ensure                = 'Present'
                            Name                  = $mockSmbShare.Name
                            Path                  = $mockSmbShare.Path
                            Verbose               = $true
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
                                ReadAccess            = [System.String[]] @()
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
                            ReadAccess            = @()
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
                                Ensure                = 'Absent'
                            }
                        }
                    }

                    It 'Should return $true when the desired state should ''Absent''' {
                        $testTargetResourceParameters = @{
                            Ensure                = 'Absent'
                            Name                  = $mockSmbShare.Name
                            Path                  = $mockSmbShare.Path
                            Verbose               = $true
                        }

                        $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                        $testTargetResourceResult | Should -BeTrue
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
