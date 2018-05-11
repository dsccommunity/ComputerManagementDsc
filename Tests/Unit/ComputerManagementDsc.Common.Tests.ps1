$script:ModuleName = 'ComputerManagementDsc.Common'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

#region HEADER
# Unit Test Template Version: 1.1.0
$script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\ComputerManagementDsc'
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
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
                    $script:result.Contains('Parameter1') | Should -Be $true
                    $script:result.Contains('Parameter2') | Should -Be $true
                }

                It 'Should have removed the common parameters from the hashtable' {
                    $script:result.Contains('Verbose') | Should -Be $false
                    $script:result.Contains('Debug') | Should -Be $false
                    $script:result.Contains('ErrorAction') | Should -Be $false
                    $script:result.Contains('WarningAction') | Should -Be $false
                    $script:result.Contains('InformationAction') | Should -Be $false
                    $script:result.Contains('ErrorVariable') | Should -Be $false
                    $script:result.Contains('WarningVariable') | Should -Be $false
                    $script:result.Contains('OutVariable') | Should -Be $false
                    $script:result.Contains('OutBuffer') | Should -Be $false
                    $script:result.Contains('PipelineVariable') | Should -Be $false
                    $script:result.Contains('InformationVariable') | Should -Be $false
                    $script:result.Contains('WhatIf') | Should -Be $false
                    $script:result.Contains('Confirm') | Should -Be $false
                    $script:result.Contains('UseTransaction') | Should -Be $false
                }
            }
        }

        Describe 'ComputerManagementDsc.Common\Test-DscParameterState' {
            Context 'All current parameters match desired parameters' {
                $currentValues = @{
                    parameterString = 'a string'
                    parameterBool = $true
                    parameterInt = 99
                    parameterArray = @( 'a', 'b', 'c' )
                }

                $desiredValues = [PSObject] @{
                    parameterString = 'a string'
                    parameterBool = $true
                    parameterInt = 99
                    parameterArray = @( 'a', 'b', 'c' )
                }

                $valuesToCheck = @(
                    'parameterString'
                    'parameterBool'
                    'ParameterInt'
                    'ParameterArray'
                )

                It 'Should not throw exception' {
                    { $script:result = Test-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -ValuesToCheck $valuesToCheck `
                            -Verbose } | Should -Not -Throw
                }

                It 'Should return $true' {
                    $script:result | Should -Be $true
                }
            }

            Context 'The current parameters do not match desired parameters because a string mismatches' {
                $currentValues = @{
                    parameterString = 'a string'
                    parameterBool = $true
                    parameterInt = 99
                    parameterArray = @( 'a', 'b', 'c' )
                }

                $desiredValues = [PSObject] @{
                    parameterString = 'different string'
                    parameterBool = $true
                    parameterInt = 99
                    parameterArray = @( 'a', 'b', 'c' )
                }

                $valuesToCheck = @(
                    'parameterString'
                    'parameterBool'
                    'ParameterInt'
                    'ParameterArray'
                )

                It 'Should not throw exception' {
                    { $script:result = Test-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -ValuesToCheck $valuesToCheck `
                            -Verbose } | Should -Not -Throw
                }

                It 'Should return $false' {
                    $script:result | Should -Be $false
                }
            }

            Context 'The current parameters do not match desired parameters because a boolean mismatches' {
                $currentValues = @{
                    parameterString = 'a string'
                    parameterBool = $true
                    parameterInt = 99
                    parameterArray = @( 'a', 'b', 'c' )
                }

                $desiredValues = [PSObject] @{
                    parameterString = 'a string'
                    parameterBool = $false
                    parameterInt = 99
                    parameterArray = @( 'a', 'b', 'c' )
                }

                $valuesToCheck = @(
                    'parameterString'
                    'parameterBool'
                    'ParameterInt'
                    'ParameterArray'
                )

                It 'Should not throw exception' {
                    { $script:result = Test-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -ValuesToCheck $valuesToCheck `
                            -Verbose } | Should -Not -Throw
                }

                It 'Should return $false' {
                    $script:result | Should -Be $false
                }
            }

            Context 'The current parameters do not match desired parameters because a int mismatches' {
                $currentValues = @{
                    parameterString = 'a string'
                    parameterBool = $true
                    parameterInt = 99
                    parameterArray = @( 'a', 'b', 'c' )
                }

                $desiredValues = [PSObject] @{
                    parameterString = 'a string'
                    parameterBool = $true
                    parameterInt = 1
                    parameterArray = @( 'a', 'b', 'c' )
                }

                $valuesToCheck = @(
                    'parameterString'
                    'parameterBool'
                    'ParameterInt'
                    'ParameterArray'
                )

                It 'Should not throw exception' {
                    { $script:result = Test-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -ValuesToCheck $valuesToCheck `
                            -Verbose } | Should -Not -Throw
                }

                It 'Should return $false' {
                    $script:result | Should -Be $false
                }
            }

            Context 'The current parameters do not match desired parameters because an array is missing a value' {
                $currentValues = @{
                    parameterString = 'a string'
                    parameterBool = $true
                    parameterInt = 99
                    parameterArray = @( 'a', 'b', 'c' )
                }

                $desiredValues = [PSObject] @{
                    parameterString = 'a string'
                    parameterBool = $true
                    parameterInt = 1
                    parameterArray = @( 'a', 'b' )
                }

                $valuesToCheck = @(
                    'parameterString'
                    'parameterBool'
                    'ParameterInt'
                    'ParameterArray'
                )

                It 'Should not throw exception' {
                    { $script:result = Test-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -ValuesToCheck $valuesToCheck `
                            -Verbose } | Should -Not -Throw
                }

                It 'Should return $false' {
                    $script:result | Should -Be $false
                }
            }

            Context 'The current parameters do not match desired parameters because an array has an additional value' {
                $currentValues = @{
                    parameterString = 'a string'
                    parameterBool = $true
                    parameterInt = 99
                    parameterArray = @( 'a', 'b', 'c' )
                }

                $desiredValues = [PSObject] @{
                    parameterString = 'a string'
                    parameterBool = $true
                    parameterInt = 1
                    parameterArray = @( 'a', 'b', 'c', 'd' )
                }

                $valuesToCheck = @(
                    'parameterString'
                    'parameterBool'
                    'ParameterInt'
                    'ParameterArray'
                )

                It 'Should not throw exception' {
                    { $script:result = Test-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -ValuesToCheck $valuesToCheck `
                            -Verbose } | Should -Not -Throw
                }

                It 'Should return $false' {
                    $script:result | Should -Be $false
                }
            }

            Context 'The current parameters do not match desired parameters because an array has a different value' {
                $currentValues = @{
                    parameterString = 'a string'
                    parameterBool = $true
                    parameterInt = 99
                    parameterArray = @( 'a', 'b', 'c' )
                }

                $desiredValues = [PSObject] @{
                    parameterString = 'a string'
                    parameterBool = $true
                    parameterInt = 1
                    parameterArray = @( 'a', 'd', 'c' )
                }

                $valuesToCheck = @(
                    'parameterString'
                    'parameterBool'
                    'ParameterInt'
                    'ParameterArray'
                )

                It 'Should not throw exception' {
                    { $script:result = Test-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -ValuesToCheck $valuesToCheck `
                            -Verbose } | Should -Not -Throw
                }

                It 'Should return $false' {
                    $script:result | Should -Be $false
                }
            }

            Context 'The current parameters do not match desired parameters because an array has a different type' {
                $currentValues = @{
                    parameterString = 'a string'
                    parameterBool = $true
                    parameterInt = 99
                    parameterArray = @( 'a', 'b', 'c' )
                }

                $desiredValues = [PSObject] @{
                    parameterString = 'a string'
                    parameterBool = $true
                    parameterInt = 1
                    parameterArray = @( 'a', 1, 'c' )
                }

                $valuesToCheck = @(
                    'parameterString'
                    'parameterBool'
                    'ParameterInt'
                    'ParameterArray'
                )

                It 'Should not throw exception' {
                    { $script:result = Test-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -ValuesToCheck $valuesToCheck `
                            -Verbose } | Should -Not -Throw
                }

                It 'Should return $false' {
                    $script:result | Should -Be $false
                }
            }

            Context 'The current parameters do not match desired parameters because a parameter has a different type' {
                $currentValues = @{
                    parameterString = 'a string'
                    parameterBool = $true
                    parameterInt = 99
                    parameterArray = @( 'a', 'b', 'c' )
                }

                $desiredValues = [PSObject] @{
                    parameterString = $false
                    parameterBool = $true
                    parameterInt = 1
                    parameterArray = @( 'a', 'b', 'c' )
                }

                $valuesToCheck = @(
                    'parameterString'
                    'parameterBool'
                    'ParameterInt'
                    'ParameterArray'
                )

                It 'Should not throw exception' {
                    { $script:result = Test-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -ValuesToCheck $valuesToCheck `
                            -Verbose } | Should -Not -Throw
                }

                It 'Should return $false' {
                    $script:result | Should -Be $false
                }
            }

            Context 'Some of the current parameters do not match desired parameters but only matching parameter is compared' {
                $currentValues = @{
                    parameterString = 'a string'
                    parameterBool = $true
                    parameterInt = 99
                    parameterArray = @( 'a', 'b', 'c' )
                }

                $desiredValues = [PSObject] @{
                    parameterString = 'a string'
                    parameterBool = $false
                    parameterInt = 1
                    parameterArray = @( 'a', 'b' )
                }

                $valuesToCheck = @(
                    'parameterString'
                )

                It 'Should not throw exception' {
                    { $script:result = Test-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -ValuesToCheck $valuesToCheck `
                            -Verbose } | Should -Not -Throw
                }

                It 'Should return $true' {
                    $script:result | Should -Be $true
                }
            }

            Describe 'ComputerManagementDsc.Common\Test-DscObjectHasProperty' {
                # Use the Get-Verb cmdlet to just get a simple object fast
                $testDscObject = (Get-Verb)[0]

                Context 'The object contains the expected property' {
                    It 'Should not throw exception' {
                        { $script:result = Test-DscObjectHasProperty -Object $testDscObject -PropertyName 'Verb' -Verbose } | Should -Not -Throw
                    }

                    It 'Should return $true' {
                        $script:result | Should -Be $true
                    }
                }

                Context 'The object does not contain the expected property' {
                    It 'Should not throw exception' {
                        { $script:result = Test-DscObjectHasProperty -Object $testDscObject -PropertyName 'Missing' -Verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }
            }

            Describe 'ComputerManagementDsc.Common\Get-TimeZoneId' {
                Context '"Get-TimeZone" not available and current timezone is set to "Pacific Standard Time"' {
                    Mock -CommandName Get-Command -ParameterFilter {
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
                        Assert-MockCalled -CommandName Get-Command -ParameterFilter {
                            $Name -eq 'Get-TimeZone'
                        } -Exactly -Times 1

                        Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1
                    }
                }

                Context '"Get-TimeZone" not available and current timezone is set to "Russia TZ 11 Standard Time"' {
                    Mock -CommandName Get-Command -ParameterFilter {
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
                        Assert-MockCalled -CommandName Get-Command -ParameterFilter {
                            $Name -eq 'Get-TimeZone'
                        } -Exactly -Times 1

                        Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1
                    }
                }

                Context '"Get-TimeZone" available and current timezone is set to "Pacific Standard Time"' {
                    function Get-TimeZone
                    {
                    }

                    Mock -CommandName Get-Command -ParameterFilter {
                        $Name -eq 'Get-TimeZone'
                    } -MockWith {
                        'Get-TimeZone'
                    }

                    Mock -CommandName Get-TimeZone -MockWith {
                        @{
                            StandardName = 'Pacific Standard Time'
                        }
                    }

                    It 'Returns "Pacific Standard Time"' {
                        Get-TimeZoneId | Should -Be 'Pacific Standard Time'
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Get-Command -ParameterFilter {
                            $Name -eq 'Get-TimeZone'
                        } -Exactly -Times 1

                        Assert-MockCalled -CommandName Get-TimeZone -Exactly -Times 1
                    }
                }
            }

            Describe 'ComputerManagementDsc.Common\Test-TimezoneId' {
                Mock Get-TimeZoneId -MockWith {
                    'Russia Time Zone 11'
                }

                Context 'current timezone matches desired timezone' {
                    It 'Should return $true' {
                        Test-TimezoneId -TimeZoneId 'Russia Time Zone 11' | Should -Be $true
                    }
                }

                Context 'current timezone does not match desired timezone' {
                    It 'Should return $false' {
                        Test-TimezoneId -TimeZoneId 'GMT Standard Time' | Should -Be $false
                    }
                }
            }

            Describe 'ComputerManagementDsc.Common\Set-TimeZoneId' {
                Context '"Set-TimeZone" and "Add-Type" is not available, Tzutil Returns 0' {
                    Mock -CommandName Get-Command -ParameterFilter {
                        $Name -eq 'Add-Type'
                    }

                    Mock -CommandName Get-Command -ParameterFilter {
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
                        Assert-MockCalled -CommandName Get-Command -ParameterFilter {
                            $Name -eq 'Add-Type'
                        } -Exactly -Times 1

                        Assert-MockCalled -CommandName Get-Command -ParameterFilter {
                            $Name -eq 'Set-TimeZone'
                        } -Exactly -Times 1

                        Assert-MockCalled -CommandName TzUtil.exe -Exactly -Times 1
                        Assert-MockCalled -CommandName Add-Type -Exactly -Times 0
                    }
                }

                Context '"Set-TimeZone" is not available but "Add-Type" is available' {
                    Mock -CommandName Get-Command -ParameterFilter {
                        $Name -eq 'Add-Type'
                    } -MockWith {
                        'Add-Type'
                    }

                    Mock -CommandName Get-Command -ParameterFilter {
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
                        Assert-MockCalled -CommandName Get-Command -ParameterFilter {
                            $Name -eq 'Add-Type'
                        } -Exactly -Times 1

                        Assert-MockCalled -CommandName Get-Command -ParameterFilter {
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

                    Mock -CommandName Get-Command -ParameterFilter {
                        $Name -eq 'Add-Type'
                    }

                    Mock -CommandName Get-Command -ParameterFilter {
                        $Name -eq 'Set-TimeZone'
                    } -MockWith {
                        'Set-TimeZone'
                    }

                    Mock -CommandName Set-TimeZone

                    It 'Should not throw an exception' {
                        { Set-TimeZoneId -TimezoneId 'Eastern Standard Time' } | Should -Not -Throw
                    }

                    It 'Should call expected mocks' {
                        Assert-MockCalled -CommandName Get-Command -ParameterFilter {
                            $Name -eq 'Add-Type'
                        } -Exactly -Times 0

                        Assert-MockCalled -CommandName Get-Command -ParameterFilter {
                            $Name -eq 'Set-TimeZone'
                        } -Exactly -Times 1

                        Assert-MockCalled -CommandName Set-TimeZone -Exactly -Times 1
                    }
                }
            }
        }
    }
}
finally
{
    #region FOOTER
    #endregion
}
