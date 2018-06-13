$repoRoot = Split-Path -Path (Split-Path -Path $Script:MyInvocation.MyCommand.Path)
$dscResourceTestsPath = Join-Path -Path $repoRoot -ChildPath '\Modules\ComputerManagementDsc\DSCResource.Tests\'

if ((-not (Test-Path -Path $dscResourceTestsPath)) -or `
    (-not (Test-Path -Path (Join-Path -Path $dscResourceTestsPath -ChildPath 'TestHelper.psm1'))))
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', $dscResourceTestsPath)
}

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\Tests\TestHarness.psm1' -Resolve)
$dscTestsPath = Join-Path -Path $dscResourceTestsPath -ChildPath 'Meta.Tests.ps1'
Invoke-TestHarness -DscTestsPath $dscTestsPath
