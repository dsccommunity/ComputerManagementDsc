#region HEADER
$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'MSFT_WindowsCapability'

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
        $script:dscResourceName = 'MSFT_WindowsCapability'
        Describe "$($script:dscResourceName)\Get-TargetResource" -Tag 'Get' {

            Mock -CommandName Remove-WindowsCapability
            Mock -CommandName Get-WindowsCapability

            Context 'When a Windows Capability is installed' {
                Mock -CommandName Get-WindowsCapability -MockWith {
                    $properties = @{
                        Name     = 'Browser.InternetExplorer~~~~0.0.11.0'
                        State    = 'Installed'
                    }
                    return (New-Object -TypeName PSObject -Property $properties)
                }

                $results = Get-TargetResource -Name 'Browser.InternetExplorer~~~~0.0.11.0'

                It 'Should return an hashtable' {
                    $results.GetType().Name | Should -Be 'Hashtable'
                }

                It 'Should return a Name of a Windows Capability' {
                    $results.Name = 'Browser.InternetExplorer~~~~0.0.11.0'
                }

                It 'Should return a State of Installed' {
                    $results.State | Should -Be 'Installed'
                }
            }
        }

        Describe "$($script:dscResourceName)\Test-TargetResource" -Tag 'Test' {

            Mock -CommandName Remove-WindowsCapability
            Mock -CommandName Set-WindowsCapability

            Context 'When valid Windows Capability parameters are passed' {
                Mock -CommandName Get-WindowsCapability -MockWith {
                    $properties = @{
                        Name     = 'XPS.Viewer~~~~0.0.1.0'
                        State    = 'Installed'
                        LogPath  = '$ENV:Temp\Logfile.log'
                        LogLevel = 'Errors'
                    }
                    return (New-Object -TypeName PSObject -Property $properties)
                }

                It 'Should not throw when passed an valid Windows Capability' {
                    { Test-TargetResource -Name 'XPS.Viewer~~~~0.0.1.0' -Ensure 'Present' -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should not throw when passed an valid Windows Capability LogLevel' {
                    { Test-TargetResource -Name 'XPS.Viewer~~~~0.0.1.0' -Ensure 'Present' -LogLevel 'Errors' -ErrorAction Stop } | Should -Not -Throw
                }

                Mock -CommandName 'Test-Path' –MockWith {
                    return $true
                }

                It 'Should not throw when passed an valid Windows Capability LogPath' {
                    { Test-TargetResource -Name 'XPS.Viewer~~~~0.0.1.0' -Ensure 'Present' -LogPath '$ENV:Temp\Logfile.log' -ErrorAction Stop } | Should -Not -Throw
                }

                It 'Should return $true if Windows Capability is in desired state' {
                    { Test-TargetResource -Name 'XPS.Viewer~~~~0.0.1.0' -Ensure 'Present' } | Should -BeTrue
                }
            }

            Context 'When invalid Windows Capability parameters are passed' {
                Mock -CommandName Get-WindowsCapability -MockWith {
                    $properties = @{
                        Name     = 'XPS.Viewer~~~~0.0.1.0'
                        State    = 'Installed'
                        LogPath  = '$ENV:Temp\Logfile.log'
                        LogLevel = 'Errors'
                    }
                    return (New-Object -TypeName PSObject -Property $properties)
                }

                It 'Should throw when passed an invalid Windows Capability Name' {
                    { Test-TargetResource -Name 'XPS.BadViewer~~~~0.0.1.0' -Ensure 'Present' -ErrorAction Stop } | Should -Throw
                }

                It 'Should throw when passed an invalid Windows Capability LogLevel' {
                    { Test-TargetResource -Name 'XPS.BadViewer~~~~0.0.1.0' -Ensure 'Present' -LogLevel 'Debug' -ErrorAction Stop } | Should -Throw
                }

                Mock -CommandName 'Test-Path' –MockWith {
                    return $false
                }

                It 'Should throw when passed an invalid Windows Capability LogPath' {
                    { Test-TargetResource -Name 'XPS.BadViewer~~~~0.0.1.0' -Ensure 'Present' -LogPath 'C:\Logs\BadLogfile.log' -ErrorAction Stop } | Should Throw
                }

                It 'Should return $false if Windows Capability is not in desired state' {
                    { Test-TargetResource -Name 'XPS.Viewer~~~~0.0.1.0' -Ensure 'Absent' } | Should -BeFalse
                }
            }
        }

        Describe "$($script:dscResourceName)\Set-TargetResource" -Tag 'Set' {
            Mock -CommandName Get-WindowsCapability

            Context 'When a Windows Capability is installed' {
                Mock -CommandName Add-WindowsCapability -MockWith {
                    $properties = @{
                        Name     = 'XPS.Viewer~~~~0.0.1.0'
                        LogLevel = '2'
                        LogPath  = '%WINDIR%\Logs\Dism\dism.log'
                        State    = 'Installed'
                    }
                    return (New-Object -TypeName PSObject -Property $properties)
                }

                $results = Set-TargetResource -Name 'XPS.Viewer~~~~0.0.1.0' -Ensure 'Present'

                It "Should be in desired state" {
                    Set-TargetResource -Name 'XPS.Viewer~~~~0.0.1.0' -Ensure 'Present'
                    Assert-MockCalled -CommandName Add-WindowsCapability -Exactly -Times 1 -Scope It
                }
            }

            Context 'When a Windows Capability is not installed' {
                Mock -CommandName Remove-WindowsCapability -MockWith {
                    $properties = @{
                        Name     = 'XPS.Viewer~~~~0.0.1.0'
                        LogLevel = '2'
                        LogPath  = '%WINDIR%\Logs\Dism\dism.log'
                        State    = 'NotPresent'
                    }
                    return (New-Object -TypeName PSObject -Property $properties)
                }

                $results = Set-TargetResource -Name 'XPS.Viewer~~~~0.0.1.0' -Ensure 'Present'

                It "Should not be in desired state" {
                    Set-TargetResource -Name 'XPS.Viewer~~~~0.0.1.0' -Ensure 'Absent'
                    Assert-MockCalled -CommandName Remove-WindowsCapability -Exactly -Times 1 -Scope It
                }
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
