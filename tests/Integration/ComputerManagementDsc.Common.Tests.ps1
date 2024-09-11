<#
    .SYNOPSIS
        Integration test for ComputerManagementDsc Common.
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

Describe 'ComputerManagementDsc.Common\Set-TimeZoneId' {
    BeforeAll {
        # Store the test machine timezone
        $currentTimeZone = & tzutil.exe /g

        # Change the current timezone so that a complete test occurs.
        tzutil.exe /s 'Eastern Standard Time'
    }

    AfterAll {
        # Restore the test machine timezone
        & tzutil.exe /s $CurrentTimeZone
    }

    <#
        The purpose of this test is to ensure the C# .NET code
        that is used to set the time zone if the Set-TimeZone
        cmdlet is not available but the Add-Type cmdlet is available

        The other conditions can be effectively tested with
        the unit tests, but the only way to test the C# .NET code
        is to execute it without mocking. This results in
        a destrutive change which is only allowed within the
        integration tests.
    #>
    Context '''Set-TimeZone'' is not available but ''Add-Type'' is available' {
        BeforeAll {
            Mock -CommandName Get-Command -ParameterFilter {
                $Name -eq 'Add-Type'
            } -MockWith { 'Add-Type' }

            Mock -CommandName Get-Command -ParameterFilter {
                $Name -eq 'Set-TimeZone'
            }

            Mock -CommandName 'TzUtil.exe' -MockWith {
                $Script:LASTEXITCODE = 0
                return 'OK'
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TimeZoneId -TimezoneId 'Eastern Standard Time' } | Should -Not -Throw
            }
        }

        It 'Should have set the time zone to ''Eastern Standard Time''' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Get-TimeZoneId | Should -Be 'Eastern Standard Time'
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
        }
    }
}
