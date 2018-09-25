#region HEADER
$script:DSCModuleName = 'ComputerManagementDsc'
$script:DSCResourceName = 'MSFT_WinEventLog'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\ComputerManagementDsc'
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) ) {
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName  `
    -TestType Unit
#endregion HEADER

try {
    InModuleScope $script:DSCResourceName {
        $script:DSCResourceName = 'MSFT_WinEventLog'
        Describe 'Get-WinEventlog' {
            Mock Get-WinEvent {
                $properties = @{
                    MaximumSizeInBytes = 5000kb
                    IsEnabled          = $true
                    LogMode            = 'Circular'
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

                It 'Sets LogMode to Retain' {
                    Mock -CommandName Set-LogMode -MockWith { }
                    Set-TargetResource -IsEnabled $true -LogName 'Application' -LogMode 'Retain'
                    Assert-MockCalled -CommandName Set-LogMode -Exactly 1 -Scope It
                }

                It 'LogMode is in desired state' {
                    Mock -CommandName Set-LogMode -MockWith { }
                    Set-TargetResource -IsEnabled $true -LogName 'Application' -LogMode 'Circular'
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

                It 'LogFilePath is in diesred state' {
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
