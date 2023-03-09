<#
    .SYNOPSIS
        Unit test for PSResourceRepository DSC resource.
#>

# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

try
{
    if (-not (Get-Module -Name 'DscResource.Test'))
    {
        # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
        if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
        {
            # Redirect all streams to $null, except the error stream (stream 2)
            & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
        }

        # If the dependencies has not been resolved, this will throw an error.
        Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
    }
}
catch [System.IO.FileNotFoundException]
{
    throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
}

try
{
    $script:dscModuleName = 'ComputerManagementDsc'

    Import-Module -Name $script:dscModuleName

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName

    Describe 'CMReason' -Tag 'CMReason' {
        Context 'When instantiating the class' {
            It 'Should not throw an error' {
                $script:mockCMReasonInstance = InModuleScope -ScriptBlock {
                    [CMReason]::new()
                }
            }

            It 'Should be of the correct type' {
                $mockCMReasonInstance | Should -Not -BeNullOrEmpty
                $mockCMReasonInstance.GetType().Name | Should -Be 'CMReason'
            }
        }

        Context 'When setting and reading values' {
            It 'Should be able to set value in instance' {
                $script:mockCMReasonInstance = InModuleScope -ScriptBlock {
                    $CMReasonInstance = [CMReason]::new()

                    $CMReasonInstance.Code = 'SqlAudit:SqlAudit:Ensure'
                    $CMReasonInstance.Phrase = 'The property Ensure should be "Present", but was "Absent"'

                    return $CMReasonInstance
                }
            }

            It 'Should be able read the values from instance' {
                $mockCMReasonInstance.Code | Should -Be 'SqlAudit:SqlAudit:Ensure'
                $mockCMReasonInstance.Phrase = 'The property Ensure should be "Present", but was "Absent"'
            }
        }
    }
}
finally
{
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}
