$script:dscModuleName = 'ComputerManagementDsc'
$script:dscResourceName = 'DSC_PowershellExecutionPolicy'

function Invoke-TestSetup
{
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
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

# Begin Testing
try
{
    InModuleScope $script:dscResourceName {
        $Script:invalidPolicyThrowMessage = "Cannot validate argument on parameter 'ExecutionPolicy'. The argument `"badParam`" does not belong to the set `"Bypass,Restricted,AllSigned,RemoteSigned,Unrestricted`" specified by the ValidateSet attribute. Supply an argument that is in the set and then try the command again."

        $Script:invalidPolicyExecutionPolicyScopeThrowMessage = "Cannot validate argument on parameter 'ExecutionPolicyScope'. The argument `"badParam`" does not belong to the set `"CurrentUser,LocalMachine,MachinePolicy,Process,UserPolicy`" specified by the ValidateSet attribute. Supply an argument that is in the set and then try the command again."

        Describe 'DSC_PowershellExecutionPolicy\Get-TargetResource' {
            It 'Throws when passed an invalid execution policy' {
                { Get-TargetResource -ExecutionPolicy 'badParam' -Scope 'LocalMachine' } | Should -Throw $Script:invalidPolicyThrowMessage
            }

            It 'Returns correct execution policy' {
                Mock Get-ExecutionPolicy { 'Unrestricted' }
                $result = Get-TargetResource -ExecutionPolicy $(Get-ExecutionPolicy) -ExecutionPolicyScope 'LocalMachine'
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

        Describe 'DSC_PowershellExecutionPolicy\Test-TargetResource' {
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

        Describe 'DSC_PowershellExecutionPolicy\Set-TargetResource' {
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
    }
}
finally
{
    Invoke-TestCleanup
}
