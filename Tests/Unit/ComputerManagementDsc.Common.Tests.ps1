#region HEADER
$script:ModuleName = 'ComputerManagementDsc.Common'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

# Unit Test Template Version: 1.2.4
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath 'DscResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force
Import-Module (Join-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'Modules' -ChildPath $script:ModuleName)) -ChildPath "$script:ModuleName.psm1") -Force
#endregion HEADER

# Begin Testing
try
{
    InModuleScope $script:ModuleName {
        Describe 'ComputerManagementDsc.Common\Remove-CommonParameter' {
            $removeCommonParameter = @{
                Parameter1          = 'value1'
                Parameter2          = 'value2'
                Verbose             = $true
                Debug               = $true
                ErrorAction         = 'Stop'
                WarningAction       = 'Stop'
                InformationAction   = 'Stop'
                ErrorVariable       = 'errorVariable'
                WarningVariable     = 'warningVariable'
                OutVariable         = 'outVariable'
                OutBuffer           = 'outBuffer'
                PipelineVariable    = 'pipelineVariable'
                InformationVariable = 'informationVariable'
                WhatIf              = $true
                Confirm             = $true
                UseTransaction      = $true
            }

            Context 'Hashtable contains all common parameters' {
                It 'Should not throw exception' {
                    { $script:result = Remove-CommonParameter -Hashtable $removeCommonParameter -Verbose } | Should -Not -Throw
                }

                It 'Should have retained parameters in the hashtable' {
                    $script:result.Contains('Parameter1') | Should -BeTrue
                    $script:result.Contains('Parameter2') | Should -BeTrue
                }

                It 'Should have removed the common parameters from the hashtable' {
                    $script:result.Contains('Verbose') | Should -BeFalse
                    $script:result.Contains('Debug') | Should -BeFalse
                    $script:result.Contains('ErrorAction') | Should -BeFalse
                    $script:result.Contains('WarningAction') | Should -BeFalse
                    $script:result.Contains('InformationAction') | Should -BeFalse
                    $script:result.Contains('ErrorVariable') | Should -BeFalse
                    $script:result.Contains('WarningVariable') | Should -BeFalse
                    $script:result.Contains('OutVariable') | Should -BeFalse
                    $script:result.Contains('OutBuffer') | Should -BeFalse
                    $script:result.Contains('PipelineVariable') | Should -BeFalse
                    $script:result.Contains('InformationVariable') | Should -BeFalse
                    $script:result.Contains('WhatIf') | Should -BeFalse
                    $script:result.Contains('Confirm') | Should -BeFalse
                    $script:result.Contains('UseTransaction') | Should -BeFalse
                }
            }
        }

        Describe 'ComputerManagementDsc.Common\Test-DscParameterState' {
            $verbose = $true

            Context 'When testing single values' {
                $currentValues = @{
                    String    = 'a string'
                    Bool      = $true
                    Int       = 99
                    Array     = 'a', 'b', 'c'
                    Hashtable = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3'
                    }
                }

                Context 'When all values match' {
                    $desiredValues = [PSObject] @{
                        String    = 'a string'
                        Bool      = $true
                        Int       = 99
                        Array     = 'a', 'b', 'c'
                        Hashtable = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3'
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $true' {
                        $script:result | Should -Be $true
                    }
                }

                Context 'When a string is mismatched' {
                    $desiredValues = [PSObject] @{
                        String    = 'different string'
                        Bool      = $true
                        Int       = 99
                        Array     = 'a', 'b', 'c'
                        Hashtable = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3'
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When a boolean is mismatched' {
                    $desiredValues = [PSObject] @{
                        String    = 'a string'
                        Bool      = $false
                        Int       = 99
                        Array     = 'a', 'b', 'c'
                        Hashtable = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3'
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When an int is mismatched' {
                    $desiredValues = [PSObject] @{
                        String    = 'a string'
                        Bool      = $true
                        Int       = 1
                        Array     = 'a', 'b', 'c'
                        Hashtable = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3'
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When a type is mismatched' {
                    $desiredValues = [PSObject] @{
                        String = 'a string'
                        Bool   = $true
                        Int    = '99'
                        Array  = 'a', 'b', 'c'
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When a type is mismatched but TurnOffTypeChecking is used' {
                    $desiredValues = [PSObject] @{
                        String = 'a string'
                        Bool   = $true
                        Int    = '99'
                        Array  = 'a', 'b', 'c'
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -TurnOffTypeChecking `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $true' {
                        $script:result | Should -Be $true
                    }
                }

                Context 'When a value is mismatched but valuesToCheck is used to exclude them' {
                    $desiredValues = [PSObject] @{
                        String = 'a string'
                        Bool   = $false
                        Int    = 1
                        Array  = @( 'a', 'b' )
                    }

                    $valuesToCheck = @(
                        'String'
                    )

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -ValuesToCheck $valuesToCheck `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $true' {
                        $script:result | Should -Be $true
                    }
                }
            }

            Context 'When testing array values' {
                BeforeAll {
                    $currentValues = @{
                        String    = 'a string'
                        Bool      = $true
                        Int       = 99
                        Array     = 'a', 'b', 'c', 1
                        Hashtable = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3'
                        }
                    }
                }

                Context 'When array is missing a value' {
                    $desiredValues = [PSObject]@{
                        String    = 'a string'
                        Bool      = $true
                        Int       = 1
                        Array     = 'a', 'b', 'c'
                        Hashtable = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3'
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When array has an additional value' {
                    $desiredValues = [PSObject] @{
                        String = 'a string'
                        Bool   = $true
                        Int    = 1
                        Array  = 'a', 'b', 'c', 1, 2
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When array has a different value' {
                    $desiredValues = [PSObject] @{
                        String = 'a string'
                        Bool   = $true
                        Int    = 1
                        Array  = 'a', 'x', 'c', 1
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When array has different order' {
                    $desiredValues = [PSObject] @{
                        String = 'a string'
                        Bool   = $true
                        Int    = 1
                        Array  = 'c', 'b', 'a', 1
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When array has different order but SortArrayValues is used' {
                    $desiredValues = [PSObject] @{
                        String = 'a string'
                        Bool   = $true
                        Int    = 1
                        Array  = 'c', 'b', 'a', 1
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -SortArrayValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }


                Context 'When array has a value with a different type' {
                    $desiredValues = [PSObject] @{
                        String = 'a string'
                        Bool   = $true
                        Int    = 99
                        Array  = 'a', 'b', 'c', '1'
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When array has a value with a different type but TurnOffTypeChecking is used' {
                    $desiredValues = [PSObject] @{
                        String = 'a string'
                        Bool   = $true
                        Int    = 99
                        Array  = 'a', 'b', 'c', '1'
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -TurnOffTypeChecking `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $true' {
                        $script:result | Should -Be $true
                    }
                }

                Context 'When both arrays are empty' {
                    $currentValues = @{
                        String    = 'a string'
                        Bool      = $true
                        Int       = 99
                        Array     = @()
                        Hashtable = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = @()
                        }
                    }

                    $desiredValues = [PSObject]@{
                        String    = 'a string'
                        Bool      = $true
                        Int       = 99
                        Array     = @()
                        Hashtable = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = @()
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $true' {
                        $script:result | Should -Be $true
                    }
                }
            }

            Context 'When testing hashtables' {
                $currentValues = @{
                    String    = 'a string'
                    Bool      = $true
                    Int       = 99
                    Array     = 'a', 'b', 'c'
                    Hashtable = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3', 99
                    }
                }

                Context 'When hashtable is missing a value' {
                    $desiredValues = [PSObject]@{
                        String    = 'a string'
                        Bool      = $true
                        Int       = 99
                        Array     = 'a', 'b', 'c'
                        Hashtable = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3'
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When hashtable has an additional value' {
                    $desiredValues = [PSObject]@{
                        String    = 'a string'
                        Bool      = $true
                        Int       = 99
                        Array     = 'a', 'b', 'c'
                        Hashtable = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3', 99, 100
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When hashtable has a different value' {
                    $desiredValues = [PSObject]@{
                        String    = 'a string'
                        Bool      = $true
                        Int       = 99
                        Array     = 'a', 'b', 'c'
                        Hashtable = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'xx', 'v2', 'v3', 99
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When an array in hashtable has different order' {
                    $desiredValues = [PSObject]@{
                        String    = 'a string'
                        Bool      = $true
                        Int       = 99
                        Array     = 'a', 'b', 'c'
                        Hashtable = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v3', 'v2', 'v1', 99
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When an array in hashtable has different order but SortArrayValues is used' {
                    $desiredValues = [PSObject]@{
                        String    = 'a string'
                        Bool      = $true
                        Int       = 99
                        Array     = 'a', 'b', 'c'
                        Hashtable = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v3', 'v2', 'v1', 99
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -SortArrayValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $true' {
                        $script:result | Should -Be $true
                    }
                }


                Context 'When hashtable has a value with a different type' {
                    $desiredValues = [PSObject]@{
                        String    = 'a string'
                        Bool      = $true
                        Int       = 99
                        Array     = 'a', 'b', 'c'
                        Hashtable = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3', '99'
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When hashtable has a value with a different type but TurnOffTypeChecking is used' {
                    $desiredValues = [PSObject]@{
                        String    = 'a string'
                        Bool      = $true
                        Int       = 99
                        Array     = 'a', 'b', 'c'
                        Hashtable = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3', 99
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -TurnOffTypeChecking `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $true' {
                        $script:result | Should -Be $true
                    }
                }
            }

            Context 'When testing CimInstances / hashtables' {
                $currentValues = @{
                    String       = 'a string'
                    Bool         = $true
                    Int          = 99
                    Array        = 'a', 'b', 'c'
                    Hashtable    = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3', 99
                    }
                    CimInstances = [CimInstance[]](ConvertTo-CimInstance -Hashtable @{
                            String = 'a string'
                            Bool   = $true
                            Int    = 99
                            Array  = 'a, b, c'
                        })
                }

                Context 'When everything matches' {
                    $desiredValues = [PSObject]@{
                        String       = 'a string'
                        Bool         = $true
                        Int          = 99
                        Array        = 'a', 'b', 'c'
                        Hashtable    = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3', 99
                        }
                        CimInstances = [CimInstance[]](ConvertTo-CimInstance -Hashtable @{
                                String = 'a string'
                                Bool   = $true
                                Int    = 99
                                Array  = 'a, b, c'
                            })
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $true' {
                        $script:result | Should -Be $true
                    }
                }

                Context 'When CimInstances missing a value in the desired state (not recognized)' {
                    $desiredValues = [PSObject]@{
                        String       = 'a string'
                        Bool         = $true
                        Int          = 99
                        Array        = 'a', 'b', 'c'
                        Hashtable    = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3', 99
                        }
                        CimInstances = @{
                            String = 'a string'
                            Bool   = $true
                            Array  = 'a, b, c'
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $true' {
                        $script:result | Should -Be $true
                    }
                }

                Context 'When CimInstances missing a value in the desired state (recognized using ReverseCheck)' {
                    $desiredValues = [PSObject]@{
                        String       = 'a string'
                        Bool         = $true
                        Int          = 99
                        Array        = 'a', 'b', 'c'
                        Hashtable    = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3', 99
                        }
                        CimInstances = @{
                            String = 'a string'
                            Bool   = $true
                            Array  = 'a, b, c'
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -ReverseCheck `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When CimInstances have an additional value' {
                    $desiredValues = [PSObject]@{
                        String       = 'a string'
                        Bool         = $true
                        Int          = 99
                        Array        = 'a', 'b', 'c'
                        Hashtable    = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3', 99
                        }
                        CimInstances = @{
                            String = 'a string'
                            Bool   = $true
                            Int    = 99
                            Array  = 'a, b, c'
                            Test   = 'Some string'
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When CimInstances have a different value' {
                    $desiredValues = [PSObject]@{
                        String       = 'a string'
                        Bool         = $true
                        Int          = 99
                        Array        = 'a', 'b', 'c'
                        Hashtable    = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3', 99
                        }
                        CimInstances = @{
                            String = 'some other string'
                            Bool   = $true
                            Int    = 99
                            Array  = 'a, b, c'
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When CimInstances have a value with a different type' {
                    $desiredValues = [PSObject]@{
                        String       = 'a string'
                        Bool         = $true
                        Int          = 99
                        Array        = 'a', 'b', 'c'
                        Hashtable    = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3', 99
                        }
                        CimInstances = @{
                            String = 'a string'
                            Bool   = $true
                            Int    = '99'
                            Array  = 'a, b, c'
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }

                Context 'When CimInstances have a value with a different type but TurnOffTypeChecking is used' {
                    $desiredValues = [PSObject]@{
                        String       = 'a string'
                        Bool         = $true
                        Int          = 99
                        Array        = 'a', 'b', 'c'
                        Hashtable    = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3', 99
                        }
                        CimInstances = @{
                            String = 'a string'
                            Bool   = $true
                            Int    = '99'
                            Array  = 'a, b, c'
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -TurnOffTypeChecking `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $true' {
                        $script:result | Should -Be $true
                    }
                }
            }

            Context 'When reverse checking' {
                $currentValues = @{
                    String    = 'a string'
                    Bool      = $true
                    Int       = 99
                    Array     = 'a', 'b', 'c', 1
                    Hashtable = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3'
                    }
                }

                Context 'When even if missing property in the desired state' {
                    $desiredValues = [PSObject] @{
                        Array     = 'a', 'b', 'c', 1
                        Hashtable = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3'
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $true' {
                        $script:result | Should -Be $true
                    }
                }

                Context 'When missing property in the desired state' {
                    $currentValues = @{
                        String = 'a string'
                        Bool   = $true
                    }

                    $desiredValues = [PSObject] @{
                        String = 'a string'
                    }

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -ReverseCheck `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }
            }

            Context 'When testing parameter types' {
                Context 'When desired value is of the wrong type' {
                    $currentValues = @{
                        String = 'a string'
                    }

                    $desiredValues = 1, 2, 3

                    It 'Should throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Throw
                    }
                }

                Context 'When current value is of the wrong type' {
                    $currentValues = 1, 2, 3

                    $desiredValues = @{
                        String = 'a string'
                    }

                    It 'Should throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Throw
                    }
                }
            }
        }

        Describe 'ComputerManagementDsc.Common\Test-DscObjectHasProperty' {
            # Use the Get-Verb cmdlet to just get a simple object fast
            $testDscObject = (Get-Verb)[0]

            Context 'When the object contains the expected property' {
                It 'Should not throw exception' {
                    { $script:result = Test-DscObjectHasProperty -Object $testDscObject -PropertyName 'Verb' -Verbose } | Should -Not -Throw
                }

                It 'Should return $true' {
                    $script:result | Should -Be $true
                }
            }

            Context 'When the object does not contain the expected property' {
                It 'Should not throw exception' {
                    { $script:result = Test-DscObjectHasProperty -Object $testDscObject -PropertyName 'Missing' -Verbose } | Should -Not -Throw
                }

                It 'Should return $false' {
                    $script:result | Should -Be $false
                }
            }
        }

        Describe 'ComputerManagementDsc.Common\ConvertTo-CimInstance' {
            $hashtable = @{
                k1 = 'v1'
                k2 = 100
                k3 = 1, 2, 3
            }

            Context 'When the array contains the expected record count' {
                It 'Should not throw exception' {
                    { $script:result = [CimInstance[]]($hashtable | ConvertTo-CimInstance) } | Should -Not -Throw
                }

                It "Should record count should be $($hashTable.Count)" {
                    $script:result.Count | Should -Be $hashtable.Count
                }

                It 'Should return result of type CimInstance[]' {
                    $script:result.GetType().Name | Should -Be 'CimInstance[]'
                }

                It 'Should return value "k1" in the CimInstance array should be "v1"' {
                    ($script:result | Where-Object Key -eq k1).Value | Should -Be 'v1'
                }

                It 'Should return value "k2" in the CimInstance array should be "100"' {
                    ($script:result | Where-Object Key -eq k2).Value | Should -Be 100
                }

                It 'Should return value "k3" in the CimInstance array should be "1,2,3"' {
                    ($script:result | Where-Object Key -eq k3).Value | Should -Be '1,2,3'
                }
            }
        }

        Describe 'ComputerManagementDsc.Common\ConvertTo-HashTable' {
            [CimInstance[]]$cimInstances = ConvertTo-CimInstance -Hashtable @{
                k1 = 'v1'
                k2 = 100
                k3 = 1, 2, 3
            }

            Context 'When the array contains the expected record count' {
                It 'Should not throw exception' {
                    { $script:result = $cimInstances | ConvertTo-HashTable } | Should -Not -Throw
                }

                It "Should return record count of $($cimInstances.Count)" {
                    $script:result.Count | Should -Be $cimInstances.Count
                }

                It 'Should return result of type [System.Collections.Hashtable]' {
                    $script:result | Should -BeOfType [System.Collections.Hashtable]
                }

                It 'Should return value "k1" in the hashtable should be "v1"' {
                    $script:result.k1 | Should -Be 'v1'
                }

                It 'Should return value "k2" in the hashtable should be "100"' {
                    $script:result.k2 | Should -Be 100
                }

                It 'Should return value "k3" in the hashtable should be "1,2,3"' {
                    $script:result.k3 | Should -Be '1,2,3'
                }
            }
        }

        Describe 'ComputerManagementDsc.Common\Get-TimeZoneId' {
            Context '"Get-TimeZone" not available and current timezone is set to "Pacific Standard Time"' {
                Mock `
                    -CommandName Get-Command `
                    -ParameterFilter {
                        $Name -eq 'Get-TimeZone'
                    }

                Mock -CommandName Get-CimInstance -MockWith {
                    @{
                        StandardName = 'Pacific Standard Time'
                    }
                }

                It 'Returns "Pacific Standard Time"' {
                    Get-TimeZoneId | Should -Be 'Pacific Standard Time'
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-Command `
                        -ParameterFilter {
                            $Name -eq 'Get-TimeZone'
                        } -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1
                }
            }

            Context '"Get-TimeZone" not available and current timezone is set to "Russia TZ 11 Standard Time"' {
                Mock `
                    -CommandName Get-Command `
                    -ParameterFilter {
                        $Name -eq 'Get-TimeZone'
                    }

                Mock -CommandName Get-CimInstance -MockWith {
                    @{
                        StandardName = 'Russia TZ 11 Standard Time'
                    }
                }

                It 'Returns "Russia Time Zone 11"' {
                    Get-TimeZoneId | Should -Be 'Russia Time Zone 11'
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-Command `
                        -ParameterFilter {
                            $Name -eq 'Get-TimeZone'
                        } -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1
                }
            }

            Context '"Get-TimeZone" available and current timezone is set to "Pacific Standard Time"' {
                function Get-TimeZone
                {
                }

                Mock `
                    -CommandName Get-Command `
                    -ParameterFilter {
                        $Name -eq 'Get-TimeZone'
                    } -MockWith {
                        'Get-TimeZone'
                    }

                Mock `
                    -CommandName Get-TimeZone `
                    -MockWith {
                        @{
                            StandardName = 'Pacific Standard Time'
                        }
                    }

                It 'Returns "Pacific Standard Time"' {
                    Get-TimeZoneId | Should -Be 'Pacific Standard Time'
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-Command `
                        -ParameterFilter {
                            $Name -eq 'Get-TimeZone'
                        } -Exactly -Times 1

                    Assert-MockCalled -CommandName Get-TimeZone -Exactly -Times 1
                }
            }
        }

        Describe 'ComputerManagementDsc.Common\Test-TimezoneId' {
            Mock -CommandName Get-TimeZoneId -MockWith {
                'Russia Time Zone 11'
            }

            Context 'current timezone matches desired timezone' {
                It 'Should return $true' {
                    Test-TimezoneId -TimeZoneId 'Russia Time Zone 11' | Should -BeTrue
                }
            }

            Context 'current timezone does not match desired timezone' {
                It 'Should return $false' {
                    Test-TimezoneId -TimeZoneId 'GMT Standard Time' | Should -BeFalse
                }
            }
        }

        Describe 'ComputerManagementDsc.Common\Set-TimeZoneId' {
            Context '"Set-TimeZone" and "Add-Type" is not available, Tzutil Returns 0' {
                Mock `
                    -CommandName Get-Command `
                    -ParameterFilter {
                        $Name -eq 'Add-Type'
                    }

                Mock `
                    -CommandName Get-Command `
                    -ParameterFilter {
                        $Name -eq 'Set-TimeZone'
                    }

                Mock -CommandName 'TzUtil.exe' -MockWith {
                    $global:LASTEXITCODE = 0
                    return 'OK'
                }

                Mock -CommandName Add-Type

                It 'Should not throw an exception' {
                    { Set-TimeZoneId -TimezoneId 'Eastern Standard Time' } | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-Command `
                        -ParameterFilter {
                            $Name -eq 'Add-Type'
                        } -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-Command `
                        -ParameterFilter {
                            $Name -eq 'Set-TimeZone'
                        } -Exactly -Times 1

                    Assert-MockCalled -CommandName TzUtil.exe -Exactly -Times 1
                    Assert-MockCalled -CommandName Add-Type -Exactly -Times 0
                }
            }

            Context '"Set-TimeZone" is not available but "Add-Type" is available' {
                Mock `
                    -CommandName Get-Command `
                    -ParameterFilter {
                        $Name -eq 'Add-Type'
                    } -MockWith {
                        'Add-Type'
                    }

                Mock `
                    -CommandName Get-Command `
                    -ParameterFilter {
                        $Name -eq 'Set-TimeZone'
                    }

                Mock -CommandName 'TzUtil.exe' -MockWith {
                    $global:LASTEXITCODE = 0
                    return 'OK'
                }

                Mock -CommandName Add-Type
                Mock -CommandName Set-TimeZoneUsingDotNet

                It 'Should not throw an exception' {
                    { Set-TimeZoneId -TimezoneId 'Eastern Standard Time' } | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-Command `
                        -ParameterFilter {
                            $Name -eq 'Add-Type'
                        } -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-Command `
                        -ParameterFilter {
                            $Name -eq 'Set-TimeZone'
                        } -Exactly -Times 1

                    Assert-MockCalled -CommandName TzUtil.exe -Exactly -Times 0
                    Assert-MockCalled -CommandName Add-Type -Exactly -Times 0
                    Assert-MockCalled -CommandName Set-TimeZoneUsingDotNet -Exactly -Times 1
                }
            }

            Context '"Set-TimeZone" is available' {
                function Set-TimeZone
                {
                    param
                    (
                        [System.String]
                        $id
                    )
                }

                Mock `
                    -CommandName Get-Command `
                    -ParameterFilter {
                        $Name -eq 'Add-Type'
                    }

                Mock `
                    -CommandName Get-Command `
                    -ParameterFilter {
                        $Name -eq 'Set-TimeZone'
                    } -MockWith {
                        'Set-TimeZone'
                    }

                Mock -CommandName Set-TimeZone

                It 'Should not throw an exception' {
                    { Set-TimeZoneId -TimezoneId 'Eastern Standard Time' } | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-Command `
                        -ParameterFilter {
                            $Name -eq 'Add-Type'
                        } -Exactly -Times 0

                    Assert-MockCalled `
                        -CommandName Get-Command `
                        -ParameterFilter {
                            $Name -eq 'Set-TimeZone'
                        } -Exactly -Times 1

                    Assert-MockCalled -CommandName Set-TimeZone -Exactly -Times 1
                }
            }
        }

        Describe 'ComputerManagementDsc.Common\Get-PowerPlan' {
            $mockBalancedPowerPlan = @{
                FriendlyName = 'Balanced'
                Guid         = [System.Guid]'381b4222-f694-41f0-9685-ff5bb260df2e'
            }

            $mockHighPerformancePowerPlan = @{
                'FriendlyName' = 'High performance'
                'Guid'         = [System.Guid]'8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
            }

            $mockPowerSaverPowerPlan = @{
                    'FriendlyName' = 'Power saver'
                    'Guid'         = [System.Guid]'a1841308-3541-4fab-bc81-f71556f20b4a'
            }

            Context 'Only one power plan is available and "PowerPlan" parameter is not specified' {
                Mock `
                    -CommandName Get-PowerPlanUsingPInvoke `
                    -MockWith {
                        return $mockBalancedPowerPlan
                    }

                It 'Should not throw an exception' {
                    { Get-PowerPlan } | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-PowerPlanUsingPInvoke `
                        -Exactly -Times 1
                }

                It 'Should return exactly one hashtable' {
                    $result = Get-PowerPlan
                    $result | Should -BeOfType [System.Collections.Hashtable]
                    $result | Should -HaveCount 1
                }

            }

            Context 'Only one power plan is available and "PowerPlan" parameter is specified as Guid of the available plan' {
                Mock `
                    -CommandName Get-PowerPlanUsingPInvoke `
                    -MockWith {
                        return $mockBalancedPowerPlan
                    }

                It 'Should not throw an exception' {
                    { Get-PowerPlan -PowerPlan '381b4222-f694-41f0-9685-ff5bb260df2e' } | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-PowerPlanUsingPInvoke `
                        -Exactly -Times 1
                }

                It 'Should return a hashtable with the name and guid fo the power plan' {
                    $result = Get-PowerPlan -PowerPlan '381b4222-f694-41f0-9685-ff5bb260df2e'
                    $result | Should -BeOfType [System.Collections.Hashtable]
                    $result | Should -HaveCount 1
                    $result.FriendlyName | Should -Be 'Balanced'
                    $result.guid | Should -Be '381b4222-f694-41f0-9685-ff5bb260df2e'
                }
            }

            Context 'Only one power plan is available and "PowerPlan" parameter is specified as Guid of a not available plan' {
                Mock `
                    -CommandName Get-PowerPlanUsingPInvoke `
                    -MockWith {
                        return $mockBalancedPowerPlan
                    }

                It 'Should not throw an exception' {
                    { Get-PowerPlan -PowerPlan '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c' } | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-PowerPlanUsingPInvoke `
                        -Exactly -Times 1
                }

                It 'Should return nothing' {
                    $result = Get-PowerPlan -PowerPlan '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
                    $result | Should -BeNullOrEmpty
                }
            }

            Context 'Only one power plan is available and "PowerPlan" parameter is specified as name of the available plan' {
                Mock `
                    -CommandName Get-PowerPlanUsingPInvoke `
                    -MockWith {
                        return $mockBalancedPowerPlan
                    }

                It 'Should not throw an exception' {
                    { Get-PowerPlan -PowerPlan 'Balanced' } | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-PowerPlanUsingPInvoke `
                        -Exactly -Times 1
                }

                It 'Should return a hashtable with the name and guid fo the power plan' {
                    $result = Get-PowerPlan -PowerPlan 'Balanced'
                    $result | Should -BeOfType [System.Collections.Hashtable]
                    $result | Should -HaveCount 1
                    $result.FriendlyName | Should -Be 'Balanced'
                    $result.guid | Should -Be '381b4222-f694-41f0-9685-ff5bb260df2e'
                }
            }

            Context 'Only one power plan is available and "PowerPlan" parameter is specified as name of a not available plan' {
                Mock `
                    -CommandName Get-PowerPlanUsingPInvoke `
                    -MockWith {
                        return $mockBalancedPowerPlan
                    }

                It 'Should not throw an exception' {
                    { Get-PowerPlan -PowerPlan 'High performance' } | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-PowerPlanUsingPInvoke `
                        -Exactly -Times 1
                }

                It 'Should return nothing' {
                    $result = Get-PowerPlan -PowerPlan 'High performance'
                    $result | Should -BeNullOrEmpty
                }
            }

            Context 'Multiple power plans are available and "PowerPlan" parameter is not specified' {
                Mock `
                    -CommandName Get-PowerPlanUsingPInvoke `
                    -MockWith {
                        return @(
                            $mockBalancedPowerPlan
                            $mockHighPerformancePowerPlan
                            $mockPowerSaverPowerPlan
                        )
                    }

                It 'Should not throw an exception' {
                    { Get-PowerPlan } | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-PowerPlanUsingPInvoke `
                        -Exactly -Times 1
                }

                It 'Should return an array with all available plans' {
                    $result = Get-PowerPlan
                    $result | Should -HaveCount 3
                }
            }

            Context 'Multiple power plans are available and "PowerPlan" parameter is specified as Guid of an available plan' {
                Mock `
                    -CommandName Get-PowerPlanUsingPInvoke `
                    -MockWith {
                        return @(
                            $mockBalancedPowerPlan
                            $mockHighPerformancePowerPlan
                            $mockPowerSaverPowerPlan
                        )
                    }

                It 'Should not throw an exception' {
                    { Get-PowerPlan -PowerPlan '381b4222-f694-41f0-9685-ff5bb260df2e'} | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-PowerPlanUsingPInvoke `
                        -Exactly -Times 1
                }

                It 'Should return a hashtable with the name and guid fo the power plan' {
                    $result = Get-PowerPlan -PowerPlan '381b4222-f694-41f0-9685-ff5bb260df2e'
                    $result | Should -BeOfType [System.Collections.Hashtable]
                    $result | Should -HaveCount 1
                    $result.FriendlyName | Should -Be 'Balanced'
                    $result.guid | Should -Be '381b4222-f694-41f0-9685-ff5bb260df2e'
                }
            }

            Context 'Multiple power plans are available and "PowerPlan" parameter is specified as Guid of a not available plan' {
                Mock `
                    -CommandName Get-PowerPlanUsingPInvoke `
                    -MockWith {
                        return @(
                            $mockBalancedPowerPlan
                            $mockHighPerformancePowerPlan
                            $mockPowerSaverPowerPlan
                        )
                    }

                It 'Should not throw an exception' {
                    { Get-PowerPlan -PowerPlan '9c5e7fda-e8bf-4a96-9a85-a7e23a8c635c'} | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-PowerPlanUsingPInvoke `
                        -Exactly -Times 1
                }

                It 'Should return nothing' {
                    $result = Get-PowerPlan -PowerPlan '9c5e7fda-e8bf-4a96-9a85-a7e23a8c635c'
                    $result | Should -BeNullOrEmpty
                }
            }

            Context 'Multiple power plans are available and "PowerPlan" parameter is specified as name of an available plan' {
                Mock `
                    -CommandName Get-PowerPlanUsingPInvoke `
                    -MockWith {
                        return @(
                            $mockBalancedPowerPlan
                            $mockHighPerformancePowerPlan
                            $mockPowerSaverPowerPlan
                        )
                    }

                It 'Should not throw an exception' {
                    { Get-PowerPlan -PowerPlan 'High performance'} | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-PowerPlanUsingPInvoke `
                        -Exactly -Times 1
                }

                It 'Should return a hashtable with the name and guid fo the power plan' {
                    $result = Get-PowerPlan -PowerPlan 'High performance'
                    $result | Should -BeOfType [System.Collections.Hashtable]
                    $result | Should -HaveCount 1
                    $result.FriendlyName | Should -Be 'High performance'
                    $result.guid | Should -Be '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
                }
            }

            Context 'Multiple power plans are available and "PowerPlan" parameter is specified as name of a not available plan' {
                Mock `
                    -CommandName Get-PowerPlanUsingPInvoke `
                    -MockWith {
                        return @(
                            $mockBalancedPowerPlan
                            $mockHighPerformancePowerPlan
                            $mockPowerSaverPowerPlan
                        )
                    }

                It 'Should not throw an exception' {
                    { Get-PowerPlan -PowerPlan 'Some unavailable plan'} | Should -Not -Throw
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-PowerPlanUsingPInvoke `
                        -Exactly -Times 1
                }

                It 'Should return nothing' {
                    $result = Get-PowerPlan -PowerPlan 'Some unavailable plan'
                    $result | Should -BeNullOrEmpty
                }
            }
        }

        Describe 'DscResource.LocalizationHelper\Get-LocalizedData' {
            $mockTestPath = {
                return $mockTestPathReturnValue
            }

            $mockImportLocalizedData = {
                $BaseDirectory | Should -Be $mockExpectedLanguagePath
            }

            BeforeEach {
                Mock -CommandName Test-Path -MockWith $mockTestPath -Verifiable
                Mock -CommandName Import-LocalizedData -MockWith $mockImportLocalizedData -Verifiable
            }

            Context 'When loading localized data for Swedish' {
                $mockExpectedLanguagePath = 'sv-SE'
                $mockTestPathReturnValue = $true

                It 'Should call Import-LocalizedData with sv-SE language' {
                    Mock -CommandName Join-Path -MockWith {
                        return 'sv-SE'
                    } -Verifiable

                    { Get-LocalizedData -ResourceName 'DummyResource' } | Should -Not -Throw

                    Assert-MockCalled -CommandName Join-Path -Exactly -Times 3 -Scope It
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Import-LocalizedData -Exactly -Times 1 -Scope It
                }

                $mockExpectedLanguagePath = 'en-US'
                $mockTestPathReturnValue = $false

                It 'Should call Import-LocalizedData and fallback to en-US if sv-SE language does not exist' {
                    Mock -CommandName Join-Path -MockWith {
                        return $ChildPath
                    } -Verifiable

                    { Get-LocalizedData -ResourceName 'DummyResource' } | Should -Not -Throw

                    Assert-MockCalled -CommandName Join-Path -Exactly -Times 4 -Scope It
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Import-LocalizedData -Exactly -Times 1 -Scope It
                }

                Context 'When $ScriptRoot is set to a path' {
                    $mockExpectedLanguagePath = 'sv-SE'
                    $mockTestPathReturnValue = $true

                    It 'Should call Import-LocalizedData with sv-SE language' {
                        Mock -CommandName Join-Path -MockWith {
                            return 'sv-SE'
                        } -Verifiable

                        { Get-LocalizedData -ResourceName 'DummyResource' -ScriptRoot '.' } | Should -Not -Throw

                        Assert-MockCalled -CommandName Join-Path -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Import-LocalizedData -Exactly -Times 1 -Scope It
                    }

                    $mockExpectedLanguagePath = 'en-US'
                    $mockTestPathReturnValue = $false

                    It 'Should call Import-LocalizedData and fallback to en-US if sv-SE language does not exist' {
                        Mock -CommandName Join-Path -MockWith {
                            return $ChildPath
                        } -Verifiable

                        { Get-LocalizedData -ResourceName 'DummyResource' -ScriptRoot '.' } | Should -Not -Throw

                        Assert-MockCalled -CommandName Join-Path -Exactly -Times 2 -Scope It
                        Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Import-LocalizedData -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When loading localized data for English' {
                Mock -CommandName Join-Path -MockWith {
                    return 'en-US'
                } -Verifiable

                $mockExpectedLanguagePath = 'en-US'
                $mockTestPathReturnValue = $true

                It 'Should call Import-LocalizedData with en-US language' {
                    { Get-LocalizedData -ResourceName 'DummyResource' } | Should -Not -Throw
                }
            }

            Assert-VerifiableMock
        }

        Describe 'DscResource.LocalizationHelper\New-InvalidOperationException' {
            Context 'When calling with Message parameter only' {
                It 'Should throw the correct error' {
                    $mockErrorMessage = 'Mocked error'

                    { New-InvalidOperationException -Message $mockErrorMessage } | Should -Throw $mockErrorMessage
                }
            }

            Context 'When calling with both the Message and ErrorRecord parameter' {
                It 'Should throw the correct error' {
                    $mockErrorMessage = 'Mocked error'
                    $mockExceptionErrorMessage = 'Mocked exception error message'

                    $mockException = New-Object -TypeName System.Exception -ArgumentList $mockExceptionErrorMessage
                    $mockErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $mockException, $null, 'InvalidResult', $null

                    { New-InvalidOperationException -Message $mockErrorMessage -ErrorRecord $mockErrorRecord } | Should -Throw ('System.InvalidOperationException: {0} ---> System.Exception: {1}' -f $mockErrorMessage, $mockExceptionErrorMessage)
                }
            }

            Assert-VerifiableMock
        }

        Describe 'DscResource.LocalizationHelper\New-InvalidArgumentException' {
            Context 'When calling with both the Message and ArgumentName parameter' {
                It 'Should throw the correct error' {
                    $mockErrorMessage = 'Mocked error'
                    $mockArgumentName = 'MockArgument'

                    { New-InvalidArgumentException -Message $mockErrorMessage -ArgumentName $mockArgumentName } | Should -Throw ('Parameter name: {0}' -f $mockArgumentName)
                }
            }

            Assert-VerifiableMock
        }

        Describe 'DscResource.LocalizationHelper\Test-IsNanoServer' {
            Context 'When the cmdlet Get-ComputerInfo does not exist' {
                BeforeAll {
                    Mock -CommandName Test-Command {
                        return $false
                    }
                }

                Test-IsNanoServer | Should -BeFalse
            }

            Context 'When the current computer is a Nano server' {
                BeforeAll {
                    Mock -CommandName Test-Command {
                        return $true
                    }

                    Mock -CommandName Get-ComputerInfo {
                        return @{
                            OsProductType = 'Server'
                            OsServerLevel = 'NanoServer'
                        }
                    }
                }

                Test-IsNanoServer | Should -BeTrue
            }

            Context 'When the current computer is not a Nano server' {
                BeforeAll {
                    Mock -CommandName Test-Command {
                        return $true
                    }

                    Mock -CommandName Get-ComputerInfo {
                        return @{
                            OsProductType = 'Server'
                            OsServerLevel = 'FullServer'
                        }
                    }
                }

                Test-IsNanoServer | Should -BeFalse
            }
        }
    }
}
finally
{
    #region FOOTER
    #endregion
}
