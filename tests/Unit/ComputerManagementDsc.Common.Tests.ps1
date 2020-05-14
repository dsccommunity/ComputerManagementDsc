#region HEADER
$script:projectPath = "$PSScriptRoot\..\.." | Convert-Path
$script:projectName = (Get-ChildItem -Path "$script:projectPath\*\*.psd1" | Where-Object -FilterScript {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try
            {
                Test-ModuleManifest -Path $_.FullName -ErrorAction Stop
            }
            catch
            {
                $false
            })
    }).BaseName

$script:parentModule = Get-Module -Name $script:projectName -ListAvailable | Select-Object -First 1
$script:subModulesFolder = Join-Path -Path $script:parentModule.ModuleBase -ChildPath 'Modules'
Remove-Module -Name $script:parentModule -Force -ErrorAction 'SilentlyContinue'

$script:subModuleName = (Split-Path -Path $PSCommandPath -Leaf) -replace '\.Tests.ps1'
$script:subModuleFile = Join-Path -Path $script:subModulesFolder -ChildPath "$($script:subModuleName)/$($script:subModuleName).psm1"

Import-Module $script:subModuleFile -Force -ErrorAction Stop
#endregion HEADER

InModuleScope $script:subModuleName {
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
                { Get-PowerPlan -PowerPlan '9c5e7fda-e8bf-4a96-9a85-a7e23a8c635c' } | Should -Not -Throw
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
                { Get-PowerPlan -PowerPlan 'High performance' } | Should -Not -Throw
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
                { Get-PowerPlan -PowerPlan 'Some unavailable plan' } | Should -Not -Throw
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

    Describe 'ComputerManagementDsc.Common\Get-RegistryPropertyValue' -Tag 'GetRegistryPropertyValue' {
        BeforeAll {
            $mockWrongRegistryPath = 'HKLM:\SOFTWARE\AnyPath'
            $mockCorrectRegistryPath = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\RS'
            $mockPropertyName = 'InstanceName'
            $mockPropertyValue = 'AnyValue'
        }

        Context 'When there are no properties in the registry' {
            BeforeAll {
                Mock -CommandName Get-ItemProperty -MockWith {
                    return @{
                        'UnknownProperty' = $mockPropertyValue
                    }
                }
            }

            It 'Should return $null' {
                $result = Get-RegistryPropertyValue -Path $mockWrongRegistryPath -Name $mockPropertyName
                $result | Should -BeNullOrEmpty

                Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the call to Get-ItemProperty throws an error (i.e. when the path does not exist)' {
            BeforeAll {
                Mock -CommandName Get-ItemProperty -MockWith {
                    throw 'mocked error'
                }
            }

            It 'Should not throw an error, but return $null' {
                $result = Get-RegistryPropertyValue -Path $mockWrongRegistryPath -Name $mockPropertyName
                $result | Should -BeNullOrEmpty

                Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 1 -Scope It
            }
        }

        Context 'When there is a property present in the registry' {
            BeforeAll {
                $mockGetItemProperty_InstanceName = {
                    return @{
                        $mockPropertyName = $mockPropertyValue
                    }
                }

                $mockGetItemProperty_InstanceName_ParameterFilter = {
                    $Path -eq $mockCorrectRegistryPath `
                    -and $Name -eq $mockPropertyName
                }

                Mock -CommandName Get-ItemProperty `
                    -MockWith $mockGetItemProperty_InstanceName `
                    -ParameterFilter $mockGetItemProperty_InstanceName_ParameterFilter
            }

            It 'Should return the correct value' {
                $result = Get-RegistryPropertyValue -Path $mockCorrectRegistryPath -Name $mockPropertyName
                $result | Should -Be $mockPropertyValue

                Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 1 -Scope It
            }
        }
    }
}
