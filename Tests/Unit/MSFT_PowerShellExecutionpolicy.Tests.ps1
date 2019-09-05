#region HEADER
$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'MSFT_PowershellExecutionPolicy'

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

$Script:invalidPolicyThrowMessage = @"
Cannot validate argument on parameter 'ExecutionPolicy'. The argument `"badParam`" does
not belong to the set `"Bypass,Restricted,AllSigned,RemoteSigned,Unrestricted`"
specified by the ValidateSet attribute. Supply an argument that is in the set and then
try the command again.
"@

$Script:invalidPolicyExecutionPolicyScopeThrowMessage = @"
Cannot validate argument on parameter 'ExecutionPolicyScope'. The argument `"badParam`"
does not belong to the set `"CurrentUser,LocalMachine,MachinePolicy,Process,UserPolicy`"
specified by the ValidateSet attribute. Supply an argument that is in the set and then
try the command again.
"@

# Begin Testing
try
{
    <#
        The InModuleScope command allows you to perform white-box unit testing on the internal
        (non-exported) code of a Script Module.
    #>
    InModuleScope $script:dscResourceName {
        $script:dscResourceName = 'MSFT_PowershellExecutionPolicy'

        #region Function Get-TargetResource
        Describe "$($script:dscResourceName)\Get-TargetResource" {

            It 'Throws when passed an invalid execution policy' {
                { Get-TargetResource -ExecutionPolicy 'badParam' -Scope 'LocalMachine' } | Should -Throw $Script:invalidPolicyThrowMessage
            }

            It 'Returns correct execution policy' {
                Mock Get-ExecutionPolicy { 'Unrestricted' }
                $result = Get-TargetResource -ExecutionPolicy $(Get-ExecutionPolicy ) -ExecutionPolicyScope 'LocalMachine'
                $result.ExecutionPolicy | Should -Be $(Get-ExecutionPolicy)
            }

            It 'Throws when passed an invalid execution policy ExecutionPolicyScope' {
                { Get-TargetResource -ExecutionPolicy $(Get-ExecutionPolicy) -ExecutionPolicyScope "badParam" } | Should -Throw $Script:invalidPolicyExecutionPolicyScopeThrowMessage
            }

            It 'Returns correct execution policy for the correct ExecutionPolicyScope' {
                $result = Get-TargetResource -ExecutionPolicy $(Get-ExecutionPolicy -Scope  'LocalMachine') -ExecutionPolicyScope  'LocalMachine'
                $result.ExecutionPolicy | Should -Be $(Get-ExecutionPolicy -Scope 'LocalMachine')
                $result.ExecutionPolicyScope | Should -Be 'LocalMachine'
            }
        }
        #endregion

        #region Function Test-TargetResource
        Describe "$($script:dscResourceName)\Test-TargetResource" {

            It 'Throws when passed an invalid execution policy' {
                { Test-TargetResource -ExecutionPolicy 'badParam' -Scope 'LocalMachine' } | Should -Throw $Script:invalidPolicyThrowMessage
            }

            It 'Returns true when current policy matches desired policy' {
                Mock Get-ExecutionPolicy { 'Unrestricted' }
                Test-TargetResource -ExecutionPolicy $(Get-ExecutionPolicy)  -ExecutionPolicyScope 'LocalMachine' | Should -BeTrue
            }

            It 'Returns false when current policy does not match desired policy' {
                Mock -CommandName Get-ExecutionPolicy -MockWith { 'Restricted' }
                Test-TargetResource -ExecutionPolicy 'Bypass' -ExecutionPolicyScope 'LocalMachine' | Should -BeFalse
            }

            It 'Throws when passed an invalid execution policy Scope' {
                { Test-TargetResource -ExecutionPolicy 'badParam' } | Should -Throw $Script:invalidPolicyThrowMessage
            }

            It 'Returns true when current policy matches desired policy with correct Scope' {
                Test-TargetResource -ExecutionPolicy $(Get-ExecutionPolicy)  -ExecutionPolicyScope 'LocalMachine' | Should -BeTrue
            }

            It 'Returns false when current policy does not match desired policy with correct ExecutionPolicyScope' {
                Mock -CommandName Get-ExecutionPolicy -MockWith { 'Restricted' }
                Test-TargetResource -ExecutionPolicy 'Bypass' -ExecutionPolicyScope 'LocalMachine' | Should -BeFalse
            }
        }
        #endregion

        #region Function Set-TargetResource
        Describe "$script:dscResourceName\Set-TargetResource" {

            It 'Throws when passed an invalid execution policy' {
                { Set-TargetResource -ExecutionPolicy 'badParam' -Scope 'LocalMachine' } | Should -Throw $Script:invalidPolicyThrowMessage
            }

            It 'Throws when passed an invalid scope level' {
                { Set-TargetResource -ExecutionPolicy 'LocalMachine' -ExecutionPolicyScope 'badParam' } | Should -Throw $Script:invalidScopeThrowMessage
            }

            It 'Catches execution policy scope warning exception' {
                Mock -CommandName Set-ExecutionPolicy -MockWith { Throw 'ExecutionPolicyOverride,Microsoft.PowerShell.Commands.SetExecutionPolicyCommand' }
                $result = Set-TargetResource -ExecutionPolicy 'Bypass' -ExecutionPolicyScope 'LocalMachine'
                $result | Should -Be $null
            }

            It 'Throws non-caught exceptions' {
                Mock -CommandName Set-ExecutionPolicy -MockWith { Throw 'Throw me!' }
                { Set-TargetResource -ExecutionPolicy 'Bypass' -ExecutionPolicyScope 'LocalMachine' } | Should -Throw 'Throw me!'
            }

            It 'Sets execution policy' {
                Mock -CommandName Set-ExecutionPolicy -MockWith { }
                Set-TargetResource -ExecutionPolicy 'Bypass' -ExecutionPolicyScope 'LocalMachine'
                Assert-MockCalled -CommandName Set-ExecutionPolicy -Exactly 1 -Scope It
            }

            It 'Sets execution policy in specified Scope' {
                Mock -CommandName Set-ExecutionPolicy -MockWith { }
                Set-TargetResource -ExecutionPolicy 'Bypass' -ExecutionPolicyScope 'LocalMachine'
                Assert-MockCalled -CommandName Set-ExecutionPolicy -Exactly 1 -Scope It
            }
        }
        #endregion
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}
