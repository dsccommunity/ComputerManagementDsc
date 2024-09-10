<#
    .SYNOPSIS
        Unit test for DSC_SmbShare DSC resource.

    .NOTES
#>

# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
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
}

BeforeAll {
    $script:dscModuleName = 'ComputerManagementDsc'
    $script:dscResourceName = 'DSC_SmbShare'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force
}

Describe 'DSC_SmbShare\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
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
                Add-Member -MemberType NoteProperty -Name 'Special' -Value $false -PassThru |
                Add-Member -MemberType NoteProperty -Name 'ScopeName' -Value '*' -PassThru -Force
        )

        $mockSmbShareAccess = @(
            (
                New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockShareName -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'ScopeName' -Value '*' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccountName' -Value $mockFullPermissionUserName[0] -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessControlType' -Value 'Allow' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessRight' -Value 'Full' -PassThru -Force
            ),
            (
                New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockShareName -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'ScopeName' -Value '*' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccountName' -Value $mockFullPermissionUserName[1] -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessControlType' -Value 'Allow' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessRight' -Value 'Full' -PassThru -Force
            ),
            (
                New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockShareName -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'ScopeName' -Value '*' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccountName' -Value $mockChangePermissionUserName[0] -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessControlType' -Value 'Allow' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessRight' -Value 'Change' -PassThru -Force
            ),
            (
                New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockShareName -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'ScopeName' -Value '*' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccountName' -Value $mockReadPermissionUserName[0] -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessControlType' -Value 'Allow' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessRight' -Value 'Read' -PassThru -Force
            ),
            (
                New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockShareName -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'ScopeName' -Value '*' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccountName' -Value $mockNoPermissionUserName[0] -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessControlType' -Value 'Deny' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessRight' -Value 'Full' -PassThru -Force
            )
        )
    }

    Context 'When the system is in the desired state' {
        BeforeAll {
            Mock -CommandName Get-SmbShare -MockWith {
                return $mockSmbShare
            }

            Mock -CommandName Get-SmbShareAccess -MockWith {
                return $mockSmbShareAccess
            }
        }

        It 'Should return the correct access memberships' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParameters = @{
                    Name = 'TestShare'
                    Path = 'c:\temp'
                }

                $getTargetResourceResult = Get-TargetResource @testParameters

                $getTargetResourceResult.ChangeAccess | Should -HaveCount 1
                $getTargetResourceResult.ChangeAccess[0] | Should -BeIn @('User1')

                $getTargetResourceResult.ReadAccess | Should -HaveCount 1
                $getTargetResourceResult.ReadAccess[0] | Should -BeIn @('User2')

                $getTargetResourceResult.FullAccess | Should -HaveCount 2
                $getTargetResourceResult.FullAccess[0] | Should -BeIn @('User3', 'User4')
                $getTargetResourceResult.FullAccess[1] | Should -BeIn @('User3', 'User4')

                $getTargetResourceResult.NoAccess | Should -HaveCount 1
                $getTargetResourceResult.NoAccess[0] | Should -BeIn @('DeniedUser1')
            }

            Should -Invoke Get-SmbShare -Exactly -Times 1 -Scope It
            Should -Invoke Get-SmbShareAccess -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            Mock -CommandName Get-SmbShare
        }

        It 'Should return the correct values' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testParameters = @{
                    Name = 'TestShare'
                    Path = 'c:\temp'
                }

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
            }

            Should -Invoke Get-SmbShare -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'DSC_SmbShare\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
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
                Add-Member -MemberType NoteProperty -Name 'Special' -Value $false -PassThru |
                Add-Member -MemberType NoteProperty -Name 'ScopeName' -Value '*' -PassThru -Force
        )

        $mockSmbShareAccess = @(
            (
                New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockShareName -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'ScopeName' -Value '*' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccountName' -Value $mockFullPermissionUserName[0] -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessControlType' -Value 'Allow' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessRight' -Value 'Full' -PassThru -Force
            ),
            (
                New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockShareName -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'ScopeName' -Value '*' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccountName' -Value $mockFullPermissionUserName[1] -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessControlType' -Value 'Allow' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessRight' -Value 'Full' -PassThru -Force
            ),
            (
                New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockShareName -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'ScopeName' -Value '*' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccountName' -Value $mockChangePermissionUserName[0] -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessControlType' -Value 'Allow' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessRight' -Value 'Change' -PassThru -Force
            ),
            (
                New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockShareName -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'ScopeName' -Value '*' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccountName' -Value $mockReadPermissionUserName[0] -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessControlType' -Value 'Allow' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessRight' -Value 'Read' -PassThru -Force
            ),
            (
                New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockShareName -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'ScopeName' -Value '*' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccountName' -Value $mockNoPermissionUserName[0] -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessControlType' -Value 'Deny' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessRight' -Value 'Full' -PassThru -Force
            )
        )
    }

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
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $setTargetResourceParameters = @{
                            Name                  = 'TestShare'
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
                        }

                        { Set-TargetResource @setTargetResourceParameters } | Should -Throw $script:localizedData.WrongAccessParameters
                    }
                }
            }

            Context 'When access permissions are given' {
                It 'Should call the correct mocks' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $setTargetResourceParameters = @{
                            Name                  = 'TestShare'
                            Path                  = 'TestDrive:\Temp'
                            Description           = 'Some description'
                            ConcurrentUserLimit   = 2
                            EncryptData           = $false
                            FolderEnumerationMode = 'AccessBased'
                            CachingMode           = 'Manual'
                            ContinuouslyAvailable = $true
                            ChangeAccess          = @('User1')
                            ReadAccess            = @('User2')
                            FullAccess            = @('User3', 'User4')
                            NoAccess              = @('DeniedUser1')
                        }

                        { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                    }

                    Should -Invoke New-SmbShare -Exactly -Times 1 -Scope It
                    Should -Invoke Set-SmbShare -Exactly -Times 0 -Scope It
                    Should -Invoke Remove-SmbShare -Exactly -Times 0 -Scope It
                    Should -Invoke Remove-SmbShareAccessPermission -Exactly -Times 0 -Scope It
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
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceParameters = @{
                        Name   = 'TestShare'
                        Path   = 'AnyValue'
                        Ensure = 'Absent'
                    }

                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke New-SmbShare -Exactly -Times 0 -Scope It
                Should -Invoke Set-SmbShare -Exactly -Times 0 -Scope It
                Should -Invoke Remove-SmbShare -Exactly -Times 1 -Scope It
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
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetResourceParameters = @{
                        Name                  = 'TestShare'
                        Path                  = 'TestDrive:\Temp'
                        Description           = 'Some description'
                        ConcurrentUserLimit   = 2
                        EncryptData           = $false
                        FolderEnumerationMode = 'AccessBased'
                        CachingMode           = 'Manual'
                        ContinuouslyAvailable = $true
                        ChangeAccess          = @('User1')
                        ReadAccess            = @('User2')
                        FullAccess            = @('User3', 'User4')
                        NoAccess              = @('DeniedUser1')
                    }

                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke Set-SmbShare -Exactly -Times 1 -Scope It
                Should -Invoke Remove-SmbShareAccessPermission -Exactly -Times 1 -Scope It
                Should -Invoke Add-SmbShareAccessPermission -Exactly -Times 1 -Scope It
                Should -Invoke New-SmbShare -Exactly -Times 0 -Scope It
                Should -Invoke Remove-SmbShare -Exactly -Times 0 -Scope It
            }


            Context 'When the share exists, but on the wrong path and recreate is allowed' {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Name   = $mockSmbShare.Name
                        Path   = $mockSmbShare.Path
                        Ensure = 'Present'
                    }
                }

                It 'Should drop and recreate the share' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $setTargetResourceParameters = @{
                            Name  = 'TestShare'
                            Path  = 'TestDrive:\Temp'
                            Force = $true
                        }

                        Set-TargetResource @setTargetResourceParameters
                    }

                    Should -Invoke -CommandName Remove-SmbShare -Times 1
                    Should -Invoke -CommandName New-SmbShare -Times 1
                }
            }

            Context 'When the share exists, but on the wrong path and recreate is not allowed' {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Name   = $mockSmbShare.Name
                        Path   = $mockSmbShare.Path
                        Ensure = 'Present'
                    }
                }

                It 'Should display a warning with the message the share cannot be updated' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $setTargetResourceParameters = @{
                            Name  = 'TestShare'
                            Path  = 'TestDrive:\Temp'
                            Force = $false
                        }

                        $message = Set-TargetResource @setTargetResourceParameters 3>&1
                        $message | Should -Be ($script:localizedData.NoRecreateShare -f
                            $setTargetResourceParameters['Name'], 'c:\temp', $setTargetResourceParameters['Path']
                        )
                    }
                }
            }

            Context 'When the share exists, but on the wrong scope and recreate is allowed' {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Name      = $mockSmbShare.Name
                        Path      = $mockSmbShare.Path
                        ScopeName = $mockSmbShare.ScopeName
                        Ensure    = 'Present'
                    }
                }

                It 'Should drop and recreate the share' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $setTargetResourceParameters = @{
                            Name      = 'TestShare'
                            Path      = 'c:\temp'
                            ScopeName = 'clustergroup1'
                            Force     = $true
                        }

                        Set-TargetResource @setTargetResourceParameters
                    }

                    Should -Invoke -CommandName Remove-SmbShare -Times 1
                    Should -Invoke -CommandName New-SmbShare -Times 1
                }
            }

            Context 'When the share exists, but on the wrong scope and recreate is not allowed' {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Name      = $mockSmbShare.Name
                        Path      = $mockSmbShare.Path
                        ScopeName = $mockSmbShare.ScopeName
                        Ensure    = 'Present'
                    }
                }

                It 'Should display a warning with the message the share cannot be updated' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $setTargetResourceParameters = @{
                            Name      = 'TestShare'
                            Path      = 'c:\temp'
                            ScopeName = 'clustergroup1'
                            Force     = $false
                        }

                        $message = Set-TargetResource @setTargetResourceParameters 3>&1
                        $message | Should -Be ($script:localizedData.NoRecreateShare -f
                            $setTargetResourceParameters['Name'], 'c:\temp', $setTargetResourceParameters['Path']
                        )
                    }
                }
            }
        }
    }
}

