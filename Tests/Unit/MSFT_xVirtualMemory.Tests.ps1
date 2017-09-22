#region HEADER
$script:DSCModuleName      = 'xComputerManagement'
$script:DSCResourceName    = 'MSFT_xVirtualMemory'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) ) {
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName  `
    -TestType Unit
#endregion HEADER

function Invoke-TestSetup {
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try {
    Invoke-TestSetup

    InModuleScope 'MSFT_xVirtualMemory' {
        <#
            Remove-CimInstance overridden to enable PSObject
            to be passed to mocked version.
        #>
        function Remove-CimInstance {
            param
            (
                $InputObject
            )
        }

        $testDrive = 'K:'
        $testInitialSize = 10
        $testMaximumSize = 20
        $testPageFileName = "$testDrive\pagefile.sys"

        $mockGetDriveInfo = {
            [PSObject] @{
                Name = "$testDrive\"
            }
        }

        $mockAutomaticPagefileEnabled = {
            [PSObject] @{
                AutomaticManagedPageFile = $true
                Name = $testPageFileName
            }
        }

        $mockAutomaticPagefileDisabled = {
            [PSObject] @{
                AutomaticManagedPageFile = $false
                Name = $testPageFileName
            }
        }

        $mockPageFileSetting = {
            [PSObject] @{
                Name        = $testPageFileName
                InitialSize = $testInitialSize
                MaximumSize = $testMaximumSize
            }
        }

        $parameterFilterGetPageFileSetting = {
            $Drive -eq $testDrive
        }

        $parameterFilterSetPageFileSetting = {
            $Namespace -eq 'root\cimv2' -and `
            $Query -eq "Select * from Win32_PageFileSetting where SettingID='pagefile.sys @ $testDrive'" -and `
            $Property.InitialSize -eq $testInitialSize -and `
            $Property.MaximumSize -eq $testMaximumSize
        }

        $parameterFilterEnableAutoManagePaging = {
            $Namespace -eq 'root\cimv2' -and `
            $Query -eq 'Select * from Win32_ComputerSystem' -and `
            $Property.AutomaticManagedPageFile -eq $True
        }

        $parameterFilterDisableAutoManagePaging = {
            $Namespace -eq 'root\cimv2' -and `
            $Query -eq 'Select * from Win32_ComputerSystem' -and `
            $Property.AutomaticManagedPageFile -eq $False
        }

        $parameterFilterNewPageFileSetting = {
            $Namespace -eq 'root\cimv2' -and `
            $ClassName -eq 'Win32_PageFileSetting' -and `
            $Property.Name -eq $testPageFileName
        }

        $parameterFilterComputerSystem = {
            $ClassName -eq 'Win32_ComputerSystem'
        }

        $parameterFilterPageFileSetting = {
            $ClassName -eq 'Win32_PageFileSetting' -and `
            $Filter -eq "SettingID='pagefile.sys @ $testDrive'"
        }

        Describe 'MSFT_xVirtualMemory\Get-TargetResource' {
            BeforeEach {
                $testParameters = @{
                    Drive   = $testDrive
                    Type    = 'CustomSize'
                    Verbose = $true
                }
            }

            Context 'When automatic managed page file is enabled' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter $parameterFilterComputerSystem `
                    -MockWith $mockAutomaticPagefileEnabled

                It 'Should return type set to AutoManagePagingFile' {
                    $result = Get-TargetResource @testParameters
                    $result.Type | Should Be 'AutoManagePagingFile'
                }

                It 'Should call the correct mocks' {
                    Assert-MockCalled `
                        -CommandName Get-CimInstance `
                        -ParameterFilter $parameterFilterComputerSystem `
                        -Exactly -Times 1
                }
            }

            Context 'When automatic managed page file is disabled and no page file set' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter $parameterFilterComputerSystem `
                    -MockWith $mockAutomaticPagefileDisabled

                Mock `
                    -CommandName Get-PageFileSetting `
                    -ParameterFilter $parameterFilterGetPageFileSetting

                It 'Should return type set to NoPagingFile' {
                    $result = Get-TargetResource @testParameters
                    $result.Type | Should Be 'NoPagingFile'
                }

                It 'Should call the correct mocks' {
                    Assert-MockCalled `
                        -CommandName Get-CimInstance `
                        -ParameterFilter $parameterFilterComputerSystem `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-PageFileSetting `
                        -ParameterFilter $parameterFilterGetPageFileSetting `
                        -Exactly -Times 1
                }
            }

            Context 'When automatic managed page file is disabled and system managed size is set' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter $parameterFilterComputerSystem `
                    -MockWith $mockAutomaticPagefileDisabled

                Mock `
                    -CommandName Get-PageFileSetting `
                    -ParameterFilter $parameterFilterGetPageFileSetting `
                    -MockWith {
                        [PSObject] @{
                            InitialSize = 0
                            MaximumSize = 0
                            Name        = "$testDrive\"
                        }
                    }

                It 'Should return a expected type and drive letter' {
                    $result = Get-TargetResource @testParameters
                    $result.Type | Should Be 'SystemManagedSize'
                    $result.Drive | Should Be ([System.IO.DriveInfo] $testParameters.Drive).Name
                }

                It 'Should call the correct mocks' {
                    Assert-MockCalled `
                        -CommandName Get-CimInstance `
                        -ParameterFilter $parameterFilterComputerSystem `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-PageFileSetting `
                        -ParameterFilter $parameterFilterGetPageFileSetting `
                        -Exactly -Times 1
                }
            }

            Context 'When automatic managed page file is disabled and custom size is set' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter $parameterFilterComputerSystem `
                    -MockWith $mockAutomaticPagefileDisabled

                Mock `
                    -CommandName Get-PageFileSetting `
                    -ParameterFilter $parameterFilterGetPageFileSetting `
                    -MockWith {
                        [PSObject] @{
                            InitialSize = 10
                            MaximumSize = 20
                            Name        = "$testDrive\"
                        }
                    }

                It 'Should return expected type and drive letter' {
                    $result = Get-TargetResource @testParameters
                    $result.Type | Should Be 'CustomSize'
                    $result.Drive | Should Be ([System.IO.DriveInfo] $testParameters.Drive).Name
                }

                It 'Should call the correct mocks' {
                    Assert-MockCalled `
                        -CommandName Get-CimInstance `
                        -ParameterFilter $parameterFilterComputerSystem `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-PageFileSetting `
                        -ParameterFilter $parameterFilterGetPageFileSetting `
                        -Exactly -Times 1
                }
            }
        }

        Describe 'MSFT_xVirtualMemory\Set-TargetResource' {
            BeforeEach {
                <#
                    These mocks are to handle when disk drive
                    used for testing does not exist.
                #>
                Mock `
                    -CommandName Get-DriveInfo `
                    -ParameterFilter { $Drive -eq $testDrive } `
                    -MockWith $mockGetDriveInfo

                Mock `
                    -CommandName Join-Path `
                    -ParameterFilter {
                        $Path -eq "$testDrive\" -and `
                        $ChildPath -eq 'pagefile.sys'
                    } `
                    -MockWith { "$testDrive\pagefile.sys"}

            }

            Context 'When automatic managed page file should be enabled' {
                Mock `
                    -CommandName Get-CimInstance `
                    -ParameterFilter $parameterFilterComputerSystem `
                    -MockWith $mockAutomaticPagefileDisabled

                Mock `
                    -CommandName Set-AutoManagePaging `
                    -ParameterFilter { $State -eq 'Enable' }

                It 'Should not throw an exception' {
                    $testParameters = @{
                        Drive       = $testDrive
                        Type        = 'AutoManagePagingFile'
                        InitialSize = 0
                        MaximumSize = 0
                        Verbose     = $true
                    }

                    { Set-TargetResource @testParameters } | Should Not Throw
                }

                It 'Should call the correct mocks' {
                    Assert-MockCalled `
                        -CommandName Get-CimInstance `
                        -ParameterFilter $parameterFilterComputerSystem `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Set-AutoManagePaging `
                        -ParameterFilter { $State -eq 'Enable' } `
                        -Exactly -Times 1
                }
            }

            Context 'CustomSize is required' {
                Context 'When automatic managed page file is enabled and no page file set' {
                    Mock `
                        -CommandName Get-CimInstance `
                        -ParameterFilter $parameterFilterComputerSystem `
                        -MockWith $mockAutomaticPagefileEnabled

                    Mock `
                        -CommandName Set-AutoManagePaging `
                        -ParameterFilter { $State -eq 'Disable' }

                    Mock `
                        -CommandName Get-PageFileSetting `
                        -ParameterFilter { $Drive -eq $testDrive }

                    Mock `
                        -CommandName New-PageFile `
                        -ParameterFilter { $PageFileName -eq $testPageFileName }

                    Mock `
                        -CommandName Set-PageFileSetting `
                        -ParameterFilter {
                            $Drive -eq $testDrive -and `
                            $InitialSize -eq $testInitialSize -and `
                            $MaximumSize -eq $testMaximumSize
                        }

                    It 'Should not throw an exception' {
                        $testParameters = @{
                            Drive       = $testDrive
                            Type        = 'CustomSize'
                            InitialSize = $testInitialSize
                            MaximumSize = $testMaximumSize
                            Verbose     = $true
                        }

                        { Set-TargetResource @testParameters } | Should Not Throw
                    }

                    It 'Should call the correct mocks' {
                        Assert-MockCalled `
                            -CommandName Get-CimInstance `
                            -ParameterFilter $parameterFilterComputerSystem `
                            -Exactly -Times 1

                        Assert-MockCalled `
                            -CommandName Set-AutoManagePaging `
                            -ParameterFilter { $State -eq 'Disable' } `
                            -Exactly -Times 1

                        Assert-MockCalled `
                            -CommandName Get-PageFileSetting `
                            -ParameterFilter { $Drive -eq $testDrive } `
                            -Exactly -Times 1

                        Assert-MockCalled `
                            -CommandName New-PageFile `
                            -ParameterFilter { $PageFileName -eq $testPageFileName } `
                            -Exactly -Times 1

                        Assert-MockCalled `
                            -CommandName Set-PageFileSetting `
                            -ParameterFilter {
                                $Drive -eq $testDrive -and `
                                $InitialSize -eq $testInitialSize -and `
                                $MaximumSize -eq $testMaximumSize
                            } `
                            -Exactly -Times 1
                    }
                }

                Context 'When automatic managed page file is enabled and page file is set' {
                    Mock `
                        -CommandName Get-CimInstance `
                        -ParameterFilter $parameterFilterComputerSystem `
                        -MockWith $mockAutomaticPagefileEnabled

                    Mock `
                        -CommandName Set-AutoManagePaging `
                        -ParameterFilter { $State -eq 'Disable' }

                    Mock `
                        -CommandName Get-PageFileSetting `
                        -ParameterFilter { $Drive -eq $testDrive } `
                        -MockWith $mockPageFileSetting

                    Mock `
                        -CommandName New-PageFile `
                        -ParameterFilter { $PageFileName -eq $testPageFileName }

                    Mock `
                        -CommandName Set-PageFileSetting `
                        -ParameterFilter {
                            $Drive -eq $testDrive -and `
                            $InitialSize -eq $testInitialSize -and `
                            $MaximumSize -eq $testMaximumSize
                        }

                    It 'Should not throw an exception' {
                        $testParameters = @{
                            Drive       = $testDrive
                            Type        = 'CustomSize'
                            InitialSize = $testInitialSize
                            MaximumSize = $testMaximumSize
                            Verbose     = $true
                        }

                        { Set-TargetResource @testParameters } | Should Not Throw
                    }

                    It 'Should call the correct mocks' {
                        Assert-MockCalled `
                            -CommandName Get-CimInstance `
                            -ParameterFilter $parameterFilterComputerSystem `
                            -Exactly -Times 1

                        Assert-MockCalled `
                            -CommandName Set-AutoManagePaging `
                            -ParameterFilter { $State -eq 'Disable' } `
                            -Exactly -Times 1

                        Assert-MockCalled `
                            -CommandName Get-PageFileSetting `
                            -ParameterFilter { $Drive -eq $testDrive } `
                            -Exactly -Times 1

                        Assert-MockCalled `
                            -CommandName New-PageFile `
                            -ParameterFilter { $PageFileName -eq $testPageFileName } `
                            -Exactly -Times 0

                        Assert-MockCalled `
                            -CommandName Set-PageFileSetting `
                            -ParameterFilter {
                                $Drive -eq $testDrive -and `
                                $InitialSize -eq $testInitialSize -and `
                                $MaximumSize -eq $testMaximumSize
                            } `
                            -Exactly -Times 1
                    }
                }

                Context 'SystemManagedSize is required' {
                    Context 'When automatic managed page file is enabled and no page file set' {
                        Mock `
                            -CommandName Get-CimInstance `
                            -ParameterFilter $parameterFilterComputerSystem `
                            -MockWith $mockAutomaticPagefileEnabled

                        Mock `
                            -CommandName Set-AutoManagePaging `
                            -ParameterFilter { $State -eq 'Disable' }

                        Mock `
                            -CommandName Get-PageFileSetting `
                            -ParameterFilter { $Drive -eq $testDrive }

                        Mock `
                            -CommandName New-PageFile `
                            -ParameterFilter { $PageFileName -eq $testPageFileName }

                        Mock `
                            -CommandName Set-PageFileSetting `
                            -ParameterFilter {
                                $Drive -eq $testDrive
                            }

                        It 'Should not throw an exception' {
                            $testParameters = @{
                                Drive       = $testDrive
                                Type        = 'SystemManagedSize'
                                Verbose     = $true
                            }

                            { Set-TargetResource @testParameters } | Should Not Throw
                        }

                        It 'Should call the correct mocks' {
                            Assert-MockCalled `
                                -CommandName Get-CimInstance `
                                -ParameterFilter $parameterFilterComputerSystem `
                                -Exactly -Times 1

                            Assert-MockCalled `
                                -CommandName Set-AutoManagePaging `
                                -ParameterFilter { $State -eq 'Disable' } `
                                -Exactly -Times 1

                            Assert-MockCalled `
                                -CommandName Get-PageFileSetting `
                                -ParameterFilter { $Drive -eq $testDrive } `
                                -Exactly -Times 1

                            Assert-MockCalled `
                                -CommandName New-PageFile `
                                -ParameterFilter { $PageFileName -eq $testPageFileName } `
                                -Exactly -Times 1

                            Assert-MockCalled `
                                -CommandName Set-PageFileSetting `
                                -ParameterFilter {
                                    $Drive -eq $testDrive
                                } `
                                -Exactly -Times 1
                        }
                    }
                }

                Context 'When automatic managed page file is enabled and page file is set' {
                    Mock `
                        -CommandName Get-CimInstance `
                        -ParameterFilter $parameterFilterComputerSystem `
                        -MockWith $mockAutomaticPagefileEnabled

                    Mock `
                        -CommandName Set-AutoManagePaging `
                        -ParameterFilter { $State -eq 'Disable' }

                    Mock `
                        -CommandName Get-PageFileSetting `
                        -ParameterFilter { $Drive -eq $testDrive } `
                        -MockWith $mockPageFileSetting

                    Mock `
                        -CommandName New-PageFile `
                        -ParameterFilter { $PageFileName -eq $testPageFileName }

                    Mock `
                        -CommandName Set-PageFileSetting `
                        -ParameterFilter {
                            $Drive -eq $testDrive
                        }

                    It 'Should not throw an exception' {
                        $testParameters = @{
                            Drive       = $testDrive
                            Type        = 'SystemManagedSize'
                            Verbose     = $true
                        }

                        { Set-TargetResource @testParameters } | Should Not Throw
                    }

                    It 'Should call the correct mocks' {
                        Assert-MockCalled `
                            -CommandName Get-CimInstance `
                            -ParameterFilter $parameterFilterComputerSystem `
                            -Exactly -Times 1

                        Assert-MockCalled `
                            -CommandName Set-AutoManagePaging `
                            -ParameterFilter { $State -eq 'Disable' } `
                            -Exactly -Times 1

                        Assert-MockCalled `
                            -CommandName Get-PageFileSetting `
                            -ParameterFilter { $Drive -eq $testDrive } `
                            -Exactly -Times 1

                        Assert-MockCalled `
                            -CommandName New-PageFile `
                            -ParameterFilter { $PageFileName -eq $testPageFileName } `
                            -Exactly -Times 0

                        Assert-MockCalled `
                            -CommandName Set-PageFileSetting `
                            -ParameterFilter {
                                $Drive -eq $testDrive
                            } `
                            -Exactly -Times 1
                    }
                }

                Context 'NoPagingFile is required' {
                    Context 'When automatic managed page file is enabled and no page file set' {
                        Mock `
                            -CommandName Get-CimInstance `
                            -ParameterFilter $parameterFilterComputerSystem `
                            -MockWith $mockAutomaticPagefileEnabled

                        Mock `
                            -CommandName Set-AutoManagePaging `
                            -ParameterFilter { $State -eq 'Disable' }

                        Mock `
                            -CommandName Get-PageFileSetting `
                            -ParameterFilter { $Drive -eq $testDrive }

                        Mock `
                            -CommandName Remove-CimInstance

                        It 'Should not throw an exception' {
                            $testParameters = @{
                                Drive       = $testDrive
                                Type        = 'NoPagingFile'
                                Verbose     = $true
                            }

                            { Set-TargetResource @testParameters } | Should Not Throw
                        }

                        It 'Should call the correct mocks' {
                            Assert-MockCalled `
                                -CommandName Get-CimInstance `
                                -ParameterFilter $parameterFilterComputerSystem `
                                -Exactly -Times 1

                            Assert-MockCalled `
                                -CommandName Set-AutoManagePaging `
                                -ParameterFilter { $State -eq 'Disable' } `
                                -Exactly -Times 1

                            Assert-MockCalled `
                                -CommandName Get-PageFileSetting `
                                -ParameterFilter { $Drive -eq $testDrive } `
                                -Exactly -Times 1

                            Assert-MockCalled `
                                -CommandName Remove-CimInstance `
                                -Exactly -Times 0
                        }
                    }
                }

                Context 'When automatic managed page file is enabled and page file is set' {
                    Mock `
                        -CommandName Get-CimInstance `
                        -ParameterFilter $parameterFilterComputerSystem `
                        -MockWith $mockAutomaticPagefileEnabled

                    Mock `
                        -CommandName Set-AutoManagePaging `
                        -ParameterFilter { $State -eq 'Disable' }

                    Mock `
                        -CommandName Get-PageFileSetting `
                        -ParameterFilter { $Drive -eq $testDrive } `
                        -MockWith $mockPageFileSetting

                    Mock `
                        -CommandName Remove-CimInstance

                    It 'Should not throw an exception' {
                        $testParameters = @{
                            Drive       = $testDrive
                            Type        = 'NoPagingFile'
                            Verbose     = $true
                        }

                        { Set-TargetResource @testParameters } | Should Not Throw
                    }

                    It 'Should call the correct mocks' {
                        Assert-MockCalled `
                            -CommandName Get-CimInstance `
                            -ParameterFilter $parameterFilterComputerSystem `
                            -Exactly -Times 1

                        Assert-MockCalled `
                            -CommandName Set-AutoManagePaging `
                            -ParameterFilter { $State -eq 'Disable' } `
                            -Exactly -Times 1

                        Assert-MockCalled `
                            -CommandName Get-PageFileSetting `
                            -ParameterFilter { $Drive -eq $testDrive } `
                            -Exactly -Times 1

                        Assert-MockCalled `
                            -CommandName Remove-CimInstance `
                            -Exactly -Times 1
                    }
                }
            }
        }

        Describe 'MSFT_xVirtualMemory\Test-TargetResource' {
            Context 'In desired state' {
                Context 'When automatic managed page file is enabled' {
                    Mock `
                        -CommandName Get-CimInstance `
                        -ParameterFilter $parameterFilterComputerSystem `
                        -MockWith $mockAutomaticPagefileEnabled

                    It 'Should return true' {
                        $testParameters = @{
                            Drive       = $testDrive
                            Type        = 'AutoManagePagingFile'
                            InitialSize = 0
                            MaximumSize = 0
                            Verbose     = $true
                        }

                        $result = Test-TargetResource @testParameters
                        $result | Should Be $true
                    }

                    It 'Should call the correct mocks' {
                        Assert-MockCalled `
                            -CommandName Get-CimInstance `
                            -ParameterFilter $parameterFilterComputerSystem `
                            -Exactly -Times 1
                    }
                }

                Context 'When automatic managed page file is disabled and no page file set' {
                    Mock `
                        -CommandName Get-CimInstance `
                        -ParameterFilter $parameterFilterComputerSystem `
                        -MockWith $mockAutomaticPagefileDisabled

                    Mock `
                        -CommandName Get-PageFileSetting `
                        -ParameterFilter $parameterFilterGetPageFileSetting

                    It 'Should return true' {
                        $testParameters = @{
                            Drive       = $testDrive
                            Type        = 'NoPagingFile'
                            InitialSize = 0
                            MaximumSize = 0
                            Verbose     = $true
                        }

                        $result = Test-TargetResource @testParameters
                        $result | Should Be $true
                    }

                    It 'Should call the correct mocks' {
                        Assert-MockCalled `
                            -CommandName Get-CimInstance `
                            -ParameterFilter $parameterFilterComputerSystem `
                            -Exactly -Times 1

                        Assert-MockCalled `
                            -CommandName Get-PageFileSetting `
                            -ParameterFilter $parameterFilterGetPageFileSetting `
                            -Exactly -Times 1
                    }
                }

                Context 'When automatic managed page file is disabled and system managed size is set' {
                    Mock `
                        -CommandName Get-CimInstance `
                        -ParameterFilter $parameterFilterComputerSystem `
                        -MockWith $mockAutomaticPagefileDisabled

                    Mock `
                        -CommandName Get-PageFileSetting `
                        -ParameterFilter $parameterFilterGetPageFileSetting `
                        -MockWith {
                            [PSObject] @{
                                InitialSize = 0
                                MaximumSize = 0
                                Name        = "$testDrive\"
                            }
                        }

                    It 'Should return true' {
                        $testParameters = @{
                            Drive       = $testDrive
                            Type        = 'SystemManagedSize'
                            InitialSize = 0
                            MaximumSize = 0
                            Verbose     = $true
                        }

                        $result = Test-TargetResource @testParameters
                        $result | Should Be $true
                    }

                    It 'Should call the correct mocks' {
                        Assert-MockCalled `
                            -CommandName Get-CimInstance `
                            -ParameterFilter $parameterFilterComputerSystem `
                            -Exactly -Times 1

                        Assert-MockCalled `
                            -CommandName Get-PageFileSetting `
                            -ParameterFilter $parameterFilterGetPageFileSetting `
                            -Exactly -Times 1
                    }
                }

                Context 'When automatic managed page file is disabled and custom size is set' {
                    Mock `
                        -CommandName Get-CimInstance `
                        -ParameterFilter $parameterFilterComputerSystem `
                        -MockWith $mockAutomaticPagefileDisabled

                    Mock `
                        -CommandName Get-PageFileSetting `
                        -ParameterFilter $parameterFilterGetPageFileSetting `
                        -MockWith {
                            [PSObject] @{
                                InitialSize = $testInitialSize
                                MaximumSize = $testMaximumSize
                                Name        = "$testDrive\"
                            }
                        }

                    It 'Should return true' {
                        $testParameters = @{
                            Drive       = $testDrive
                            Type        = 'CustomSize'
                            InitialSize = $testInitialSize
                            MaximumSize = $testMaximumSize
                            Verbose     = $true
                        }

                        $result = Test-TargetResource @testParameters
                        $result | Should Be $true
                    }

                    It 'Should call the correct mocks' {
                        Assert-MockCalled `
                            -CommandName Get-CimInstance `
                            -ParameterFilter $parameterFilterComputerSystem `
                            -Exactly -Times 1

                        Assert-MockCalled `
                            -CommandName Get-PageFileSetting `
                            -ParameterFilter $parameterFilterGetPageFileSetting `
                            -Exactly -Times 1
                    }
                }
            }

            Context 'Not in desired state' {
                Context 'When automatic managed page file is enabled' {
                    Mock `
                        -CommandName Get-CimInstance `
                        -ParameterFilter $parameterFilterComputerSystem `
                        -MockWith $mockAutomaticPagefileDisabled

                    It 'Should return false' {
                        $testParameters = @{
                            Drive       = $testDrive
                            Type        = 'AutoManagePagingFile'
                            InitialSize = 0
                            MaximumSize = 0
                            Verbose     = $true
                        }

                        $result = Test-TargetResource @testParameters
                        $result | Should Be $false
                    }

                    It 'Should call the correct mocks' {
                        Assert-MockCalled `
                            -CommandName Get-CimInstance `
                            -ParameterFilter $parameterFilterComputerSystem `
                            -Exactly -Times 1
                    }
                }

                Context 'When automatic managed page file is disabled and no page file set' {
                    Mock `
                        -CommandName Get-CimInstance `
                        -ParameterFilter $parameterFilterComputerSystem `
                        -MockWith $mockAutomaticPagefileDisabled

                    Mock `
                        -CommandName Get-PageFileSetting `
                        -ParameterFilter $parameterFilterGetPageFileSetting `
                        -MockWith {
                            [PSObject] @{
                                InitialSize = $testInitialSize
                                MaximumSize = $testMaximumSize
                                Name        = "$testDrive\"
                            }
                        }

                    It 'Should return false' {
                        $testParameters = @{
                            Drive       = $testDrive
                            Type        = 'NoPagingFile'
                            InitialSize = 0
                            MaximumSize = 0
                            Verbose     = $true
                        }

                        $result = Test-TargetResource @testParameters
                        $result | Should Be $false
                    }

                    It 'Should call the correct mocks' {
                        Assert-MockCalled `
                            -CommandName Get-CimInstance `
                            -ParameterFilter $parameterFilterComputerSystem `
                            -Exactly -Times 1

                        Assert-MockCalled `
                            -CommandName Get-PageFileSetting `
                            -ParameterFilter $parameterFilterGetPageFileSetting `
                            -Exactly -Times 1
                    }
                }

                Context 'When automatic managed page file is disabled and system managed size is set' {
                    Mock `
                        -CommandName Get-CimInstance `
                        -ParameterFilter $parameterFilterComputerSystem `
                        -MockWith $mockAutomaticPagefileDisabled

                    Mock `
                        -CommandName Get-PageFileSetting `
                        -ParameterFilter $parameterFilterGetPageFileSetting `
                        -MockWith {
                            [PSObject] @{
                                InitialSize = $testInitialSize
                                MaximumSize = $testMaximumSize
                                Name        = "$testDrive\"
                            }
                        }

                    It 'Should return false' {
                        $testParameters = @{
                            Drive       = $testDrive
                            Type        = 'SystemManagedSize'
                            InitialSize = 0
                            MaximumSize = 0
                            Verbose     = $true
                        }

                        $result = Test-TargetResource @testParameters
                        $result | Should Be $false
                    }

                    It 'Should call the correct mocks' {
                        Assert-MockCalled `
                            -CommandName Get-CimInstance `
                            -ParameterFilter $parameterFilterComputerSystem `
                            -Exactly -Times 1

                        Assert-MockCalled `
                            -CommandName Get-PageFileSetting `
                            -ParameterFilter $parameterFilterGetPageFileSetting `
                            -Exactly -Times 1
                    }
                }

                Context 'When automatic managed page file is disabled and custom size is set and initial size differs' {
                    Mock `
                        -CommandName Get-CimInstance `
                        -ParameterFilter $parameterFilterComputerSystem `
                        -MockWith $mockAutomaticPagefileDisabled

                    Mock `
                        -CommandName Get-PageFileSetting `
                        -ParameterFilter $parameterFilterGetPageFileSetting `
                        -MockWith {
                            [PSObject] @{
                                InitialSize = $testInitialSize
                                MaximumSize = $testMaximumSize
                                Name        = "$testDrive\"
                            }
                        }

                    It 'Should return false' {
                        $testParameters = @{
                            Drive       = $testDrive
                            Type        = 'CustomSize'
                            InitialSize = $testInitialSize + 10
                            MaximumSize = $testMaximumSize
                            Verbose     = $true
                        }

                        $result = Test-TargetResource @testParameters
                        $result | Should Be $false
                    }

                    It 'Should call the correct mocks' {
                        Assert-MockCalled `
                            -CommandName Get-CimInstance `
                            -ParameterFilter $parameterFilterComputerSystem `
                            -Exactly -Times 1

                        Assert-MockCalled `
                            -CommandName Get-PageFileSetting `
                            -ParameterFilter $parameterFilterGetPageFileSetting `
                            -Exactly -Times 1
                    }
                }

                Context 'When automatic managed page file is disabled and custom size is set and maximum size differs' {
                    Mock `
                        -CommandName Get-CimInstance `
                        -ParameterFilter $parameterFilterComputerSystem `
                        -MockWith $mockAutomaticPagefileDisabled

                    Mock `
                        -CommandName Get-PageFileSetting `
                        -ParameterFilter $parameterFilterGetPageFileSetting `
                        -MockWith {
                            [PSObject] @{
                                InitialSize = $testInitialSize
                                MaximumSize = $testMaximumSize
                                Name        = "$testDrive\"
                            }
                        }

                    It 'Should return false' {
                        $testParameters = @{
                            Drive       = $testDrive
                            Type        = 'CustomSize'
                            InitialSize = $testInitialSize
                            MaximumSize = $testMaximumSize + 10
                            Verbose     = $true
                        }

                        $result = Test-TargetResource @testParameters
                        $result | Should Be $false
                    }

                    It 'Should call the correct mocks' {
                        Assert-MockCalled `
                            -CommandName Get-CimInstance `
                            -ParameterFilter $parameterFilterComputerSystem `
                            -Exactly -Times 1

                        Assert-MockCalled `
                            -CommandName Get-PageFileSetting `
                            -ParameterFilter $parameterFilterGetPageFileSetting `
                            -Exactly -Times 1
                    }
                }
            }

            Describe 'MSFT_xVirtualMemory\Get-PageFileSetting' {
                Context "Page file defined on drive $testDrive" {
                    Mock `
                        -CommandName Get-CimInstance `
                        -ParameterFilter $parameterFilterPageFileSetting `
                        -MockWith {
                            [PSObject] @{
                                InitialSize = $testInitialSize
                                MaximumSize = $testMaximumSize
                                Name        = "$testDrive\"
                            }
                        }

                    It 'Should return the expected object' {
                        $result = Get-PageFileSetting -Drive $testDrive -Verbose
                        $result.InitialSize | Should Be $testInitialSize
                        $result.MaximumSize | Should Be $testMaximumSize
                        $result.Name | Should Be "$testDrive\"
                    }

                    It 'Should call the correct mocks' {
                        Assert-MockCalled `
                            -CommandName Get-CimInstance `
                            -ParameterFilter $parameterFilterPageFileSetting `
                            -Exactly -Times 1
                    }
                }
            }

            Describe 'MSFT_xVirtualMemory\Set-PageFileSetting' {
                Context "Set page file settings on drive $testDrive" {
                    Mock `
                        -CommandName Set-CimInstance `
                        -ParameterFilter $parameterFilterSetPageFileSetting

                    It 'Should not throw an exception' {
                        {
                            Set-PageFileSetting `
                                -Drive $testDrive `
                                -InitialSize $testInitialSize `
                                -MaximumSize $testMaximumSize `
                                -Verbose
                         } | Should Not Throw
                    }

                    It 'Should call the correct mocks' {
                        Assert-MockCalled `
                            -CommandName Set-CimInstance `
                            -ParameterFilter $parameterFilterSetPageFileSetting `
                            -Exactly -Times 1
                    }
                }
            }

            Describe 'MSFT_xVirtualMemory\Set-AutoManagePaging' {
                Context "Enable auto managed page file" {
                    Mock `
                        -CommandName Set-CimInstance `
                        -ParameterFilter $parameterFilterEnableAutoManagePaging

                    It 'Should not throw an exception' {
                        { Set-AutoManagePaging -State Enable -Verbose } | Should Not Throw
                    }

                    It 'Should call the correct mocks' {
                        Assert-MockCalled `
                            -CommandName Set-CimInstance `
                            -ParameterFilter $parameterFilterEnableAutoManagePaging `
                            -Exactly -Times 1
                    }
                }

                Context "Disable auto managed page file" {
                    Mock `
                        -CommandName Set-CimInstance `
                        -ParameterFilter $parameterFilterDisableAutoManagePaging

                    It 'Should not throw an exception' {
                        { Set-AutoManagePaging -State Disable -Verbose } | Should Not Throw
                    }

                    It 'Should call the correct mocks' {
                        Assert-MockCalled `
                            -CommandName Set-CimInstance `
                            -ParameterFilter $parameterFilterDisableAutoManagePaging `
                            -Exactly -Times 1
                    }
                }
            }

            Describe 'MSFT_xVirtualMemory\New-PageFile' {
                Context "Create a new page file" {
                    Mock `
                        -CommandName New-CimInstance `
                        -ParameterFilter $parameterFilterNewPageFileSetting

                    It 'Should not throw an exception' {
                        { New-PageFile -PageFileName $testPageFileName -Verbose } | Should Not Throw
                    }

                    It 'Should call the correct mocks' {
                        Assert-MockCalled `
                            -CommandName New-CimInstance `
                            -ParameterFilter $parameterFilterNewPageFileSetting `
                            -Exactly -Times 1
                    }
                }
            }
        }
    }
}
finally {
    Invoke-TestCleanup
}
