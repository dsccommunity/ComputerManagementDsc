<#
    .SYNOPSIS
        Unit test for ComputerManagementDsc Common.
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
    $script:subModuleName = 'ComputerManagementDsc.Common'

    $script:parentModule = Get-Module -Name $script:dscModuleName -ListAvailable | Select-Object -First 1
    $script:subModulesFolder = Join-Path -Path $script:parentModule.ModuleBase -ChildPath 'Modules'

    $script:subModulePath = Join-Path -Path $script:subModulesFolder -ChildPath $script:subModuleName

    Import-Module -Name $script:subModulePath -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:subModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:subModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:subModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:subModuleName -All | Remove-Module -Force
}

Describe 'ComputerManagementDsc.Common\Get-TimeZoneId' {
    Context 'When "Get-TimeZone" not available and current timezone is set to "Pacific Standard Time"' {
        BeforeAll {
            Mock -CommandName Get-Command -ParameterFilter {
                $Name -eq 'Get-TimeZone'
            }

            Mock -CommandName Get-CimInstance -MockWith {
                @{
                    StandardName = 'Pacific Standard Time'
                }
            }
        }

        It 'Should return "Pacific Standard Time"' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Get-TimeZoneId | Should -Be 'Pacific Standard Time'
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-Command -ParameterFilter {
                $Name -eq 'Get-TimeZone'
            } -Exactly -Times 1 -Scope Context

            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When "Get-TimeZone" not available and current timezone is set to "Russia TZ 11 Standard Time"' {
        BeforeAll {
            Mock -CommandName Get-Command -ParameterFilter {
                $Name -eq 'Get-TimeZone'
            }

            Mock -CommandName Get-CimInstance -MockWith {
                @{
                    StandardName = 'Russia TZ 11 Standard Time'
                }
            }
        }

        It 'Should return "Russia Time Zone 11"' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Get-TimeZoneId | Should -Be 'Russia Time Zone 11'
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-Command -ParameterFilter {
                $Name -eq 'Get-TimeZone'
            } -Exactly -Times 1 -Scope Context

            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When "Get-TimeZone" available and current timezone is set to "Pacific Standard Time"' {
        BeforeAll {
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
        }

        It 'Should return "Pacific Standard Time"' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Get-TimeZoneId | Should -Be 'Pacific Standard Time'
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-Command -ParameterFilter {
                $Name -eq 'Get-TimeZone'
            } -Exactly -Times 1 -Scope Context

            Should -Invoke -CommandName Get-TimeZone -Exactly -Times 1 -Scope Context
        }
    }
}

Describe 'ComputerManagementDsc.Common\Test-TimezoneId' {
    BeforeAll {
        Mock -CommandName Get-TimeZoneId -MockWith {
            'Russia Time Zone 11'
        }
    }

    Context 'When the current timezone matches desired timezone' {
        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TimezoneId -TimeZoneId 'Russia Time Zone 11' | Should -BeTrue
            }
        }
    }

    Context 'When the current timezone does not match desired timezone' {
        It 'Should return $false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Test-TimezoneId -TimeZoneId 'GMT Standard Time' | Should -BeFalse
            }
        }
    }
}

Describe 'ComputerManagementDsc.Common\Set-TimeZoneId' {
    Context 'When "Set-TimeZone" and "Add-Type" is not available, Tzutil Returns 0' {
        BeforeAll {
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
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TimeZoneId -TimezoneId 'Eastern Standard Time' } | Should -Not -Throw
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-Command -ParameterFilter {
                $Name -eq 'Add-Type'
            } -Exactly -Times 1 -Scope Context

            Should -Invoke -CommandName Get-Command -ParameterFilter {
                $Name -eq 'Set-TimeZone'
            } -Exactly -Times 1 -Scope Context

            Should -Invoke -CommandName TzUtil.exe -Exactly -Times 1 -Scope Context
            Should -Invoke -CommandName Add-Type -Exactly -Times 0 -Scope Context
        }
    }

    Context 'When "Set-TimeZone" is not available but "Add-Type" is available' {
        BeforeAll {
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
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TimeZoneId -TimezoneId 'Eastern Standard Time' } | Should -Not -Throw
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-Command -ParameterFilter {
                $Name -eq 'Add-Type'
            } -Exactly -Times 1 -Scope Context

            Should -Invoke -CommandName Get-Command -ParameterFilter {
                $Name -eq 'Set-TimeZone'
            } -Exactly -Times 1 -Scope Context

            Should -Invoke -CommandName TzUtil.exe -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Add-Type -Exactly -Times 0 -Scope Context
            Should -Invoke -CommandName Set-TimeZoneUsingDotNet -Exactly -Times 1 -Scope Context
        }
    }

    Context 'When "Set-TimeZone" is available' {
        BeforeAll {
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
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TimeZoneId -TimezoneId 'Eastern Standard Time' } | Should -Not -Throw
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-Command -ParameterFilter {
                $Name -eq 'Add-Type'
            } -Exactly -Times 0 -Scope Context

            Should -Invoke -CommandName Get-Command -ParameterFilter {
                $Name -eq 'Set-TimeZone'
            } -Exactly -Times 1 -Scope Context

            Should -Invoke -CommandName Set-TimeZone -Exactly -Times 1 -Scope Context
        }
    }
}

