$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'DSC_PendingReboot'

try
{
    Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
}
catch [System.IO.FileNotFoundException]
{
    throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
}

$script:testEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -ResourceType 'Mof' `
    -TestType 'Integration'

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

# Begin Testing
try
{
    Describe 'PendingReboot Integration Tests' {
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

                Also, on Azure DevOps Agents, there are sometimes pending file
                rename operations that also cause the test to fail. So we will
                also preserve the state of this setting.
            #>
            $script:rebootRegistryKeys = @{
                ComponentBasedServicing = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\'
                WindowsUpdate           = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\'
                PendingFileRename       = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\'
                ActiveComputerName      = 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName'
                PendingComputerName     = 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName'
            }

            $windowsUpdateKeys = (Get-ChildItem -Path $script:rebootRegistryKeys.WindowsUpdate).Name

            if ($windowsUpdateKeys)
            {
                $script:currentAutoUpdateRebootState = $windowsUpdateKeys.Split('\') -contains 'RebootRequired'
            }

            if (-not $script:currentAutoUpdateRebootState)
            {
                $null = New-Item `
                    -Path $script:rebootRegistryKeys.WindowsUpdate `
                    -Name 'RebootRequired'
            }

            $script:currentPendingFileRenameState = (Get-ItemProperty -Path $script:rebootRegistryKeys.PendingFileRename).PendingFileRenameOperations

            if ($script:currentPendingFileRenameState)
            {
                $null = Remove-ItemProperty `
                    -Path $script:rebootRegistryKeys.PendingFileRename `
                    -Name PendingFileRenameOperations
            }

            $configData = @{
                AllNodes = @(
                    @{
                        NodeName                    = 'localhost'
                        RebootName                  = 'TestReboot'
                        SkipComponentBasedServicing = $false
                        SkipWindowsUpdate           = $false
                        SkipPendingFileRename       = $false
                        SkipPendingComputerRename   = $false
                        SkipCcmClientSDK            = $true
                    }
                )
            }

            It 'Should compile the MOF without throwing' {
                {
                    & "$($script:dscResourceName)_Config" `
                        -OutputPath $TestDrive `
                        -ConfigurationData $configData
               } | Should -Not -Throw
            }

            It 'Should apply the MOF without throwing' {
                {
                    Reset-DscLcm

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
                $current.ComponentBasedServicing | Should -BeFalse
                $current.WindowsUpdate | Should -BeTrue
                $current.PendingFileRename | Should -BeFalse
                $current.PendingComputerRename | Should -BeFalse
                $current.CcmClientSDK | Should -BeFalse
                $current.RebootRequired | Should -BeTrue
                <#
                    The actual values assigned to the Skip* parameters
                    are not returned by Get-TargetResource because they
                    are set only (control) parameters, so can not be
                    evaluated except to check the default values.
                #>
                $current.SkipComponentBasedServicing | Should -BeFalse
                $current.SkipWindowsUpdate | Should -BeFalse
                $current.SkipPendingFileRename | Should -BeFalse
                $current.SkipPendingComputerRename | Should -BeFalse
                $current.SkipCcmClientSDK | Should -BeTrue
            }
        }
    }
}
finally
{
    if (-not $script:currentAutoUpdateRebootState)
    {
        $null = Remove-Item `
            -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired' `
            -ErrorAction SilentlyContinue
    }

    if ($script:currentPendingFileRenameState)
    {
        $null = Set-ItemProperty `
            -Path $script:rebootRegistryKeys.PendingFileRename `
            -Name PendingFileRenameOperations `
            -Value $script:currentPendingFileRenameState
    }

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
