<#
    .SYNOPSIS
        Unit test for DSC_WindowsEventLog DSC resource.

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
    $script:dscResourceName = 'DSC_WindowsEventLog'

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

Describe 'DSC_WindowsEventLog\Get-TargetResource' -Tag 'Get' {
    Context 'When getting a request for a non-existent target resource' {
        It 'Should throw when an event log does not exist' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0


                $errorMessage = Get-InvalidOperationRecord -Message (
                    $script:localizedData.GetWindowsEventLogFailure -f 'UndefinedLog'
                )

                { Get-TargetResource -LogName 'UndefinedLog' } | Should -Throw -ExpectedMessage ($errorMessage.Exception.Message + '*')
            }
        }
    }

    Context 'When getting the default target resource' {
        BeforeAll {
            Mock -CommandName Get-EventLog -MockWith {
                return @{
                    Log                  = 'Application'
                    MinimumRetentionDays = 0
                }
            }
            Mock -CommandName Get-WinEvent -MockWith {
                return New-Object `
                    -TypeName System.Diagnostics.Eventing.Reader.EventLogConfiguration `
                    -ArgumentList 'Application' `
                    -Property @{
                    IsEnabled          = $true
                    LogFilePath        = '%SystemRoot%\System32\Winevt\Logs\Application.evtx'
                    LogMode            = 'Circular'
                    MaximumSizeInBytes = [System.Int64] 525074432
                    SecurityDescriptor = 'O:BAG:SYD:(A;;0x2;;;S-1-15-2-1)' + `
                        '(A;;0xf0007;;;SY)(A;;0x7;;;BA)' + `
                        '(A;;0x7;;;SO)(A;;0x3;;;IU)' + `
                        '(A;;0x3;;;SU)(A;;0x3;;;S-1-5-3)' + `
                        '(A;;0x3;;;S-1-5-33)(A;;0x1;;;S-1-5-32-573)'
                }
            }
        }

        It 'Should get the current event log configuration state' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $eventLogConfiguration = Get-TargetResource -LogName 'Application'

                $eventLogConfiguration | Should -BeOfType Hashtable
                $eventLogConfiguration.LogName | Should -Be 'Application'
                $eventLogConfiguration.MaximumSizeInBytes | Should -BeOfType Int64
                $eventLogConfiguration.MaximumSizeInBytes | Should -BeGreaterOrEqual 64KB
                $eventLogConfiguration.MaximumSizeInBytes | Should -BeLessOrEqual 4GB
                $eventLogConfiguration.IsEnabled | Should -Be $true
                $eventLogConfiguration.LogMode | Should -BeIn @('AutoBackup', 'Circular', 'Retain')
                $eventLogConfiguration.LogRetentionDays | Should -BeIn (0..365)
                $eventLogConfiguration.LogFilePath | Should -Not -BeNullOrEmpty
                $eventLogConfiguration.SecurityDescriptor | Should -Not -BeNullOrEmpty
                $eventLogConfiguration.RestrictGuestAccess | Should -Be $true
            }
        }
    }
}

Describe 'DSC_WindowsEventLog\Test-TargetResource' -Tag 'Test' {
    Context 'When testing a request with values that are out of bounds or invalid' {
        BeforeAll {
            Mock -CommandName Get-EventLog -MockWith {
                return @{
                    Log                  = 'Application'
                    MinimumRetentionDays = 0
                }
            }
            Mock -CommandName Get-WinEvent -MockWith {
                return New-Object `
                    -TypeName System.Diagnostics.Eventing.Reader.EventLogConfiguration `
                    -ArgumentList 'Application' `
                    -Property @{
                    IsEnabled          = $true
                    LogFilePath        = '%SystemRoot%\System32\Winevt\Logs\Application.evtx'
                    LogMode            = 'Circular'
                    MaximumSizeInBytes = [System.Int64] 525074432
                    SecurityDescriptor = 'O:BAG:SYD:(A;;0x2;;;S-1-15-2-1)' + `
                        '(A;;0xf0007;;;SY)(A;;0x7;;;BA)' + `
                        '(A;;0x7;;;SO)(A;;0x3;;;IU)' + `
                        '(A;;0x3;;;SU)(A;;0x3;;;S-1-5-3)' + `
                        '(A;;0x3;;;S-1-5-33)(A;;0x1;;;S-1-5-32-573)'
                }
            }
        }

        It 'Should throw when MaximumSizeInBytes is less than 64KB' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Test-TargetResource -LogName 'Application' -MaximumSizeInBytes 0 } | Should -Throw
            }
        }

        It 'Should throw when MaximumSizeInBytes is greater than 4GB' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Test-TargetResource -LogName 'Application' -MaximumSizeInBytes 5GB } | Should -Throw
            }
        }

        It 'Should throw when LogMode is not a valid keyword' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Test-TargetResource -LogName 'Application' -LogMode Rectangular } | Should -Throw
            }
        }

        It 'Should throw when LogRentionDays is less than 0' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Test-TargetResource -LogName 'Application' -LogRetentionDays -1 } | Should -Throw
            }
        }

        It 'Should throw when LogRentionDays is greater than 365' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Test-TargetResource -LogName 'Application' -LogRetentionDays 366 } | Should -Throw
            }
        }
    }

    Context 'When the event log is in the desired state' {
        BeforeAll {
            Mock -CommandName Get-WindowsEventLog -MockWith {
                return New-Object `
                    -TypeName System.Diagnostics.Eventing.Reader.EventLogConfiguration `
                    -ArgumentList 'Application' `
                    -Property @{
                    IsEnabled          = $true
                    LogFilePath        = '%SystemRoot%\System32\Winevt\Logs\Application.evtx'
                    LogMode            = 'Circular'
                    MaximumSizeInBytes = [System.Int64] 525074432
                    SecurityDescriptor = 'O:BAG:SYD:(A;;0x2;;;S-1-15-2-1)' + `
                        '(A;;0xf0007;;;SY)(A;;0x7;;;BA)' + `
                        '(A;;0x7;;;SO)(A;;0x3;;;IU)' + `
                        '(A;;0x3;;;SU)(A;;0x3;;;S-1-5-3)' + `
                        '(A;;0x3;;;S-1-5-33)(A;;0x1;;;S-1-5-32-573)'
                }
            }
            Mock -CommandName Get-WindowsEventLogRestrictGuestAccess -MockWith { return $true }
            Mock -CommandName Get-WindowsEventLogRetentionDays -MockWith { return 0 }
            Mock -CommandName Get-WindowsEventLogRegisteredSource -MockWith { return 'PesterTest' }
            Mock -CommandName Get-WindowsEventLogRegisteredSourceFile -MockWith { return 'C:\WINDOWS\System32\PesterTest.dll' }
        }

        It 'Should return true when all resources are in the desired state' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetParameters = @{
                    IsEnabled             = $true
                    LogFilePath           = '%SystemRoot%\System32\Winevt\Logs\Application.evtx'
                    LogMode               = 'Circular'
                    LogName               = 'Application'
                    LogRetentionDays      = 0
                    MaximumSizeInBytes    = [System.Int64] 525074432
                    RestrictGuestAccess   = $true
                    SecurityDescriptor    = 'O:BAG:SYD:(A;;0x2;;;S-1-15-2-1)' + `
                        '(A;;0xf0007;;;SY)(A;;0x7;;;BA)' + `
                        '(A;;0x7;;;SO)(A;;0x3;;;IU)' + `
                        '(A;;0x3;;;SU)(A;;0x3;;;S-1-5-3)' + `
                        '(A;;0x3;;;S-1-5-33)(A;;0x1;;;S-1-5-32-573)'
                    RegisteredSource      = 'PesterTest'
                    CategoryResourceFile  = 'C:\WINDOWS\System32\PesterTest.dll'
                    MessageResourceFile   = 'C:\WINDOWS\System32\PesterTest.dll'
                    ParameterResourceFile = 'C:\WINDOWS\System32\PesterTest.dll'
                }

                $Result = Test-TargetResource @testTargetParameters
                $Result | Should -BeTrue
            }
        }
    }

    Context 'When the event log is not in the desired state' {
        BeforeDiscovery {
            $testCasesGeneric = @(
                @{
                    EventLogSetting = 'IsEnabled'
                    NewValue        = $false
                }
                @{
                    EventLogSetting = 'LogFilePath'
                    NewValue        = '%SystemRoot%\System32\Winevt\Logs\NewApplication.evtx'
                }
                @{
                    EventLogSetting = 'LogMode'
                    NewValue        = 'AutoBackup'
                }
                @{
                    EventLogSetting = 'LogRetentionDays'
                    NewValue        = 30
                }
                @{
                    EventLogSetting = 'MaximumSizeInBytes'
                    NewValue        = 1MB
                }
                @{
                    EventLogSetting = 'SecurityDescriptor'
                    NewValue        = 'O:BAG:SYD:(A;;0x2;;;S-1-15-2-1)(A;;0xf0007;;;SY)(A;;0x7;;;BA)'
                }
                @{
                    EventLogSetting = 'RegisteredSource'
                    NewValue        = 'NewPesterTest'
                }
                @{
                    EventLogSetting = 'RestrictGuestAccess'
                    NewValue        = $false
                }
            )

            $testCasesEventSource = @(
                @{
                    EventLogSetting = 'CategoryResourceFile'
                    NewValue        = 'C:\WINDOWS\System32\NewPesterTest.dll'
                }
                @{
                    EventLogSetting = 'MessageResourceFile'
                    NewValue        = 'C:\WINDOWS\System32\NewPesterTest.dll'
                }
                @{
                    EventLogSetting = 'ParameterResourceFile'
                    NewValue        = 'C:\WINDOWS\System32\NewPesterTest.dll'
                }
            )
        }

        BeforeAll {
            Mock -CommandName Get-WindowsEventLog -MockWith {
                return New-Object `
                    -TypeName System.Diagnostics.Eventing.Reader.EventLogConfiguration `
                    -ArgumentList 'Application' `
                    -Property @{
                    IsEnabled          = $true
                    LogFilePath        = '%SystemRoot%\System32\Winevt\Logs\Application.evtx'
                    LogMode            = 'Circular'
                    MaximumSizeInBytes = [System.Int64] 525074432
                    SecurityDescriptor = 'O:BAG:SYD:(A;;0x2;;;S-1-15-2-1)' + `
                        '(A;;0xf0007;;;SY)(A;;0x7;;;BA)' + `
                        '(A;;0x7;;;SO)(A;;0x3;;;IU)' + `
                        '(A;;0x3;;;SU)(A;;0x3;;;S-1-5-3)' + `
                        '(A;;0x3;;;S-1-5-33)(A;;0x1;;;S-1-5-32-573)'
                }
            }
            Mock -CommandName Get-WindowsEventLogRestrictGuestAccess -MockWith { return $true }
            Mock -CommandName Get-WindowsEventLogRetentionDays -MockWith { return 0 }
            Mock -CommandName Get-WindowsEventLogRegisteredSource -MockWith { return 'PesterTest' }
            Mock -CommandName Get-WindowsEventLogRegisteredSourceFile -MockWith { return 'C:\WINDOWS\System32\PesterTest.dll' }
        }

        It 'Should return false when <EventLogSetting> setting changes are required' -TestCases $testCasesGeneric {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $CaseParams = @{
                    LogName          = 'Application'
                    $EventLogSetting = $NewValue
                }

                $Result = Test-TargetResource @CaseParams
                $Result | Should -BeFalse
            }
        }

        It 'Should return false when <EventLogSetting> setting changes are required' -TestCases $testCasesEventSource {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $CaseParams = @{
                    LogName          = 'Application'
                    RegisteredSource = 'PesterTest'
                    $EventLogSetting = $NewValue
                }

                $Result = Test-TargetResource @CaseParams
                $Result | Should -BeFalse
            }
        }
    }
}