Describe 'ComputerManagementDsc.Common\Get-PowerPlan' {
    BeforeAll {
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
    }

    Context 'When only one power plan is available and "PowerPlan" parameter is not specified' {
        BeforeAll {
            Mock -CommandName Get-PowerPlanUsingPInvoke -MockWith {
                return $mockBalancedPowerPlan
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Get-PowerPlan } | Should -Not -Throw
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-PowerPlanUsingPInvoke -Exactly -Times 1 -Scope Context
        }

        It 'Should return exactly one hashtable' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-PowerPlan
                $result | Should -BeOfType [System.Collections.Hashtable]
                $result | Should -HaveCount 1
            }
        }

    }

    Context 'When only one power plan is available and "PowerPlan" parameter is specified as Guid of the available plan' {
        BeforeAll {
            Mock -CommandName Get-PowerPlanUsingPInvoke -MockWith {
                return $mockBalancedPowerPlan
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Get-PowerPlan -PowerPlan '381b4222-f694-41f0-9685-ff5bb260df2e' } | Should -Not -Throw
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-PowerPlanUsingPInvoke -Exactly -Times 1 -Scope Context
        }

        It 'Should return a hashtable with the name and guid fo the power plan' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-PowerPlan -PowerPlan '381b4222-f694-41f0-9685-ff5bb260df2e'
                $result | Should -BeOfType [System.Collections.Hashtable]
                $result | Should -HaveCount 1
                $result.FriendlyName | Should -Be 'Balanced'
                $result.guid | Should -Be '381b4222-f694-41f0-9685-ff5bb260df2e'
            }
        }
    }

    Context 'When only one power plan is available and "PowerPlan" parameter is specified as Guid of a not available plan' {
        BeforeAll {
            Mock -CommandName Get-PowerPlanUsingPInvoke -MockWith {
                return $mockBalancedPowerPlan
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Get-PowerPlan -PowerPlan '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c' } | Should -Not -Throw
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-PowerPlanUsingPInvoke -Exactly -Times 1 -Scope Context
        }

        It 'Should return nothing' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-PowerPlan -PowerPlan '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
                $result | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When only one power plan is available and "PowerPlan" parameter is specified as name of the available plan' {
        BeforeAll {
            Mock -CommandName Get-PowerPlanUsingPInvoke -MockWith {
                return $mockBalancedPowerPlan
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Get-PowerPlan -PowerPlan 'Balanced' } | Should -Not -Throw
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-PowerPlanUsingPInvoke -Exactly -Times 1 -Scope Context
        }

        It 'Should return a hashtable with the name and guid fo the power plan' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-PowerPlan -PowerPlan 'Balanced'
                $result | Should -BeOfType [System.Collections.Hashtable]
                $result | Should -HaveCount 1
                $result.FriendlyName | Should -Be 'Balanced'
                $result.guid | Should -Be '381b4222-f694-41f0-9685-ff5bb260df2e'
            }
        }
    }

    Context 'When only one power plan is available and "PowerPlan" parameter is specified as name of a not available plan' {
        BeforeAll {
            Mock -CommandName Get-PowerPlanUsingPInvoke -MockWith {
                return $mockBalancedPowerPlan
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Get-PowerPlan -PowerPlan 'High performance' } | Should -Not -Throw
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-PowerPlanUsingPInvoke -Exactly -Times 1 -Scope Context
        }

        It 'Should return nothing' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-PowerPlan -PowerPlan 'High performance'
                $result | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When multiple power plans are available and "PowerPlan" parameter is not specified' {
        BeforeAll {
            Mock -CommandName Get-PowerPlanUsingPInvoke -MockWith {
                return @(
                    $mockBalancedPowerPlan
                    $mockHighPerformancePowerPlan
                    $mockPowerSaverPowerPlan
                )
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Get-PowerPlan } | Should -Not -Throw
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-PowerPlanUsingPInvoke -Exactly -Times 1 -Scope Context
        }

        It 'Should return an array with all available plans' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-PowerPlan
                $result | Should -HaveCount 3
            }
        }
    }

    Context 'When multiple power plans are available and "PowerPlan" parameter is specified as Guid of an available plan' {
        BeforeAll {
            Mock -CommandName Get-PowerPlanUsingPInvoke -MockWith {
                return @(
                    $mockBalancedPowerPlan
                    $mockHighPerformancePowerPlan
                    $mockPowerSaverPowerPlan
                )
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Get-PowerPlan -PowerPlan '381b4222-f694-41f0-9685-ff5bb260df2e' } | Should -Not -Throw
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-PowerPlanUsingPInvoke -Exactly -Times 1 -Scope Context
        }

        It 'Should return a hashtable with the name and guid fo the power plan' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-PowerPlan -PowerPlan '381b4222-f694-41f0-9685-ff5bb260df2e'
                $result | Should -BeOfType [System.Collections.Hashtable]
                $result | Should -HaveCount 1
                $result.FriendlyName | Should -Be 'Balanced'
                $result.guid | Should -Be '381b4222-f694-41f0-9685-ff5bb260df2e'
            }
        }
    }

    Context 'When multiple power plans are available and "PowerPlan" parameter is specified as Guid of a not available plan' {
        BeforeAll {
            Mock -CommandName Get-PowerPlanUsingPInvoke -MockWith {
                return @(
                    $mockBalancedPowerPlan
                    $mockHighPerformancePowerPlan
                    $mockPowerSaverPowerPlan
                )
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Get-PowerPlan -PowerPlan '9c5e7fda-e8bf-4a96-9a85-a7e23a8c635c' } | Should -Not -Throw
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-PowerPlanUsingPInvoke -Exactly -Times 1 -Scope Context
        }

        It 'Should return nothing' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-PowerPlan -PowerPlan '9c5e7fda-e8bf-4a96-9a85-a7e23a8c635c'
                $result | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When multiple power plans are available and "PowerPlan" parameter is specified as name of an available plan' {
        BeforeAll {
            Mock -CommandName Get-PowerPlanUsingPInvoke -MockWith {
                return @(
                    $mockBalancedPowerPlan
                    $mockHighPerformancePowerPlan
                    $mockPowerSaverPowerPlan
                )
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Get-PowerPlan -PowerPlan 'High performance' } | Should -Not -Throw
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-PowerPlanUsingPInvoke -Exactly -Times 1 -Scope Context
        }

        It 'Should return a hashtable with the name and guid fo the power plan' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-PowerPlan -PowerPlan 'High performance'
                $result | Should -BeOfType [System.Collections.Hashtable]
                $result | Should -HaveCount 1
                $result.FriendlyName | Should -Be 'High performance'
                $result.guid | Should -Be '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
            }
        }
    }

    Context 'When multiple power plans are available and "PowerPlan" parameter is specified as name of a not available plan' {
        BeforeAll {
            Mock -CommandName Get-PowerPlanUsingPInvoke -MockWith {
                return @(
                    $mockBalancedPowerPlan
                    $mockHighPerformancePowerPlan
                    $mockPowerSaverPowerPlan
                )
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Get-PowerPlan -PowerPlan 'Some unavailable plan' } | Should -Not -Throw
            }
        }

        It 'Should call expected mocks' {
            Should -Invoke -CommandName Get-PowerPlanUsingPInvoke -Exactly -Times 1 -Scope Context
        }

        It 'Should return nothing' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-PowerPlan -PowerPlan 'Some unavailable plan'
                $result | Should -BeNullOrEmpty
            }
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
            InModuleScope -Parameters @{
                mockWrongRegistryPath = $mockWrongRegistryPath
                mockPropertyName      = $mockPropertyName
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-RegistryPropertyValue -Path $mockWrongRegistryPath -Name $mockPropertyName
                $result | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Get-ItemProperty -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the call to Get-ItemProperty throws an error (i.e. when the path does not exist)' {
        BeforeAll {
            Mock -CommandName Get-ItemProperty -MockWith {
                throw 'mocked error'
            }
        }

        It 'Should not throw an error, but return $null' {
            InModuleScope -Parameters @{
                mockWrongRegistryPath = $mockWrongRegistryPath
                mockPropertyName      = $mockPropertyName
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-RegistryPropertyValue -Path $mockWrongRegistryPath -Name $mockPropertyName
                $result | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Get-ItemProperty -Exactly -Times 1 -Scope It
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
                $Path -eq $mockCorrectRegistryPath -and
                $Name -eq $mockPropertyName
            }

            Mock -CommandName Get-ItemProperty `
                -MockWith $mockGetItemProperty_InstanceName `
                -ParameterFilter $mockGetItemProperty_InstanceName_ParameterFilter
        }

        It 'Should return the correct value' {
            InModuleScope -Parameters @{
                mockCorrectRegistryPath = $mockCorrectRegistryPath
                mockPropertyName        = $mockPropertyName
                mockPropertyValue       = $mockPropertyValue
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-RegistryPropertyValue -Path $mockCorrectRegistryPath -Name $mockPropertyName
                $result | Should -Be $mockPropertyValue
            }

            Should -Invoke -CommandName Get-ItemProperty -Exactly -Times 1 -Scope It
        }
    }
}