Describe 'DSC_SmbShare\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
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
                Add-Member -MemberType NoteProperty -Name 'Special' -Value $false -PassThru |
                Add-Member -MemberType NoteProperty -Name 'ScopeName' -Value '*' -PassThru -Force
        )
    }
    Context 'When the system is not in the desired state' {
        Context 'When no member are provided in any of the access permission collections' {
            It 'Should throw the correct error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceParameters = @{
                        Name         = 'TestShare'
                        Path         = 'TestDrive:\Temp'
                        FullAccess   = @()
                        ChangeAccess = @()
                        ReadAccess   = @()
                        NoAccess     = @()
                        Ensure       = 'Present'
                    }

                    {
                        Test-TargetResource @testTargetResourceParameters
                    } | Should -Throw $script:localizedData.WrongAccessParameters
                }
            }
        }

        Context 'When there is a configured SMB share' {
            BeforeDiscovery {
                $mockDefaultTestCaseValues = @{
                    TestCase              = ''
                    Name                  = 'TestShare'
                    Path                  = 'c:\temp'
                    Description           = 'Dummy share for unit testing'
                    ConcurrentUserLimit   = 10
                    EncryptData           = $false
                    FolderEnumerationMode = 'AccessBased'
                    CachingMode           = 'Manual'
                    ContinuouslyAvailable = $true
                    FullAccess            = @()
                    ChangeAccess          = @()
                    ReadAccess            = @('User2')
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
            }

            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Name                  = $mockSmbShare.Name
                        Path                  = $mockSmbShare.Path
                        Description           = $mockSmbShare.Description
                        ConcurrentUserLimit   = [System.UInt32] 10
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

            It 'Should return $false when property ''<TestCase>'' has the wrong value' -TestCases $testCases {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

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
                    }

                    $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                    $testTargetResourceResult | Should -BeFalse
                }
            }

            It 'Should return $false when the desired state should be ''Absent''' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceParameters = @{
                        Ensure                = 'Absent'
                        Name                  = 'TestShare'
                        Path                  = 'c:\temp'
                        Description           = 'Dummy share for unit testing'
                        ConcurrentUserLimit   = [System.UInt32] 10
                        EncryptData           = $false
                        FolderEnumerationMode = 'AccessBased'
                        CachingMode           = 'Manual'
                        ContinuouslyAvailable = $true
                        FullAccess            = @()
                        ChangeAccess          = @()
                        ReadAccess            = @('User2')
                        NoAccess              = @()
                    }

                    $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                    $testTargetResourceResult | Should -BeFalse
                }
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
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceParameters = @{
                        Ensure = 'Present'
                        Name   = 'TestShare'
                        Path   = 'c:\temp'
                    }

                    $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                    $testTargetResourceResult | Should -BeFalse
                }
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
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceParameters = @{
                        Ensure                = 'Present'
                        Name                  = 'TestShare'
                        Path                  = 'c:\temp'
                        Description           = 'Dummy share for unit testing'
                        ConcurrentUserLimit   = [System.UInt32] 10
                        EncryptData           = $false
                        FolderEnumerationMode = 'AccessBased'
                        CachingMode           = 'Manual'
                        ContinuouslyAvailable = $true
                        FullAccess            = @()
                        ChangeAccess          = @()
                        ReadAccess            = @('User2')
                        NoAccess              = @()
                    }

                    $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                    $testTargetResourceResult | Should -BeTrue
                }
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
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceParameters = @{
                        Ensure = 'Absent'
                        Name   = 'TestShare'
                        Path   = 'c:\temp'
                    }

                    $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                    $testTargetResourceResult | Should -BeTrue
                }
            }
        }
    }
}

