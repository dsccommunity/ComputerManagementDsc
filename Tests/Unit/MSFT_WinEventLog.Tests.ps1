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

        Describe "$($script:DSCResourceName)\Get-TargetResource" {

            Mock Get-WinEvent {
                $properties = @{
                    MaximumSizeInBytes = 4096kb
                        IsEnabled          = $true
                        LogMode            = 'Circular'
                        LogFilePath        = '%SystemRoot%\System32\Winevt\Logs\Application.evtx'
                        SecurityDescriptor = 'TestDescriptor'
                }

                Write-Output (New-Object -TypeName PSObject -Property $properties)
            }

            $results = Get-TargetResource -LogName 'Application' -IsEnabled $true

            It 'Should return an hashtable' {
                $results.GetType().Name | Should Be 'HashTable'
            }

            It 'Should return a Hashtable name is Application' {
                $results.LogName = 'Application'
            }

            It 'Should return a Hashatable with the MaximumSizeInBytes is 4096kb' {
                $results.MaximumSizeInBytes | Should Be 4096kb
            }

            It 'Should return a Hashtable where IsEnabled is true' {
                $results.IsEnabled | should Be $true
            }

            It 'Should return a HashTable where LogMode is Circular' {
                $results.LogMode | Should Be 'Circular'
            }

            It 'Should return a HashTable where LogFilePath is %SystemRoot%\System32\Winevt\Logs\Application.evtx' {
                $results.LogFilePath | Should Be "%SystemRoot%\System32\Winevt\Logs\Application.evtx"
            }

            It 'Should return a HashTable where SecurityDescriptor is TestDescriptor' {
                $results.SecurityDescriptor | Should Be 'TestDescriptor'
            }
        }

        Describe "$($script:DSCResourceName)\Test-TargetResource" {

            It 'Throws when passed an invalid Logname' {
                { Test-TargetResource -LogName 'badLogName' -IsEnabled $true -ErrorAction Stop } | Should -Throw
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

            It 'Throws when passed an invalid MaximumSizeInBytes below 1028' {
                { Test-TargetResource -LogName 'Application' -LogMode 'Circular' -IsEnabled $true -MaximumSizeInBytes 1027kb -ErrorAction Stop } | Should -Throw
            }

            It 'Throws when passed an invalid MaximumSizeInBytes above 18014398509481983kb' {
                { Test-TargetResource -LogName 'Application' -LogMode 'Circular' -IsEnabled $true -MaximumSizeInBytes 18014398509481983kb -ErrorAction Stop } | Should -Throw
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

            It 'Should not throw when passed an valid LogFilePath' {
                { Test-TargetResource -LogName 'Application' -IsEnabled $true -LogFilePath '%SystemRoot%\System32\Winevt\Logs\Application.evtx' -ErrorAction Stop } | Should -Not -Throw
            }
        }

        Describe "$($script:DSCResourceName)\Set-TargetResource" {
            Mock Get-WinEvent {
                $properties = @{
                    MaximumSizeInBytes = 5000kb
                    IsEnabled          = $true
                    LogMode            = 'AutoBackup'
                    LogFilePath        = 'c:\logs\test.evtx'
                    SecurityDescriptor = 'TestDescriptor'
                    LogRetentionDays   = '30'
                }

                Write-Output (New-Object -TypeName PSObject -Property $properties)
            }

            Context 'When set is called and actual value does not match expected value' {

                It 'Sets MaximumSizeInBytes to 1028kb' {
                    Mock -CommandName Set-MaximumSizeInBytes -MockWith { }
                    Set-TargetResource -MaximumSizeInBytes 1028kb -IsEnabled $true -LogName 'Application'
                    Assert-MockCalled -CommandName Set-MaximumSizeInBytes -Exactly 1 -Scope It
                }

                It 'MaximumSizeInBytes is in desired state' {
                    Mock -CommandName Set-MaximumSizeInBytes -MockWith { }
                    Set-TargetResource -MaximumSizeInBytes 5000kb -IsEnabled $true -LogName 'Application'
                    Assert-MockCalled -CommandName Set-MaximumSizeInBytes -Exactly 0 -Scope It
                }

                It 'Sets LogRetentionDays to 32' {
                    Mock -CommandName Set-LogRetentionDays -MockWith { }
                    Set-TargetResource -LogRetentionDays '32' -IsEnabled $true -LogName 'Application'
                    Assert-MockCalled -CommandName Set-LogRetentionDays -Exactly 1 -Scope It
                }

                It 'LogRetentionDays is in desired state' {
                    Mock -CommandName Set-LogRetentionDays -MockWith { }
                    Set-TargetResource -LogRetentionDays '30' -IsEnabled $true -LogName 'Application'
                    Assert-MockCalled -CommandName Set-LogRetentionDays -Exactly 0 -Scope It
                }

                It 'Sets IsEnabled to false' {
                    Mock -CommandName Set-IsEnabled -MockWith { }
                    Set-TargetResource -IsEnabled $false -LogName 'Application'
                    Assert-MockCalled -CommandName Set-IsEnabled -Exactly 1 -Scope It
                }

                It 'IsEnabled is in desired state' {
                    Mock -CommandName Set-IsEnabled -MockWith { }
                    Set-TargetResource -IsEnabled $true -LogName 'Application'
                    Assert-MockCalled -CommandName Set-IsEnabled -Exactly 0 -Scope It
                }

                It 'Sets LogMode to Circular' {
                    Mock -CommandName Set-LogMode -MockWith { }
                    Set-TargetResource -IsEnabled $true -LogName 'Application' -LogMode 'Circular'
                    Assert-MockCalled -CommandName Set-LogMode -Exactly 1 -Scope It
                }

                It 'LogMode is in desired state' {
                    Mock -CommandName Set-LogMode -MockWith { }
                    Set-TargetResource -IsEnabled $true -LogName 'Application' -LogMode 'AutoBackup'
                    Assert-MockCalled -CommandName Set-LogMode -Exactly 0 -Scope It
                }

                It 'Sets SecurityDescriptor to OtherTestDescriptor' {
                    Mock -CommandName Set-SecurityDescriptor -MockWith { }
                    Set-TargetResource -IsEnabled $true -LogName 'Application' -SecurityDescriptor 'OtherTestDescriptor'
                    Assert-MockCalled -CommandName Set-SecurityDescriptor -Exactly 1 -Scope It
                }

                It 'SecurityDescriptor is in desired state' {
                    Mock -CommandName Set-SecurityDescriptor -MockWith { }
                    Set-TargetResource -IsEnabled $true -LogName 'Application' -SecurityDescriptor 'TestDescriptor'
                    Assert-MockCalled -CommandName Set-SecurityDescriptor -Exactly 0 -Scope It
                }

                It 'Sets LogFilePath to default path' {
                    Mock -CommandName Set-LogFilePath -MockWith { }
                    Set-TargetResource -IsEnabled $true -LogName 'Application' -LogFilePath '%SystemRoot%\System32\Winevt\Logs\Application.evtx'
                    Assert-MockCalled -CommandName Set-LogFilePath -Exactly 1 -Scope It
                }

                It 'LogFilePath is in desired state' {
                    Mock -CommandName Set-LogFilePath -MockWith { }
                    Set-TargetResource -IsEnabled $true -LogName 'Application' -LogFilePath 'c:\logs\test.evtx'
                    Assert-MockCalled -CommandName Set-LogFilePath -Exactly 0 -Scope It
                }
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
