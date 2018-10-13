#region HEADER
$script:DSCModuleName = 'ComputerManagementDsc'
$script:DSCResourceName = 'MSFT_WinEventLog'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\ComputerManagementDsc'
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName  `
    -TestType Unit
#endregion HEADER

# Begin Testing
try
{
    InModuleScope $script:DSCResourceName {
        $script:DSCResourceName = 'MSFT_WinEventLog'

        Describe "$($script:DSCResourceName)\Get-TargetResource" -Tag 'Get' {

            Mock -CommandName Get-WinEvent -MockWith {
                $properties = @{
                    MaximumSizeInBytes     = 4096kb
                        IsEnabled          = $true
                        LogMode            = 'Circular'
                        LogFilePath        = '%SystemRoot%\System32\Winevt\Logs\Application.evtx'
                        SecurityDescriptor = 'TestDescriptor'
                        LogRetentionDays   = '0'
                }

                Write-Output (New-Object -TypeName PSObject -Property $properties)
            }

            $results = Get-TargetResource -LogName 'Application' -IsEnabled $true

            It 'Should return an hashtable' {
                $results.GetType().Name | Should -Be 'HashTable'
            }

            It 'Should return a Logname Application' {
                $results.LogName = 'Application'
            }

            It 'Should return a MaximumSizeInBytes of 4096kb' {
                $results.MaximumSizeInBytes | Should -Be 4096kb
            }

            It 'Should return IsEnabled is true' {
                $results.IsEnabled | should -Be $true
            }

            It 'Should return a LogMode is Circular' {
                $results.LogMode | Should -Be 'Circular'
            }

            It 'Should return a LogRetentionDays of 30' {
                $results.LogRetentionDays | Should -Be 30
            }

            It 'Should return a LogFilePath of %SystemRoot%\System32\Winevt\Logs\Application.evtx' {
                $results.LogFilePath | Should -Be "%SystemRoot%\System32\Winevt\Logs\Application.evtx"
            }

            It 'Should return SecurityDescriptor with a value TestDescriptor' {
                $results.SecurityDescriptor | Should -Be 'TestDescriptor'
            }
        }

        Describe "$($script:DSCResourceName)\Test-TargetResource" -Tag 'Test' {

            Mock -CommandName Get-WinEvent -MockWith {
                $properties = @{
                    MaximumSizeInBytes = 1028kb
                    IsEnabled          = $true
                    LogMode            = 'Circular'
                    LogFilePath        = '%SystemRoot%\System32\Winevt\Logs\Application.evtx'
                    SecurityDescriptor = 'TestDescriptor'
                    LogRetentionDays   = '7'
                    LogName            = 'Application'
                }

                Write-Output (New-Object -TypeName PSObject -Property $properties)
            }

            Mock -CommandName Get-EventLog -MockWith {
                $params = @{
                    MinimumRetentionDays = '7'
                    Log                  = 'Application'
                }

                Write-Output (New-Object -TypeName PSObject -Property $params)
            }

            It 'Should not throw when passed an valid Logname' {
                { Test-TargetResource -LogName 'Application' -IsEnabled $true -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Throws when passed an invalid LogMode' {
                { Test-TargetResource -LogName 'Application' -LogMode 'BadLogmode' -IsEnabled $true -ErrorAction Stop } | Should -Throw
            }

            It 'Should not throw when passed an valid LogMode' {
                { Test-TargetResource -LogName 'Application' -LogMode 'Circular' -IsEnabled $true -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should return $true if Logmode is in desired state' {
                Test-TargetResource -LogName 'Application' -LogMode 'Circular' -IsEnabled $true | Should -Be $true
            }

            It 'Should return $false if Logmode is not in desired state' {
                Test-TargetResource -LogName 'Application' -LogMode 'AutoBackup' -IsEnabled $false | Should -Be $false
            }

            It 'Throws when passed an invalid MaximumSizeInBytes below 1028kb' {
                { Test-TargetResource -LogName 'Application' -LogMode 'Circular' -IsEnabled $true -MaximumSizeInBytes 1027kb -ErrorAction Stop } | Should -Throw
            }

            It 'Throws when passed an invalid MaximumSizeInBytes above 18014398509481983kb' {
                { Test-TargetResource -LogName 'Application' -LogMode 'Circular' -IsEnabled $true -MaximumSizeInBytes 18014398509481983kb -ErrorAction Stop } | Should -Throw
            }

            It 'Should return $true if MaximumSizeInBytes is in desired state' {
                Test-TargetResource -MaximumSizeInBytes 1028kb -LogName 'Application' -IsEnabled $true | Should -Be $true
            }

            It 'Should return $false if MaximumSizeInBytes is not in desired state' {
                Test-TargetResource -MaximumSizeInBytes 2048kb -LogName 'Application' -IsEnabled $true | Should -Be $false
            }

            It 'Should not throw when passed an valid MaximumSizeInBytes' {
                { Test-TargetResource -LogName 'Application' -MaximumSizeInBytes 1028kb -IsEnabled $true -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Throws when passed an invalid LogRetentionDays below 1 day' {
                { Test-TargetResource -LogName 'Application' -LogMode 'AutoBackup' -IsEnabled $true -LogRetentionDays 0  -ErrorAction Stop } | Should -Throw
            }

            It 'Throws when passed an invalid LogRetentionDays above 365 days' {
                { Test-TargetResource -LogName 'Application' -LogMode 'AutoBackup' -IsEnabled $true -LogRetentionDays 366 -ErrorAction Stop } | Should -Throw
            }

            It 'Should not throw when passed an valid LogRetentionDays' {
                { Test-TargetResource -LogName 'Application' -LogMode 'AutoBackup' -LogRetentionDays 30 -IsEnabled $true -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should return $false if LogRetentionDays is not in desired state' {
                Test-TargetResource -LogName 'Application' -IsEnabled $true -LogRetentionDays 13 -LogMode 'AutoBackup'  | Should -Be $false
            }

            It 'Should return $true if LogRetentionDays is in desired state' {
                Mock -CommandName Get-WinEvent -MockWith {
                    $properties = @{
                        MaximumSizeInBytes = 1028kb
                        IsEnabled          = $true
                        LogMode            = 'AutoBackup'
                        LogFilePath        = '%SystemRoot%\System32\Winevt\Logs\Application.evtx'
                        SecurityDescriptor = 'TestDescriptor'
                        LogRetentionDays   = '7'
                        LogName            = 'Application'
                    }

                    Write-Output (New-Object -TypeName PSObject -Property $properties)
                }

                Test-TargetResource -LogName 'Application' -IsEnabled $true -LogRetentionDays 7 -LogMode 'AutoBackup'  | Should -Be $true
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
                Test-TargetResource -LogName 'Application' -LogFilePath '%SystemRoot%\System32\Winevt\Logs\Application.evtx' -IsEnabled $true | Should -Be $true
            }

            It 'Should return $false if LogFilePath is not in desired state' {
                Test-TargetResource -LogName 'Application' -LogFilePath '%SystemRoot%\System32\Winevt\OtherLogs\Application.evtx' -IsEnabled $true | Should -Be $false
            }

            It 'Should not throw when passed an valid SecurityDescriptor' {
                { Test-TargetResource -LogName 'Application' -SecurityDescriptor 'TestDescriptor' -IsEnabled $true -ErrorAction Stop } | Should -Not -Throw
            }

            It 'Should return $true if SecurityDescriptor is in desired state' {
                Test-TargetResource -LogName 'Application' -SecurityDescriptor 'TestDescriptor' -IsEnabled $true | Should -Be $true
            }

            It 'Should return $false if SecurityDescriptor is not in desired state' {
                Test-TargetResource -LogName 'Application' -SecurityDescriptor 'TestTestDescriptor' -IsEnabled $true | Should -Be $false
            }

            It 'Should return $true if IsEnabled is in desired state' {
                Test-TargetResource -LogName 'Application' -IsEnabled $true | Should -Be $true
            }

            It 'Should return $false if IsEnabled is not in desired state' {
                Test-TargetResource -LogName 'Application' -IsEnabled $false | Should -Be $false
            }

            It 'Should return $false if IsEnabled is not in desired state' {
                Mock -CommandName Get-WinEvent -MockWith {
                    $properties = @{
                        MaximumSizeInBytes = 1028kb
                        IsEnabled          = $false
                        LogName            = 'Application'
                    }

                    Write-Output (New-Object -TypeName PSObject -Property $properties)
                }

                Test-TargetResource -LogName 'Application' -IsEnabled $true | Should -Be $false
            }

            It 'Should return $true if IsEnabled is not in desired state' {
                Mock -CommandName Get-WinEvent -MockWith {
                    $properties = @{
                        MaximumSizeInBytes = 1028kb
                        IsEnabled          = $true
                        LogName            = 'Application'
                    }

                    Write-Output (New-Object -TypeName PSObject -Property $properties)
                }

                Test-TargetResource -LogName 'Application' -IsEnabled $true | Should -Be $true
            }
        }

        Describe "$($script:DSCResourceName)\Set-TargetResource" -Tag 'Set' {
            Mock -CommandName Get-WinEvent -MockWith {
                $properties = @{
                    MaximumSizeInBytes = 5000kb
                    IsEnabled          = $true
                    LogMode            = 'AutoBackup'
                    LogFilePath        = 'c:\logs\test.evtx'
                    SecurityDescriptor = 'TestDescriptor'
                    LogRetentionDays   = '7'
                    LogName            = 'TestLog'
                }

                Write-Output (New-Object -TypeName PSObject -Property $properties)
            }

            Mock -CommandName Get-EventLog -MockWith {
                $params = @{
                    MinimumRetentionDays = '7'
                    Log                  = 'TestLog'
                }

                Write-Output (New-Object -TypeName PSObject -Property $params)
            }

            It 'Sets MaximumSizeInBytes to 1028kb' {
                    Mock -CommandName Set-MaximumSizeInBytes
                    Set-TargetResource -MaximumSizeInBytes 1028kb -IsEnabled $true -LogName 'TestLog'
                    Assert-MockCalled -CommandName Set-MaximumSizeInBytes -Exactly -Times 1 -Scope It
            }

            It 'MaximumSizeInBytes is in desired state' {
                Mock -CommandName Set-MaximumSizeInBytes
                Set-TargetResource -MaximumSizeInBytes 5000kb -IsEnabled $true -LogName 'TestLog'
                Assert-MockCalled -CommandName Set-MaximumSizeInBytes -Exactly -Times 0 -Scope It
            }

            It 'Sets LogRetentionDays to 32 days' {
                Mock -CommandName Set-LogRetentionDays
                Set-TargetResource -LogRetentionDays '32' -IsEnabled $true -LogName 'TestLog' -LogMode 'Autobackup'
                Assert-MockCalled -CommandName Set-LogRetentionDays -Exactly -Times 1 -Scope It
            }

            It 'Sets LogRetentionDays to 32 days, wrong Logmode' {
                Mock -CommandName Set-LogRetentionDays
                Set-TargetResource -LogRetentionDays '32' -IsEnabled $true -LogName 'TestLog' -LogMode 'Circular'
                Assert-MockCalled -CommandName Set-LogRetentionDays -Exactly -Times 0 -Scope It
            }

            It 'LogRetentionDays is in desired state' {
                Mock -CommandName Set-LogRetentionDays
                Set-TargetResource -LogRetentionDays '7' -IsEnabled $true -LogName 'TestLog' -LogMode 'Autobackup'
                Assert-MockCalled -CommandName Set-LogRetentionDays -Exactly -Times 0 -Scope It
            }

            It 'Sets IsEnabled to false' {
                Mock -CommandName Set-IsEnabled
                Set-TargetResource -IsEnabled $false -LogName 'TestLog'
                Assert-MockCalled -CommandName Set-IsEnabled -Exactly -Times 1 -Scope It
            }

            It 'IsEnabled is in desired state' {
                Mock -CommandName Set-IsEnabled
                Set-TargetResource -IsEnabled $true -LogName 'TestLog'
                Assert-MockCalled -CommandName Set-IsEnabled -Exactly -Times 0 -Scope It
            }

            It 'IsEnabled is not in desired state' {
                Mock -CommandName Get-WinEvent -MockWith {
                    $properties = @{
                        MaximumSizeInBytes = 5000kb
                        IsEnabled          = $false
                        LogMode            = 'AutoBackup'
                        LogFilePath        = 'c:\logs\test.evtx'
                        SecurityDescriptor = 'TestDescriptor'
                        LogRetentionDays   = '7'
                        LogName            = 'TestLog'
                    }

                    Write-Output (New-Object -TypeName PSObject -Property $properties)
                }

                Set-TargetResource -IsEnabled $true -LogName 'TestLog'
                Assert-MockCalled -CommandName Set-IsEnabled -Exactly -Times 1 -Scope It
            }

            It 'Sets LogMode to Circular' {
                Mock -CommandName Set-LogMode
                Set-TargetResource -IsEnabled $true -LogName 'TestLog' -LogMode 'Circular'
                Assert-MockCalled -CommandName Set-LogMode -Exactly -Times 1 -Scope It
            }

            It 'LogMode is in desired state' {
                Mock -CommandName Set-LogMode
                Set-TargetResource -IsEnabled $true -LogName 'TestLog' -LogMode 'AutoBackup'
                Assert-MockCalled -CommandName Set-LogMode -Exactly -Times 0 -Scope It
            }

            It 'Sets SecurityDescriptor to OtherTestDescriptor' {
                Mock -CommandName Set-SecurityDescriptor
                Set-TargetResource -IsEnabled $true -LogName 'TestLog' -SecurityDescriptor 'OtherTestDescriptor'
                Assert-MockCalled -CommandName Set-SecurityDescriptor -Exactly -Times 1 -Scope It
            }

            It 'SecurityDescriptor is in desired state' {
                Mock -CommandName Set-SecurityDescriptor
                Set-TargetResource -IsEnabled $true -LogName 'TestLog' -SecurityDescriptor 'TestDescriptor'
                Assert-MockCalled -CommandName Set-SecurityDescriptor -Exactly -Times 0 -Scope It
            }

            It 'Sets LogFilePath to default path' {
                Mock -CommandName Set-LogFilePath
                Set-TargetResource -IsEnabled $true -LogName 'TestLog' -LogFilePath '%SystemRoot%\System32\Winevt\Logs\Application.evtx'
                Assert-MockCalled -CommandName Set-LogFilePath -Exactly -Times 1 -Scope It
            }

            It 'LogFilePath is in desired state' {
                Mock -CommandName Set-LogFilePath
                Set-TargetResource -IsEnabled $true -LogName 'TestLog' -LogFilePath 'c:\logs\test.evtx'
                Assert-MockCalled -CommandName Set-LogFilePath -Exactly -Times 0 -Scope It
            }
        }

        Describe "$($script:DSCResourceName)\Set-IsEnabled" -Tag 'Helper' {
            It 'Tests the Private function' {
                Set-IsEnabled -LogName 'Application' -IsEnabled $true | Should -Be $null
            }

            Mock -CommandName Get-WinEvent -MockWith { throw }
            It "Should throw if we're unable to get a log" {
                { Set-IsEnabled -LogName 'WrongLog' -IsEnabled $truelse } | Should -Throw
            }
        }

        Describe "$($script:DSCResourceName)\Set-MaximumSizeInBytes" -Tag 'Helper' {
            It 'Tests the Private function' {
                Set-MaximumSizeInBytes -LogName 'Application' -MaximumSizeInBytes 2048kb | Should -Be $null
            }

            Mock -CommandName Get-WinEvent -MockWith { throw }
            It "Should throw if we're unable to get a log" {
                { Set-MaximumSizeInBytes -LogName 'NotExistingLog' -MaximumSizeInBytes 'StringValue' } | Should -Throw
            }
        }

        Describe "$($script:DSCResourceName)\Set-LogMode" -Tag 'Helper' {
            It 'Tests the Private function' {
                Set-LogMode -LogName 'Application' -LogMode 'Circular' | Should -Be $null
            }

            Mock -CommandName Get-WinEvent -MockWith { throw }
            It "Should throw if we're unable to get a log" {
                { Set-LogMode -LogName 'NotExistingLog' -LogMode 'BadValue' } | Should -Throw
            }
        }

        Describe "$($script:DSCResourceName)\Set-LogRetentionDays" -Tag 'Helper' {
            It 'Tests the Private function' {
                Set-LogRetentionDays -LogName 'Application' -LogRetentionDays 30 | Should -Be $null
            }

            Mock -CommandName Limit-Eventlog -MockWith { throw }
            It "Should throw if we're unable to get a log" {
                {  Limit-Eventlog -LogName 'Application' -OverflowAction 'OverwriteOlder' -RetentionDays 30 } | Should -Throw
            }
        }

        Describe "$($script:DSCResourceName)\Set-SecurityDescriptor" -Tag 'Helper' {
            It 'Tests the Private function' {
                Set-SecurityDescriptor -LogName 'Application' -SecurityDescriptor 'TestDescriptor' | Should -Be $null
            }

            Mock -CommandName Get-WinEvent -MockWith { throw }
            It "Should throw if we're unable to get a log" {
                { Set-SecurityDescriptor -LogName 'Application' -SecurityDescriptor '' } | Should -Throw
            }
        }

        Describe "$($script:DSCResourceName)\Set-LogFilePath" -Tag 'Helper' {
            It 'Tests the Private function' {
                Set-LogFilePath -LogName 'Application' -LogFilePath 'C:\Temp' | Should -Be $null
            }

            Mock -CommandName Get-WinEvent -MockWith { throw }
            It "Should throw if we're unable to get a log" {
                { Set-LogFilePath -LogName 'Application' -LogFilePath '' } | Should Throw
            }
        }

        $errorRecord = 'InvalidOperationException: You cannot call a method on a null-valued expression.'
        Describe "$($script:DSCResourceName)\New-TerminatingError" -Tag 'Helper' {
            It 'Tests the Private function' {
                { New-TerminatingError -errorId 'TestFailure' -errorMessage 'TestFailureMessage' -errorCategory 'InvalidOperation' } | Should -Throw 'TestFailureMessage'
            }

            Mock -CommandName Get-WinEvent -MockWith { throw }
            It "Should throw if we're unable to get a log" {
                { New-TerminatingError -errorId 'TestFailure' -errorMessage 'TestFailureMessage' -errorCategory 'InvalidOperation'  } | Should -Throw
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
