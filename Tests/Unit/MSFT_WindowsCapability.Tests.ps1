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
                Mock -CommandName Get-WindowsCapability -MockWith {
                    $properties = @{
                            Name        = 'Browser.InternetExplorer~~~~0.0.11.0'
                            LogLevel    = '3'
                            LimitAccess = $true
                            Online      = $true
                            LogPath     = '%WINDIR%\Logs\Dism\dism.log'
                    }
                    return (New-Object -TypeName PSObject -Property $properties)
                }

                $results = Get-TargetResource -Name 'Browser.InternetExplorer~~~~0.0.11.0' -Ensure 'Present' -Online $true

                It 'Should return an hashtable' {
                    $results.GetType().Name | Should -Be 'Hashtable'
                }

                It 'Should return a Name of a Windows Capability' {
                    $results.Name = 'Browser.InternetExplorer~~~~0.0.11.0'
                }

                It 'Should return a LogLevel of 3' {
                    $results.LogLevel | Should -Be 3
                }

                It 'Should return a LimitAccess of $true' {
                    $results.LimitAccess | Should -Be $true
                }

                It 'Should return a Online of $true' {
                    $results.Online | Should -Be $true
                }

                It 'Should return a LogPath %WINDIR%\Logs\Dism\dism.log' {
                    $results.LogPath | Should -Be '%WINDIR%\Logs\Dism\dism.log'
                }
            }

            Describe "$($script:dscResourceName)\Test-TargetResource" -Tag 'Test' {
            }

            Describe "$($script:dscResourceName)\Set-TargetResource" -Tag 'Set' {
            }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
