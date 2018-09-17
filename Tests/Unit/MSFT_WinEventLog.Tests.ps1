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

    #Getting initial Value for Capi2 Log so we can test the ability to set Isenabled to False
        #and then set it back to its original value when we're done
        $Capi2Log = Get-WinEvent -ListLog 'Microsoft-Windows-CAPI2/Operational'
        if ($Capi2Log.IsEnabled)
        {
            $Capi2Log.IsEnabled = $false
            $Capi2Log.SaveChanges()
        }

        Describe "$($script:DSCResourceName)\Get-TargetResource" {

            Mock -ModuleName 'MSFT_WinEventLog' Get-WinEvent {
                $properties = @{
                    MaximumSizeInBytes = 4096kb
                    IsEnabled          = $true
                    LogMode            = 'Circular'
                    LogFilePath        = '%SystemRoot%\System32\Winevt\Logs\Application.evtx'
                    SecurityDescriptor = 'TestDescriptor'
                }

                Write-Output (New-Object -TypeName PSObject -Property $properties)
            }

            $results = Get-TargetResource 'Application'

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

            Mock -ModuleName 'MSFT_WinEventLog' Get-WinEvent {
                $properties = @{
                    LogName            = 'Application'
                    MaximumSizeInBytes = 2048kb
                    IsEnabled          = $true
                    LogMode            = 'Circular'
                    LogFilePath        = 'c:\logs\test.evtx'
                    SecurityDescriptor = 'TestDescriptor'
                }

                Write-Output (New-Object -TypeName PSObject -Property $properties)
            }

            $params = @{
                LogName            = 'Application'
                MaximumSizeInBytes = 2048kb
                LogMode            = 'Circular'
                IsEnabled          = $true
                LogFilePath        = 'c:\logs\test.evtx'
                SecurityDescriptor = 'TestDescriptor'
            }

            It 'should return true when all properties match does not match' {
                $testResults = Test-TargetResource @params
                $testResults | Should Be $True
            }

            It 'should return false when MaximumSizeInBytes does not match' {
                $testResults = Test-TargetResource -LogName 'Application' -MaximumSizeInBytes 4096kb -IsEnabled $true -SecurityDescriptor 'TestDescriptor' -LogMode 'Circular' -LogFilePath 'c:\logs\test.evtx'
                $testResults | Should Be $False
            }

            It 'should return false when LogMode does not match' {
                $testResults = Test-TargetResource -LogName 'Application' -MaximumSizeInBytes 2048kb -IsEnabled $true -SecurityDescriptor 'TestDescriptor' -LogMode 'Retain' -LogFilePath 'c:\logs\test.evtx'
                $testResults | Should Be $false
            }

            It 'should return false when IsEnabled does not match' {
                $testResults = Test-TargetResource -LogName 'Application' -MaximumSizeInBytes 2048kb -IsEnabled $false -SecurityDescriptor 'TestDescriptor' -LogMode 'Circular' -LogFilePath 'c:\logs\test.evtx'
                $testResults | Should Be $false
            }

            It 'Should return false when SecurityDescriptor does not match' {
                $testResults = Test-TargetResource -LogName 'Application' -MaximumSizeInBytes 2048kb -IsEnabled $true -SecurityDescriptor 'TestDescriptorFail' -LogMode 'Circular' -LogFilePath 'c:\logs\test.evtx'
                $testResults | Should Be $false
            }

            It 'Should return false when LogFilePath does not match' {
                $testResults = Test-TargetResource -LogName 'Application' -MaximumSizeInBytes 2048kb -IsEnabled $true -SecurityDescriptor 'TestDescriptor' -LogMode 'Circular' -LogFilePath 'c:\wronglogs\wrongfile.evtx'
                $testResults | Should Be $false
            }

            It 'Should call Get-WinEventLog' {
                Assert-MockCalled Get-WinEvent -ModuleName MSFT_WinEventLog -Exactly 6
            }
        }

        Describe "$($script:DSCResourceName)\Set-TargetResource" {
            BeforeAll {
                New-EventLog -LogName 'Pester' -Source 'PesterTest'
                $Log = Get-WinEvent -ListLog 'Pester'
                $Log.LogMode = 'Circular'
                $Log.SaveChanges()
                New-Item -Path "$env:SystemDrive\tmp" -ItemType Directory -Force | Out-Null
            }

            Context 'When set is called and actual value does not match expected value' {

                It 'Should update MaximumSizeInBytes' {
                    Set-TargetResource -LogName 'Pester' -MaximumSizeInBytes 4096kb -IsEnabled $true
                    (Get-WinEvent -ListLog 'Pester').MaximumSizeInBytes | Should Be 4096kb
                }

                It 'Should update the LogMode' {
                    Set-TargetResource -LogName 'Pester' -LogMode 'AutoBackup' -IsEnabled $true
                    (Get-WinEvent -ListLog 'Pester').LogMode | Should Be 'AutoBackup'
                }

                It 'Should update IsEnabled to false' {
                    Set-TargetResource -LogName 'Microsoft-Windows-CAPI2/Operational' -IsEnabled $false
                    (Get-WinEvent -ListLog 'Microsoft-Windows-CAPI2/Operational').IsEnabled | Should Be $false
                }

                It 'Should update SecurityDescriptor' {
                    Set-TargetResource -LogName 'Pester' -SecurityDescriptor 'O:BAG:SYD:(A;;0x7;;;BA)(A;;0x7;;;SO)(A;;0x3;;;IU)(A;;0x3;;;SU)(A;;0x3;;;S-1-5-3)(A;;0x3;;;S-1-5-33)(A;;0x1;;;S-1-5-32-573)' -IsEnabled $true
                    (Get-WinEvent -ListLog 'Pester').SecurityDescriptor = 'O:BAG:SYD:(A;;0x7;;;BA)(A;;0x7;;;SO)(A;;0x3;;;IU)(A;;0x3;;;SU)(A;;0x3;;;S-1-5-3)(A;;0x3;;;S-1-5-33)(A;;0x1;;;S-1-5-32-573)'
                }

                It 'Should update the LogFilePath' {
                    Set-TargetResource -LogName 'Pester' -LogFilePath 'c:\tmp\test.evtx' -IsEnabled $true
                    (Get-WinEvent -ListLog 'Pester').LogFilePath | Should Be 'c:\tmp\test.evtx'
                }
            }

            Mock -CommandName Set-MaximumSizeInBytes -ModuleName MSFT_WinEventLog -MockWith {
                return $true
            }

            Mock -CommandName Set-LogMode -ModuleName MSFT_WinEventLog -MockWith {
                return $true
            }

            Mock -CommandName Set-SecurityDescriptor -ModuleName MSFT_WinEventLog -MockWith {
                return $true
            }

            Mock -CommandName Set-IsEnabled -ModuleName MSFT_WinEventLog -MockWith {
                return $true
            }

            Mock -CommandName Set-LogFilePath -ModuleName MSFT_WinEventLog -MockWith {
                return $true
            }

            Context 'When desired value matches property' {

                $Log = Get-WinEvent -ListLog 'Pester'
                Set-TargetResource -LogName $Log.LogName -SecurityDescriptor $log.SecurityDescriptor -LogMode $log.LogMode -IsEnabled $log.IsEnabled

                It 'Should not call Set-MaximumSizeInBytes' {
                    Assert-MockCalled -CommandName Set-MaximumSizeInBytes -ModuleName MSFT_WinEventLog -Exactly 0
                }

                It 'Should not call Set-LogMode' {
                    Assert-MockCalled -CommandName Set-LogMode -ModuleName MSFT_WinEventLog -Exactly 0
                }

                It 'Should not call Set-SecurityDescriptor' {
                    Assert-MockCalled -CommandName Set-SecurityDescriptor -ModuleName MSFT_WinEventLog -Exactly 0
                }

                It 'Should not call Set-IsEnabled' {
                    Assert-MockCalled -CommandName Set-IsEnabled -ModuleName MSFT_WinEventLog -Exactly 0
                }

                It 'Should not call Set-LogFilePath' {
                    Assert-MockCalled -CommandName Set-LogFilePath -ModuleName MSFT_WinEventLog -Exactly 0
                }
            }

            AfterAll {
                Remove-EventLog -LogName 'Pester'
                $log = Get-WinEvent -ListLog 'Microsoft-Windows-CAPI2/Operational'
                $log.IsEnabled = $Capi2Log.IsEnabled
                $log.SaveChanges()
                Remove-Item -Path "$env:SystemDrive\tmp" -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
