#region HEADER
$script:projectPath = "$PSScriptRoot\..\.." | Convert-Path
$script:projectName = (Get-ChildItem -Path "$script:projectPath\*\*.psd1" | Where-Object -FilterScript {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try
            { Test-ModuleManifest -Path $_.FullName -ErrorAction Stop
            }
            catch
            { $false
            })
    }).BaseName

$script:parentModule = Get-Module -Name $script:projectName -ListAvailable | Select-Object -First 1
$script:subModulesFolder = Join-Path -Path $script:parentModule.ModuleBase -ChildPath 'Modules'
Remove-Module -Name $script:parentModule -Force -ErrorAction 'SilentlyContinue'

$script:subModuleName = (Split-Path -Path $PSCommandPath -Leaf) -replace '\.Tests.ps1'
$script:subModuleFile = Join-Path -Path $script:subModulesFolder -ChildPath "$($script:subModuleName)/$($script:subModuleName).psm1"

Import-Module $script:subModuleFile -Force -ErrorAction Stop
#endregion HEADER

# Store the test machine timezone
$currentTimeZone = & tzutil.exe /g

# Change the current timezone so that a complete test occurs.
tzutil.exe /s 'Eastern Standard Time'

# Using try/finally to always cleanup even if something awful happens.
try
{
    InModuleScope $script:subModuleName {
        Describe 'ComputerManagementDsc.Common\Set-TimeZoneId' {
            <#
                The purpose of this test is to ensure the C# .NET code
                that is used to set the time zone if the Set-TimeZone
                cmdlet is not available but the Add-Type cmdlet is available

                The other conditions can be effectively tested with
                the unit tests, but the only way to test the C# .NET code
                is to execute it without mocking. This results in
                a destrutive change which is only allowed within the
                integration tests.
            #>
            Context '"Set-TimeZone" is not available but "Add-Type" is available' {
                Mock `
                    -CommandName Get-Command `
                    -ParameterFilter {
                    $Name -eq 'Add-Type'
                } -MockWith {
                    'Add-Type'
                }

                Mock `
                    -CommandName Get-Command `
                    -ParameterFilter {
                    $Name -eq 'Set-TimeZone'
                }

                Mock -CommandName 'TzUtil.exe' -MockWith {
                    $Script:LASTEXITCODE = 0
                    return 'OK'
                }

                It 'Should not throw an exception' {
                    { Set-TimeZoneId -TimezoneId 'Eastern Standard Time' } | Should -Not -Throw
                }

                It 'Should have set the time zone to Eastern Standard Time' {
                    Get-TimeZoneId | Should -Be 'Eastern Standard Time'
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled `
                        -CommandName Get-Command `
                        -ParameterFilter {
                        $Name -eq 'Add-Type'
                    } -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-Command `
                        -ParameterFilter {
                        $Name -eq 'Set-TimeZone'
                    } -Exactly -Times 1

                    Assert-MockCalled -CommandName TzUtil.exe -Exactly -Times 0
                }
            }
        }
    }
}
finally
{
    # Restore the test machine timezone
    & tzutil.exe /s $CurrentTimeZone
}
