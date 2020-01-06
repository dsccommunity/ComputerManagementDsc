#region HEADER
$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'MSFT_PendingReboot'

# Integration Test Template Version: 1.3.3
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
    -TestType Integration
#endregion

try
{
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configFile

    Describe "$($script:dscResourceName)_Integration" {
        <#
            These integration tests will not actually reboot the node
            because that would terminate the tests and cause them to fail.

            There does not appear to be a method of determining if the
            reboot is in fact triggered, so this is not currently tested.

            Instead, we will preserve the current state of the Auto Update
            reboot flag and then set it to reboot required. After the tests
            have run we will determine if the Get-TargetResource indicates
            that a reboot would have been required.
        #>
        $windowsUpdateKeys = (Get-ChildItem -Path $rebootRegistryKeys.WindowsUpdate).Name

        if ($windowsUpdateKeys)
        {
            $script:currentAutoUpdateRebootState = $windowsUpdateKeys.Split('\') -contains 'RebootRequired'
        }

        if (-not $script:currentAutoUpdateRebootState)
        {
            $null = New-Item `
                -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\' `
                -Name 'RebootRequired'
        }

        $configData = @{
            AllNodes = @(
                @{
                    NodeName   = 'localhost'
                    RebootName = 'TestReboot'
                    SkipComponentBasedServicing = $false
                    SkipWindowsUpdate           = $false
                    SkipPendingFileRename       = $false
                    SkipPendingComputerRename   = $false
                    SkipCcmClientSDK            = $true
                }
            )
        }

        It 'Should compile and apply the MOF without throwing' {
            {
                & "$($script:dscResourceName)_Config" `
                    -OutputPath $TestDrive `
                    -ConfigurationData $configData

                $startDscConfigurationParameters = @{
                    Path         = $TestDrive
                    ComputerName = 'localhost'
                    Wait         = $true
                    Verbose      = $true
                    Force        = $true
                    ErrorAction  = 'Stop'
                }

                Start-DscConfiguration @startDscConfigurationParameters
            } | Should -Not -Throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            {
                Get-DscConfiguration -Verbose -ErrorAction Stop
            } | Should -Not -Throw
        }

        It 'Should have set the resource and all the parameters should match' {
            $current = Get-DscConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq "$($script:dscResourceName)_Config"
            }
            $current.Name | Should -Be $configData.AllNodes[0].RebootName
            $current.SkipComponentBasedServicing | Should -Be $configData.AllNodes[0].SkipComponentBasedServicing
            $current.ComponentBasedServicing | Should -BeFalse
            $current.SkipWindowsUpdate | Should -Be $configData.AllNodes[0].SkipWindowsUpdate
            $current.WindowsUpdate | Should -BeTrue
            $current.SkipPendingFileRename | Should -Be $configData.AllNodes[0].SkipPendingFileRename
            $current.PendingFileRename | Should -BeFalse
            $current.SkipPendingComputerRename | Should -Be $configData.AllNodes[0].SkipPendingComputerRename
            $current.PendingComputerRename | Should -BeFalse
            $current.SkipCcmClientSDK | Should -Be $configData.AllNodes[0].SkipCcmClientSDK
            $current.CcmClientSDK | Should -BeFalse
            $current.RebootRequired | Should -BeTrue
        }
    }
}
finally
{
    #region FOOTER
    if (-not $script:currentAutoUpdateRebootState)
    {
        $null = Remove-Item `
            -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired' `
            -ErrorAction SilentlyContinue
    }

    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
