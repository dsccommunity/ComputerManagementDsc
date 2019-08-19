#region HEADER
$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'MSFT_WindowsEventLog'

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

# Begin Testing
try
{
    InModuleScope $script:dscResourceName {
        $script:dscResourceName = 'MSFT_WindowsEventLog'

            Describe "$($script:dscResourceName)\Get-TargetResource" -Tag 'Get' {

                Mock -CommandName Get-WindowsEventLog -MockWith {
                    $properties = @{
                            MaximumSizeInBytes = 4096kb
                            IsEnabled          = $true
                            LogMode            = 'Circular'
                            LogFilePath        = '%SystemRoot%\System32\Winevt\Logs\Application.evtx'
                            SecurityDescriptor = 'TestDescriptor'
                            LogRetentionDays   = '0'
                            LogName            = 'Application'
                    }

                    return (New-Object -TypeName PSObject -Property $properties)
                }

                $results = Get-TargetResource -LogName 'Application' -IsEnabled $true

                It 'Should return an hashtable' {
                    $results.GetType().Name | Should -Be 'Hashtable'
                }

                It 'Should return a Logname Application' {
                    $results.LogName = 'Application'
                }

                It 'Should return a MaximumSizeInBytes of 4096kb' {
                    $results.MaximumSizeInBytes | Should -Be 4096kb
                }

                It 'Should return IsEnabled is true' {
                    $results.IsEnabled | Should -BeTrue
                }

                It 'Should return a LogMode is Circular' {
                    $results.LogMode | Should -Be 'Circular'
                }

                It 'Should return a LogRetentionDays of 0' {
                    $results.LogRetentionDays | Should -Be 0
                }

                It 'Should return a LogFilePath of %SystemRoot%\System32\Winevt\Logs\Application.evtx' {
                    $results.LogFilePath | Should -Be "%SystemRoot%\System32\Winevt\Logs\Application.evtx"
                }

                It 'Should return SecurityDescriptor with a value TestDescriptor' {
                    $results.SecurityDescriptor | Should -Be 'TestDescriptor'
                }
            }

            Describe "$($script:dscResourceName)\Test-TargetResource" -Tag 'Test' {

                Mock -CommandName Get-WindowsEventLog -MockWith {
                    $properties = @{
                        MaximumSizeInBytes = 1028kb
                        IsEnabled          = $true
                        LogMode            = 'Circular'
                        LogFilePath        = '%SystemRoot%\System32\Winevt\Logs\Application.evtx'
                        SecurityDescriptor = 'TestDescriptor'
                        LogRetentionDays   = '7'
                        LogName            = 'Application'
                    }

                    return (New-Object -TypeName PSObject -Property $properties)
                }

                Mock -CommandName Get-EventLog -MockWith {
                    $params = @{
                        MinimumRetentionDays = '7'
                        Log                  = 'Application'
                    }

                    return (New-Object -TypeName PSObject -Property $params)
                }

                It 'Should not throw when passed an valid Logname' {
                    { Test-TargetResource -LogName 'Application' -IsEnabled $true -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should throw when passed an invalid LogMode' {
                    { Test-TargetResource -LogName 'Application' -LogMode 'BadLogmode' -IsEnabled $true -ErrorAction Stop } | Should -Throw
                }

                It 'Should not throw when passed an valid LogMode' {
                    { Test-TargetResource -LogName 'Application' -LogMode 'Circular' -IsEnabled $true -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should return $true if Logmode is in desired state' {
                    Test-TargetResource -LogName 'Application' -LogMode 'Circular' -IsEnabled $true | Should -BeTrue
                }

                It 'Should return $false if Logmode is not in desired state' {
                    Test-TargetResource -LogName 'Application' -LogMode 'AutoBackup' -IsEnabled $false | Should -BeFalse
                }

                It 'Should throw when passed an invalid MaximumSizeInBytes below 1028kb' {
                    { Test-TargetResource -LogName 'Application' -LogMode 'Circular' -IsEnabled $true -MaximumSizeInBytes 1027kb -ErrorAction Stop } | Should -Throw
                }

                It 'Shoudl throw when passed an invalid MaximumSizeInBytes above 18014398509481983kb' {
                    { Test-TargetResource -LogName 'Application' -LogMode 'Circular' -IsEnabled $true -MaximumSizeInBytes 18014398509481983kb -ErrorAction Stop } | Should -Throw
                }

                It 'Should return $true if MaximumSizeInBytes is in desired state' {
                    Test-TargetResource -MaximumSizeInBytes 1028kb -LogName 'Application' -IsEnabled $true | Should -BeTrue
                }

                It 'Should return $false if MaximumSizeInBytes is not in desired state' {
                    Test-TargetResource -MaximumSizeInBytes 2048kb -LogName 'Application' -IsEnabled $true | Should -BeFalse
                }

                It 'Should not throw when passed an valid MaximumSizeInBytes' {
                    { Test-TargetResource -LogName 'Application' -MaximumSizeInBytes 1028kb -IsEnabled $true -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should throw when passed an invalid LogRetentionDays below 1 day' {
                    { Test-TargetResource -LogName 'Application' -LogMode 'AutoBackup' -IsEnabled $true -LogRetentionDays 0  -ErrorAction Stop } | Should -Throw
                }

                It 'Should throw when passed an invalid LogRetentionDays above 365 days' {
                    { Test-TargetResource -LogName 'Application' -LogMode 'AutoBackup' -IsEnabled $true -LogRetentionDays 366 -ErrorAction Stop } | Should -Throw
                }

                It 'Should not throw when passed an valid LogRetentionDays' {
                    { Test-TargetResource -LogName 'Application' -LogMode 'AutoBackup' -LogRetentionDays 30 -IsEnabled $true -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should return $false if LogRetentionDays is not in desired state' {
                    Test-TargetResource -LogName 'Application' -IsEnabled $true -LogRetentionDays 13 -LogMode 'AutoBackup'  | Should -BeFalse
                }

                It 'Should return $true if LogRetentionDays is in desired state' {
                    Mock -CommandName Get-WindowsEventLog -MockWith {
                        $properties = @{
                            MaximumSizeInBytes = 1028kb
                            IsEnabled          = $true
                            LogMode            = 'AutoBackup'
                            LogFilePath        = '%SystemRoot%\System32\Winevt\Logs\Application.evtx'
                            SecurityDescriptor = 'TestDescriptor'
                            LogRetentionDays   = '7'
                            LogName            = 'Application'
                        }

                        return (New-Object -TypeName PSObject -Property $properties)
                    }

                    Test-TargetResource -LogName 'Application' -IsEnabled $true -LogRetentionDays 7 -LogMode 'AutoBackup'  | Should -BeTrue
                }

                It 'Should not throw when passed an invalid LogRetentionDays' {
                    { Test-TargetResource -LogName 'WrongLog' -LogMode 'AutoBackup' -LogRetentionDays 30 -IsEnabled $true -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should not throw when passed an invalid LogMode with LogRetention' {
                    { Test-TargetResource -LogName 'Application' -LogMode 'Circular' -LogRetentionDays 30 -IsEnabled $true -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should not throw when passed an valid LogFilePath' {
                    { Test-TargetResource -LogName 'Application' -IsEnabled $true -LogFilePath '%SystemRoot%\System32\Winevt\Logs\Application.evtx' -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should return $true if LogFilePath is in desired state' {
                    Test-TargetResource -LogName 'Application' -LogFilePath '%SystemRoot%\System32\Winevt\Logs\Application.evtx' -IsEnabled $true | Should -BeTrue
                }

                It 'Should return $false if LogFilePath is not in desired state' {
                    Test-TargetResource -LogName 'Application' -LogFilePath '%SystemRoot%\System32\Winevt\OtherLogs\Application.evtx' -IsEnabled $true | Should -BeFalse
                }

                It 'Should not throw when passed an valid SecurityDescriptor' {
                    { Test-TargetResource -LogName 'Application' -SecurityDescriptor 'TestDescriptor' -IsEnabled $true -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should return $true if SecurityDescriptor is in desired state' {
                    Test-TargetResource -LogName 'Application' -SecurityDescriptor 'TestDescriptor' -IsEnabled $true | Should -BeTrue
                }

                It 'Should return $false if SecurityDescriptor is not in desired state' {
                    Test-TargetResource -LogName 'Application' -SecurityDescriptor 'TestTestDescriptor' -IsEnabled $true | Should -BeFalse
                }

                It 'Should return $true if IsEnabled is in desired state' {
                    Test-TargetResource -LogName 'Application' -IsEnabled $true | Should -BeTrue
                }

                It 'Should return $false if IsEnabled is not in desired state' {
                    Test-TargetResource -LogName 'Application' -IsEnabled $false | Should -BeFalse
                }

                It 'Should return $false if IsEnabled is not in desired state' {
                    Mock -CommandName Get-WindowsEventLog -MockWith {
                        $properties = @{
                            MaximumSizeInBytes = 1028kb
                            IsEnabled          = $false
                            LogName            = 'Application'
                        }

                        return (New-Object -TypeName PSObject -Property $properties)
                    }

                    Test-TargetResource -LogName 'Application' -IsEnabled $true | Should -BeFalse
                }

                It 'Should return $true if IsEnabled is not in desired state' {
                    Mock -CommandName Get-WindowsEventLog -MockWith {
                        $properties = @{
                            MaximumSizeInBytes = 1028kb
                            IsEnabled          = $true
                            LogName            = 'Application'
                        }

                        return (New-Object -TypeName PSObject -Property $properties)
                    }

                    Test-TargetResource -LogName 'Application' -IsEnabled $true | Should -BeTrue
                }
            }

            Describe "$($script:dscResourceName)\Set-TargetResource" -Tag 'Set' {
                Mock -CommandName Get-WindowsEventLog -MockWith {
                    $properties = @{
                        MaximumSizeInBytes = 5000kb
                        IsEnabled          = $true
                        LogMode            = 'AutoBackup'
                        LogFilePath        = 'c:\logs\test.evtx'
                        SecurityDescriptor = 'TestDescriptor'
                        LogRetentionDays   = '7'
                        LogName            = 'TestLog'
                    }

                    return (New-Object -TypeName PSObject -Property $properties)
                }

                Mock -CommandName Get-EventLog -MockWith {
                    $params = @{
                        MinimumRetentionDays = '7'
                        Log                  = 'TestLog'
                    }

                    return (New-Object -TypeName PSObject -Property $params)
                }

                It 'Should set MaximumSizeInBytes to 1028kb' {
                        Mock -CommandName Save-LogFile
                        Set-TargetResource -MaximumSizeInBytes 1028kb -IsEnabled $true -LogName 'TestLog'
                        Assert-MockCalled -CommandName Save-LogFile -Exactly -Times 1 -Scope It
                }

                It 'MaximumSizeInBytes is in desired state' {
                    Mock -CommandName Save-LogFile
                    Set-TargetResource -MaximumSizeInBytes 5000kb -IsEnabled $true -LogName 'TestLog'
                    Assert-MockCalled -CommandName Save-LogFile -Exactly -Times 0 -Scope It
                }

                It 'Should set SecurityDescriptor to OtherTestDescriptor' {
                    Mock -CommandName Save-LogFile
                    Set-TargetResource -IsEnabled $true -LogName 'TestLog' -SecurityDescriptor 'OtherTestDescriptor'
                    Assert-MockCalled -CommandName Save-LogFile -Exactly -Times 1 -Scope It
                }

                It 'SecurityDescriptor is in desired state' {
                    Mock -CommandName Save-LogFile
                    Set-TargetResource -IsEnabled $true -LogName 'TestLog' -SecurityDescriptor 'TestDescriptor'
                    Assert-MockCalled -CommandName Save-LogFile -Exactly -Times 0 -Scope It
                }

                It 'Should set LogFilePath to default path' {
                    Mock -CommandName Save-LogFile
                    Set-TargetResource -IsEnabled $true -LogName 'TestLog' -LogFilePath '%SystemRoot%\System32\Winevt\Logs\Application.evtx'
                    Assert-MockCalled -CommandName Save-LogFile -Exactly -Times 1 -Scope It
                }

                It 'LogFilePath is in desired state' {
                    Mock -CommandName Save-LogFile
                    Set-TargetResource -IsEnabled $true -LogName 'TestLog' -LogFilePath 'c:\logs\test.evtx'
                    Assert-MockCalled -CommandName Save-LogFile -Exactly -Times 0 -Scope It
                }

                It 'Should set LogRetentionDays to 14 days' {
                    Mock -CommandName Set-LogRetentionDays
                    Set-TargetResource -LogRetentionDays '14' -IsEnabled $true -LogName 'TestLog' -LogMode 'Autobackup'
                    Assert-MockCalled -CommandName Set-LogRetentionDays -Exactly -Times 1 -Scope It
                }

                It 'Should set LogRetentionDays to 32 days, wrong Logmode' {
                    Mock -CommandName Set-LogRetentionDays
                    Set-TargetResource -LogRetentionDays '32' -IsEnabled $true -LogName 'TestLog' -LogMode 'Circular'
                    Assert-MockCalled -CommandName Set-LogRetentionDays -Exactly -Times 0 -Scope It
                }

                It 'Should set LogRetentionDays is in desired state' {
                    Mock -CommandName Set-LogRetentionDays
                    Set-TargetResource -LogRetentionDays '7' -IsEnabled $true -LogName 'TestLog' -LogMode 'Autobackup'
                    Assert-MockCalled -CommandName Set-LogRetentionDays -Exactly -Times 0 -Scope It
                }

                It 'Should set IsEnabled to false' {
                    Mock -CommandName Save-LogFile
                    Set-TargetResource -IsEnabled $false -LogName 'TestLog'
                    Assert-MockCalled -CommandName Save-LogFile -Exactly -Times 1 -Scope It
                }

                It 'IsEnabled is in desired state' {
                    Mock -CommandName Save-LogFile
                    Set-TargetResource -IsEnabled $true -LogName 'TestLog'
                    Assert-MockCalled -CommandName Save-LogFile -Exactly -Times 0 -Scope It
                }

                It 'IsEnabled is not in desired state' {
                    Mock -CommandName Save-LogFile
                    Set-TargetResource -IsEnabled $false -LogName 'TestLog'
                    Assert-MockCalled -CommandName Save-LogFile -Exactly -Times 1 -Scope It
                }

                It 'Should throw if IsEnabled is not in desired state' {
                    Mock -CommandName Save-LogFile
                    Mock -CommandName Get-WindowsEventLog -MockWith { throw }
                    { Set-TargetResource -LogName 'SomeLog' -IsEnabled $false } | Should -Throw
                }

                It 'IsEnabled is not in desired state' {
                    Mock -CommandName Get-WindowsEventLog -MockWith {
                        $properties = @{
                            MaximumSizeInBytes = 5000kb
                            IsEnabled          = $false
                            LogMode            = 'AutoBackup'
                            LogFilePath        = 'c:\logs\test.evtx'
                            SecurityDescriptor = 'TestDescriptor'
                            LogRetentionDays   = '7'
                            LogName            = 'TestLog'
                        }

                        return (New-Object -TypeName PSObject -Property $properties)
                    }

                    Set-TargetResource -IsEnabled $true -LogName 'TestLog'
                    Assert-MockCalled -CommandName Save-LogFile -Exactly -Times 1 -Scope It
                }

            Describe "$($script:dscResourceName)\Save-LogFile" -Tag 'Helper' {
                Mock -CommandName Limit-Eventlog -MockWith { throw }

                It 'Should throw if we are unable to get a log' {
                    {  Limit-Eventlog -LogName 'Application' -OverflowAction 'OverwriteOlder' -RetentionDays 30 } | Should -Throw
                }
            }

            Describe "$($script:dscResourceName)\Set-LogRetentionDays" -Tag 'Helper' {
                Mock -CommandName Limit-Eventlog -MockWith { throw }

                It 'Should throw if we are unable to get a log' {
                    {  Limit-Eventlog -LogName 'Application' -OverflowAction 'OverwriteOlder' -RetentionDays 30 } | Should -Throw
                }
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