Describe 'DSC_SmbShare\Add-SmbShareAccessPermission' -Tag 'Private' {
    BeforeAll {
        $mockShareName = 'TestShare'
        $mockChangePermissionUserName = @('User1')
        $mockReadPermissionUserName = @('User2')
        $mockFullPermissionUserName = @('User3', 'User4')
        $mockNoPermissionUserName = @('DeniedUser1')
        $mockSmbShareAccess = @(
            (
                New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockShareName -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'ScopeName' -Value '*' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccountName' -Value $mockFullPermissionUserName[0] -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessControlType' -Value 'Allow' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessRight' -Value 'Full' -PassThru -Force
            ),
            (
                New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockShareName -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'ScopeName' -Value '*' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccountName' -Value $mockFullPermissionUserName[1] -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessControlType' -Value 'Allow' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessRight' -Value 'Full' -PassThru -Force
            ),
            (
                New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockShareName -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'ScopeName' -Value '*' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccountName' -Value $mockChangePermissionUserName[0] -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessControlType' -Value 'Allow' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessRight' -Value 'Change' -PassThru -Force
            ),
            (
                New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockShareName -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'ScopeName' -Value '*' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccountName' -Value $mockReadPermissionUserName[0] -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessControlType' -Value 'Allow' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessRight' -Value 'Read' -PassThru -Force
            ),
            (
                New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockShareName -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'ScopeName' -Value '*' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccountName' -Value $mockNoPermissionUserName[0] -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessControlType' -Value 'Deny' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessRight' -Value 'Full' -PassThru -Force
            )
        )

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
        AfterEach {
            Should -Invoke -CommandName Block-SmbShareAccess -Exactly -Times 0 -Scope It
        }

        Context 'When an account with full access should be added' {
            It 'Should not throw an error and call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $addSmbShareAccessPermissionParameters = @{
                        Name       = 'TestShare'
                        # User3 is an already present account. It should not be added.
                        FullAccess = @('User3', 'NewUser')
                    }

                    { Add-SmbShareAccessPermission @addSmbShareAccessPermissionParameters } | Should -Not -Throw
                }
                <#
                    Assert that Grant-SmbShareAccess is only called once, and
                    that only time was with the correct parameters.
                #>
                Should -Invoke -CommandName Grant-SmbShareAccess -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Grant-SmbShareAccess -ParameterFilter {
                    $Name -eq $mockShareName `
                        -and $AccessRight -eq 'Full' `
                        -and $AccountName -eq 'NewUser'
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When an account with change access should be added' {
            It 'Should not throw an error and call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $addSmbShareAccessPermissionParameters = @{
                        Name         = 'TestShare'
                        # User1 is an already present account. It should not be added.
                        ChangeAccess = @('User1', 'NewUser')
                    }

                    { Add-SmbShareAccessPermission @addSmbShareAccessPermissionParameters } | Should -Not -Throw
                }

                <#
                    Assert that Grant-SmbShareAccess is only called once, and
                    that only time was with the correct parameters.
                #>
                Should -Invoke -CommandName Grant-SmbShareAccess -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Grant-SmbShareAccess -ParameterFilter {
                    $Name -eq $mockShareName `
                        -and $AccessRight -eq 'Change' `
                        -and $AccountName -eq 'NewUser'
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When an account with read access should be added' {
            It 'Should not throw an error and call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $addSmbShareAccessPermissionParameters = @{
                        Name       = 'TestShare'
                        # User2 is an already present account. It should not be added.
                        ReadAccess = @('User2', 'NewUser')
                    }

                    { Add-SmbShareAccessPermission @addSmbShareAccessPermissionParameters } | Should -Not -Throw
                }

                <#
                    Assert that Grant-SmbShareAccess is only called once, and
                    that only time was with the correct parameters.
                #>
                Should -Invoke -CommandName Grant-SmbShareAccess -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Grant-SmbShareAccess -ParameterFilter {
                    $Name -eq $mockShareName `
                        -and $AccessRight -eq 'Read' `
                        -and $AccountName -eq 'NewUser'
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When accounts with different access should be added' {
            It 'Should not throw an error and call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $addSmbShareAccessPermissionParameters = @{
                        Name         = 'TestShare'
                        # User1, User2, and User3 is an already present account. It should not be added.
                        FullAccess   = @('User3', 'NweUser1')
                        ReadAccess   = @('User2', 'NweUser2')
                        ChangeAccess = @('User1', 'NweUser3')
                    }

                    { Add-SmbShareAccessPermission @addSmbShareAccessPermissionParameters } | Should -Not -Throw
                }

                <#
                    Assert that Grant-SmbShareAccess is only called once, and
                    that only time was with the correct parameters.
                #>
                Should -Invoke -CommandName Grant-SmbShareAccess -Exactly -Times 3 -Scope It
                Should -Invoke -CommandName Grant-SmbShareAccess -ParameterFilter {
                    $Name -eq $mockShareName `
                        -and $AccessRight -eq 'Change' `
                        -and $AccountName -eq 'NweUser3'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Grant-SmbShareAccess -ParameterFilter {
                    $Name -eq $mockShareName `
                        -and $AccessRight -eq 'Full' `
                        -and $AccountName -eq 'NweUser1'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Grant-SmbShareAccess -ParameterFilter {
                    $Name -eq $mockShareName `
                        -and $AccessRight -eq 'Read' `
                        -and $AccountName -eq 'NweUser2'
                } -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When denying permissions on an SMB share' {
        AfterEach {
            Should -Invoke -CommandName Grant-SmbShareAccess -Exactly -Times 0 -Scope It
        }

        Context 'When an account with denied access should be revoked' {
            It 'Should not throw an error and call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $removeSmbShareAccessPermissionParameters = @{
                        Name     = 'TestShare'
                        NoAccess = @('DeniedUser1', 'NewDeniedUser')
                    }

                    { Add-SmbShareAccessPermission @removeSmbShareAccessPermissionParameters } | Should -Not -Throw
                }

                <#
                    Assert that Block-SmbShareAccess is only called once, and
                    that only time was with the correct parameters.
                #>
                Should -Invoke -CommandName Block-SmbShareAccess -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Block-SmbShareAccess -ParameterFilter {
                    $Name -eq $mockShareName `
                        -and $AccountName -eq 'NewDeniedUser'
                } -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'DSC_SmbShare\Remove-SmbShareAccessPermission' -Tag 'Private' {
    BeforeAll {
        $mockShareName = 'TestShare'
        $mockChangePermissionUserName = @('User1')
        $mockReadPermissionUserName = @('User2')
        $mockFullPermissionUserName = @('User3', 'User4')
        $mockNoPermissionUserName = @('DeniedUser1')
        $mockSmbShareAccess = @(
            (
                New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockShareName -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'ScopeName' -Value '*' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccountName' -Value $mockFullPermissionUserName[0] -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessControlType' -Value 'Allow' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessRight' -Value 'Full' -PassThru -Force
            ),
            (
                New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockShareName -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'ScopeName' -Value '*' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccountName' -Value $mockFullPermissionUserName[1] -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessControlType' -Value 'Allow' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessRight' -Value 'Full' -PassThru -Force
            ),
            (
                New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockShareName -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'ScopeName' -Value '*' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccountName' -Value $mockChangePermissionUserName[0] -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessControlType' -Value 'Allow' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessRight' -Value 'Change' -PassThru -Force
            ),
            (
                New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockShareName -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'ScopeName' -Value '*' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccountName' -Value $mockReadPermissionUserName[0] -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessControlType' -Value 'Allow' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessRight' -Value 'Read' -PassThru -Force
            ),
            (
                New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockShareName -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'ScopeName' -Value '*' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccountName' -Value $mockNoPermissionUserName[0] -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessControlType' -Value 'Deny' -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'AccessRight' -Value 'Full' -PassThru -Force
            )
        )
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
            Should -Invoke -CommandName Unblock-SmbShareAccess -Exactly -Times 0 -Scope It
        }

        Context 'When an account with full access should be removed' {
            BeforeAll {
                $mockExpectedAccountToBeRemoved = 'User4'
            }

            It 'Should not throw an error and call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $removeSmbShareAccessPermissionParameters = @{
                        Name       = 'TestShare'
                        FullAccess = @('User3')
                    }

                    { Remove-SmbShareAccessPermission @removeSmbShareAccessPermissionParameters } | Should -Not -Throw
                }
                <#
                    Assert that Revoke-SmbShareAccess is only called once, and
                    that only time was with the correct parameters.
                #>
                Should -Invoke -CommandName Revoke-SmbShareAccess -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Revoke-SmbShareAccess -ParameterFilter {
                    $Name -eq $mockShareName `
                        -and $AccountName -eq $mockExpectedAccountToBeRemoved
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When an all accounts with full access should be removed' {
            BeforeAll {
                $mockExpectedAccountToBeRemoved1 = 'User3'
                $mockExpectedAccountToBeRemoved2 = 'User4'
            }

            It 'Should not throw an error and call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $removeSmbShareAccessPermissionParameters = @{
                        Name       = 'TestShare'
                        FullAccess = @()
                    }

                    { Remove-SmbShareAccessPermission @removeSmbShareAccessPermissionParameters } | Should -Not -Throw
                }
                <#
                    Assert that Revoke-SmbShareAccess is called twice, and
                    that both times it is called with the correct parameters.
                #>
                Should -Invoke -CommandName Revoke-SmbShareAccess -Exactly -Times 2 -Scope It
                Should -Invoke -CommandName Revoke-SmbShareAccess -ParameterFilter {
                    $Name -eq $mockShareName `
                        -and $AccountName -eq $mockExpectedAccountToBeRemoved1
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Revoke-SmbShareAccess -ParameterFilter {
                    $Name -eq $mockShareName `
                        -and $AccountName -eq $mockExpectedAccountToBeRemoved2
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When an account with change access should be removed' {
            BeforeAll {
                $mockExpectedAccountToBeRemoved = 'User1'
            }

            It 'Should not throw an error and call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $removeSmbShareAccessPermissionParameters = @{
                        Name         = 'TestShare'
                        ChangeAccess = @()
                    }

                    { Remove-SmbShareAccessPermission @removeSmbShareAccessPermissionParameters } | Should -Not -Throw
                }
                <#
                    Assert that Revoke-SmbShareAccess is only called once, and
                    that only time was with the correct parameters.
                #>
                Should -Invoke -CommandName Revoke-SmbShareAccess -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Revoke-SmbShareAccess -ParameterFilter {
                    $Name -eq $mockShareName `
                        -and $AccountName -eq $mockExpectedAccountToBeRemoved
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When an account with read access should be removed' {
            BeforeAll {
                $mockExpectedAccountToBeRemoved = 'User2'
            }

            It 'Should not throw an error and call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $removeSmbShareAccessPermissionParameters = @{
                        Name       = 'TestShare'
                        ReadAccess = @()
                    }

                    { Remove-SmbShareAccessPermission @removeSmbShareAccessPermissionParameters } | Should -Not -Throw
                }
                <#
                    Assert that Revoke-SmbShareAccess is only called for each account,
                    and each time with the correct parameters.
                #>
                Should -Invoke -CommandName Revoke-SmbShareAccess -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Revoke-SmbShareAccess -ParameterFilter {
                    $Name -eq $mockShareName `
                        -and $AccountName -eq $mockExpectedAccountToBeRemoved
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When an all granted access should be removed' {
            It 'Should not throw an error and call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $removeSmbShareAccessPermissionParameters = @{
                        Name         = 'TestShare'
                        FullAccess   = @()
                        ChangeAccess = @()
                        ReadAccess   = @()
                    }

                    { Remove-SmbShareAccessPermission @removeSmbShareAccessPermissionParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Revoke-SmbShareAccess -Exactly -Times 4 -Scope It
                Should -Invoke -CommandName Revoke-SmbShareAccess -ParameterFilter {
                    $Name -eq $mockShareName `
                        -and $AccountName -eq 'User1'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Revoke-SmbShareAccess -ParameterFilter {
                    $Name -eq $mockShareName `
                        -and $AccountName -eq 'User2'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Revoke-SmbShareAccess -ParameterFilter {
                    $Name -eq $mockShareName `
                        -and $AccountName -eq 'User3'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Revoke-SmbShareAccess -ParameterFilter {
                    $Name -eq $mockShareName `
                        -and $AccountName -eq 'User4'
                } -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When revoking denied permissions from an SMB share' {
        AfterEach {
            Should -Invoke -CommandName Revoke-SmbShareAccess -Exactly -Times 0 -Scope It
        }

        Context 'When an account with denied access should be revoked' {
            BeforeAll {
                $mockExpectedAccountToBeUnblocked = 'DeniedUser1'
            }

            It 'Should not throw an error and call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $removeSmbShareAccessPermissionParameters = @{
                        Name     = 'TestShare'
                        NoAccess = @()
                        Verbose  = $true
                    }

                    { Remove-SmbShareAccessPermission @removeSmbShareAccessPermissionParameters } | Should -Not -Throw
                }
                <#
                    Assert that Block-SmbShareAccess is only called once, and
                    that only time was with the correct parameters.
                #>
                Should -Invoke -CommandName Unblock-SmbShareAccess -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Unblock-SmbShareAccess -ParameterFilter {
                    $Name -eq $mockShareName `
                        -and $AccountName -eq $mockExpectedAccountToBeUnblocked
                } -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'DSC_SmbShare\Assert-AccessPermissionParameters' -Tag 'Private' {
    Context 'When asserting correct provided access permissions parameters' {
        Context 'When providing at least one member in one of the access permission collections' {
            BeforeDiscovery {
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
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

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
        }

        Context 'When not providing any members in any of the access permission collections' {
            It 'Should throw the correct error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

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