Describe 'DSC_WindowsEventLog\Set-TargetResource' -Tag 'Set' {
    Context 'When configuration is required' {
        BeforeAll {
            Mock -CommandName Get-WindowsEventLog -MockWith {
                return New-Object `
                    -TypeName System.Diagnostics.Eventing.Reader.EventLogConfiguration `
                    -ArgumentList 'Application' `
                    -Property @{
                    IsEnabled          = $true
                    LogFilePath        = '%SystemRoot%\System32\Winevt\Logs\Application.evtx'
                    LogMode            = 'Circular'
                    MaximumSizeInBytes = [System.Int64] 525074432
                    SecurityDescriptor = 'O:BAG:SYD:(A;;0x2;;;S-1-15-2-1)' + `
                        '(A;;0xf0007;;;SY)(A;;0x7;;;BA)' + `
                        '(A;;0x7;;;SO)(A;;0x3;;;IU)' + `
                        '(A;;0x3;;;SU)(A;;0x3;;;S-1-5-3)' + `
                        '(A;;0x3;;;S-1-5-33)(A;;0x1;;;S-1-5-32-573)'
                }
            }
            Mock -CommandName Get-WindowsEventLogRestrictGuestAccess -MockWith { return $true }
            Mock -CommandName Get-WindowsEventLogRegisteredSource -MockWith { return 'PesterTest' }
            Mock -CommandName Get-WindowsEventLogRegisteredSourceFile -MockWith { return 'C:\WINDOWS\System32\PesterTest.dll' }
        }

        Context 'When the EventLog settings need to be changed' {
            BeforeDiscovery {
                $setCasesGeneric = @(
                    @{
                        EventLogSetting = 'IsEnabled'
                        NewValue        = $false
                    }
                    @{
                        EventLogSetting = 'LogFilePath'
                        NewValue        = '%SystemRoot%\System32\Winevt\Logs\NewApplication.evtx'
                    }
                    @{
                        EventLogSetting = 'LogMode'
                        NewValue        = 'AutoBackup'
                    }
                    @{
                        EventLogSetting = 'MaximumSizeInBytes'
                        NewValue        = 1MB
                    }
                    @{
                        EventLogSetting = 'SecurityDescriptor'
                        NewValue        = 'O:BAG:SYD:(A;;0x2;;;S-1-15-2-1)(A;;0xf0007;;;SY)(A;;0x7;;;BA)'
                    }
                )
            }

            BeforeAll {
                Mock -CommandName Save-WindowsEventLog
            }

            It 'Should set <EventLogSetting> to the correct value' -TestCases $setCasesGeneric {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $CaseParams = @{
                        LogName          = 'Application'
                        $EventLogSetting = $NewValue
                    }

                    Set-TargetResource @CaseParams
                }

                Should -Invoke -CommandName Save-WindowsEventLog -Exactly -Times 1 -Scope It
            }
        }

        Context 'When RestrictGuestAccess needs to be changed' {
            BeforeAll {
                Mock -CommandName Set-WindowsEventLogRestrictGuestAccess
                Mock -CommandName Save-WindowsEventLog

            }

            It 'Should set the correct value' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    Set-TargetResource -LogName 'Application' -RestrictGuestAccess $false
                }

                Should -Invoke -CommandName Set-WindowsEventLogRestrictGuestAccess -Exactly -Times 1 -Scope It
            }
        }

        Context 'When LogRetentionDays needs to be changed' {
            BeforeAll {
                Mock -CommandName Set-WindowsEventLogRetentionDays
                Mock -CommandName Save-WindowsEventLog
            }

            It 'Should be set the correct value' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    Set-TargetResource -LogName 'Application' -LogRetentionDays 30 -LogMode AutoBackup
                }

                Should -Invoke -CommandName Set-WindowsEventLogRetentionDays -Exactly -Times 1 -Scope It
            }
        }

        Context 'When RegisteredSource needs to be changed' {
            BeforeAll {
                Mock -CommandName Register-WindowsEventLogSource
            }

            It 'Should be set the correct value' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    Set-TargetResource -LogName 'Application' -RegisteredSource 'NewPesterTest'
                }

                Should -Invoke -CommandName Register-WindowsEventLogSource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When ResourceFiles need to be changed' {
            BeforeDiscovery {
                $testCases = @(
                    @{
                        Name = 'CategoryResourceFile'
                    }
                    @{
                        Name = 'MessageResourceFile'
                    }
                    @{
                        Name = 'ParameterResourceFile'
                    }
                )
            }
            BeforeAll {
                Mock -CommandName Register-WindowsEventLogSource
            }

            It 'Should set the <Name>' -ForEach $testCases {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetParameters = @{
                        LogName          = 'Application'
                        RegisteredSource = 'PesterTest'
                        $Name            = 'NewPesterTest.dll'
                    }

                    Set-TargetResource @setTargetParameters
                }

                Should -Invoke -CommandName Register-WindowsEventLogSource -Times 1
            }
        }

        Context 'When RestrictGuestAccess and user-provided DACL needs to be changed' {
            BeforeAll {
                Mock -CommandName Get-WindowsEventLogRestrictGuestAccess -MockWith {
                    return $true
                }
                Mock -CommandName Save-WindowsEventLog
                Mock -CommandName Set-WindowsEventLogRestrictGuestAccess
            }

            It 'Should set correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $setTargetParameters = @{
                        LogName             = 'Application'
                        SecurityDescriptor  = 'O:BAG:SYD:(A;;0x7;;;BA)'
                        RestrictGuestAccess = $false
                    }

                    Set-TargetResource @setTargetParameters
                }

                Should -Invoke -CommandName Save-WindowsEventLog -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Set-WindowsEventLogRestrictGuestAccess -Exactly -Times 1 -Scope It
            }
        }

        Context 'When RestrictGuestAccess and system-level DACL needs to be changed' {
            BeforeAll {
                Mock -CommandName Get-WindowsEventLogRestrictGuestAccess -MockWith {
                    return $true
                }
                Mock -CommandName Save-WindowsEventLog
                Mock -CommandName Set-WindowsEventLogRestrictGuestAccess

            }
            It 'Should set correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    Set-TargetResource -LogName 'Application' -RestrictGuestAccess $false
                }

                Should -Invoke -CommandName Save-WindowsEventLog -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Set-WindowsEventLogRestrictGuestAccess -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'DSC_WindowsEventLog\Get-WindowsEventLogRestrictGuestAccess' -Tag 'Private' {
    Context 'When testing the helper function' {
        BeforeAll {
            Mock -CommandName Get-ItemProperty -MockWith { throw }
        }
        It 'Should not throw under any circumstances' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Get-WindowsEventLogRestrictGuestAccess -LogName 'UndefinedLog' | Should -BeFalse
            }
        }
    }

    Context 'When RestrictGuestAccess is 1' {
        BeforeAll {
            Mock -CommandName Get-ItemProperty -MockWith {
                return [PSCustomObject]@{
                    RestrictGuestAccess = 1
                }
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                    ( Get-WindowsEventLogRestrictGuestAccess -LogName 'Application' ) | Should -BeTrue
            }
        }
    }

    Context 'When RestrictGuestAccess is 0' {
        BeforeAll {
            Mock -CommandName Get-ItemProperty -MockWith {
                return [PSCustomObject]@{
                    RestrictGuestAccess = 0
                }
            }
        }
        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                    ( Get-WindowsEventLogRestrictGuestAccess -LogName 'Application' ) | Should -BeFalse
            }
        }
    }
}

Describe 'DSC_WindowsEventLog\Get-WindowsEventLogRetentionDays' -Tag 'Private' {
    Context 'When the event log does not exist' {
        BeforeAll {
            Mock -CommandName Get-EventLog -MockWith { @{ MinimumRetentionDays = $null } }
        }
        It 'Should throw when an event log does not exist' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidArgumentRecord -Message (
                    $script:localizedData.GetWindowsEventLogRetentionDaysFailure -f 'UndefinedLog'
                ) -ArgumentName 'LogName'

                { Get-WindowsEventLogRetentionDays -LogName 'UndefinedLog' } | Should -Throw -ExpectedMessage $errorRecord
            }

            Should -Invoke -CommandName Get-EventLog -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the event log does exist' {
        BeforeAll {
            Mock -CommandName Get-EventLog -MockWith {
                @{
                    Log                  = 'Application'
                    MinimumRetentionDays = 20
                }
            }
        }
        It 'Should return the eventlog retention days value' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-WindowsEventLogRetentionDays -LogName 'Application'
                $result | Should -BeExactly 20
                $result | Should -BeOfType Int32
            }

            Should -Invoke -CommandName Get-EventLog -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'DSC_WindowsEventLog\Register-WindowsEventLogSource' -Tag 'Private' {
    Context 'When testing a request with values that are out of bounds or invalid' {
        BeforeDiscovery {
            $testCases = @(
                @{
                    Name = 'CategoryResourceFile'
                }
                @{
                    Name = 'MessageResourceFile'
                }
                @{
                    Name = 'ParameterResourceFile'
                }
            )
        }

        It 'Should throw when <Name> is an invalid path' -ForEach $testCases {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidArgumentRecord -Message (
                    $script:localizedData.RegisterWindowsEventLogSourceInvalidPath -f 'PesterTest', 'foo>bar'
                ) -ArgumentName $Name

                $mockParameters = @{
                    LogName    = 'Application'
                    SourceName = 'PesterTest'
                    $Name      = 'foo>bar'
                }

                { Register-WindowsEventLogSource @mockParameters } | Should -Throw -ExpectedMessage $errorRecord
            }
        }

        Context 'When the New-EventLog cmdlet encounters an error' {
            BeforeAll {
                Mock -CommandName New-EventLog -MockWith { throw 'New-EventLog Error' }
                Mock -CommandName Get-WindowsEventLogRegisteredSource -MockWith { '' }
            }

            It 'Should throw an exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $errorRecord = Get-InvalidOperationRecord -Message (
                        $script:localizedData.RegisterWindowsEventLogSourceFailure -f 'Application', 'PesterTest'
                    )

                    $mockParameters = @{
                        LogName    = 'Application'
                        SourceName = 'PesterTest'
                    }

                    { Register-WindowsEventLogSource @mockParameters } | Should -Throw -ExpectedMessage ($errorRecord.Exception.Message + '*')
                }

                Should -Invoke -CommandName New-EventLog -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Get-WindowsEventLogRegisteredSource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the Remove-EventLog cmdlet encounters an error' {
            BeforeAll {
                Mock -CommandName Remove-EventLog -MockWith { throw }
                Mock -CommandName Get-WindowsEventLogRegisteredSource -MockWith { 'anything' }
            }

            It 'Should throw an exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $errorRecord = Get-InvalidOperationRecord -Message (
                        $script:localizedData.RegisterWindowsEventLogSourceFailure -f 'Application', 'PesterTest'
                    )

                    $mockParameters = @{
                        LogName    = 'Application'
                        SourceName = 'PesterTest'
                    }

                    { Register-WindowsEventLogSource @mockParameters } | Should -Throw -ExpectedMessage ($errorRecord.Exception.Message + '*')
                }

                Should -Invoke -CommandName Remove-EventLog -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Get-WindowsEventLogRegisteredSource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When Remove-EventLog succeeds and New-EventLog cmdlet encounters an error' {
            BeforeAll {
                Mock -CommandName New-EventLog  -MockWith { throw }
                Mock -CommandName Remove-EventLog
                Mock -CommandName Get-WindowsEventLogRegisteredSource -MockWith { 'anything' }
            }

            It 'Should throw an exception' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $errorRecord = Get-InvalidOperationRecord -Message (
                        $script:localizedData.RegisterWindowsEventLogSourceFailure -f 'Application', 'PesterTest'
                    )

                    $mockParameters = @{
                        LogName    = 'Application'
                        SourceName = 'PesterTest'
                    }

                    { Register-WindowsEventLogSource @mockParameters } | Should -Throw -ExpectedMessage ($errorRecord.Exception.Message + '*')
                }

                Should -Invoke -CommandName New-EventLog -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Remove-EventLog -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Get-WindowsEventLogRegisteredSource -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'DSC_WindowsEventLog\Set-WindowsEventLogRestrictGuestAccess' -Tag 'Private' {
    Context 'When testing a request with values that are out of bounds or invalid' {
        BeforeAll {
            Mock -CommandName Set-ItemProperty -MockWith { throw 'Set-ItemProperty Error' }
        }
        It 'Should throw when the Set-ItemProperty cmdlet encounters an error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord -Message (
                    $script:localizedData.SetWindowsEventLogRestrictGuestAccessFailure -f 'Application'
                )

                $setWinEventLogParameters = @{
                    LogName             = 'Application'
                    RestrictGuestAccess = $true
                    Sddl                = 'O:BAG:SYD:(A;;0x2;;;S-1-15-2-1)'
                }

                { Set-WindowsEventLogRestrictGuestAccess @setWinEventLogParameters } |
                    Should -Throw -ExpectedMessage ($errorRecord.Exception.Message + '*')
            }
        }
    }
}

Describe 'DSC_WindowsEventLog\Set-WindowsEventLogRetentionDays' -Tag 'Private' {
    Context 'When testing a request with values that are out of bounds or invalid' {
        It 'Should throw when setting retention days in the wrong log mode' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidArgumentRecord -Message (
                    $script:localizedData.SetWindowsEventLogRetentionDaysWrongMode -f 'Application'
                ) -ArgumentName 'LogMode'

                $setWindowsEventLogRetentionDaysParameters = @{
                    LogName          = 'Application'
                    LogRetentionDays = 30
                    LogMode          = 'Circular'
                }

                { Set-WindowsEventLogRetentionDays @setWindowsEventLogRetentionDaysParameters } |
                    Should -Throw -ExpectedMessage $errorRecord
            }
        }
    }

    Context 'When the Get-EventLog cmdlet encounters an error' {
        BeforeAll {
            Mock -CommandName Get-EventLog -MockWith { throw 'Get-EventLog Error' }
        }

        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord -Message (
                    $script:localizedData.GetWindowsEventLogRetentionDaysFailure -f 'Application'
                )

                $setWindowsEventLogRetentionDaysParameters = @{
                    LogName          = 'Application'
                    LogRetentionDays = 30
                    LogMode          = 'AutoBackup'
                }

                { Set-WindowsEventLogRetentionDays @setWindowsEventLogRetentionDaysParameters } |
                    Should -Throw -ExpectedMessage ($errorRecord.Exception.Message + '*')
            }
        }
    }

    Context 'When the Limit-EventLog cmdlet encounters an error' {
        BeforeAll {
            Mock -CommandName Get-EventLog -MockWith { @{MinimumRetentionDays = 10 } }
            Mock -CommandName Limit-EventLog -MockWith { throw }
        }

        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord -Message (
                    $script:localizedData.SetWindowsEventLogRetentionDaysFailure -f 'Application'
                )

                $setWindowsEventLogRetentionDaysParameters = @{
                    LogName          = 'Application'
                    LogRetentionDays = 30
                    LogMode          = 'AutoBackup'
                }

                { Set-WindowsEventLogRetentionDays @setWindowsEventLogRetentionDaysParameters } |
                    Should -Throw -ExpectedMessage ($errorRecord.Exception.Message + '*')
            }
        }
    }
}
