<#
    .SYNOPSIS
        Unit test for DSC_Computer DSC resource.

    .NOTES
#>

# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
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
}

BeforeAll {
    $script:dscModuleName = 'ComputerManagementDsc'
    $script:dscResourceName = 'DSC_Computer'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName

    # A real password isn't needed here - use this next line to avoid triggering PSSA rule
    $securePassword = New-Object -Type SecureString
    $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'USER', $securePassword
    $notComputerName = if ($env:COMPUTERNAME -ne 'othername')
    {
        'othername'
    }
    else
    {
        'name'
    }

    InModuleScope -Parameters @{
        credential = $credential
    } -ScriptBlock {
        $script:credential = $credential
    }
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force
}

Describe 'DSC_Computer\Test-TargetResource' {
    BeforeAll {
        Mock -CommandName Get-WMIObject -MockWith {
            [PSCustomObject] @{
                DomainName = 'ContosoLtd'
            }
        } -ParameterFilter {
            $Class -eq 'Win32_NTDomain'
        }
    }

    Context 'When both DomainName and WorkGroupName are specified' {
        It 'Should throw correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($LocalizedData.DomainNameAndWorkgroupNameError)

                $testTargetParams = @{
                    Name          = $env:COMPUTERNAME
                    DomainName    = 'contoso.com'
                    WorkGroupName = 'workgroup'
                }

                { Test-TargetResource @testTargetParams } | Should -Throw -ExpectedMessage $errorRecord
            }
        }
    }

    Context 'When Domain is specified without Credentials' {
        It 'Should throw correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($LocalizedData.CredentialsNotSpecifiedError) `
                    -ArgumentName 'Credentials'

                $testTargetParams = @{
                    Name       = $env:COMPUTERNAME
                    DomainName = 'contoso.com'
                }

                { Test-TargetResource @testTargetParams } | Should -Throw -ExpectedMessage $errorRecord
            }
        }
    }

    Context 'When Domain name is same as specified' {
        BeforeAll {
            Mock -CommandName Get-WMIObject -MockWith {
                [PSCustomObject] @{
                    Domain       = 'Contoso.com';
                    Workgroup    = 'Contoso.com';
                    PartOfDomain = $true
                }
            }

            Mock -CommandName Get-ComputerDomain -MockWith {
                'contoso.com'
            }
        }
        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetParams = @{
                    Name       = $env:COMPUTERNAME
                    DomainName = 'Contoso.com'
                    Credential = $credential
                }

                Test-TargetResource @testTargetParams | Should -BeTrue
            }
        }
    }

    Context 'When Workgroup name is same as specified' {
        BeforeAll {
            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    Domain       = 'Workgroup';
                    Workgroup    = 'Workgroup';
                    PartOfDomain = $false
                }
            }

            Mock -CommandName Get-ComputerDomain -MockWith {
                ''
            }
        }

        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetParams = @{
                    Name          = $env:COMPUTERNAME
                    WorkGroupName = 'workgroup'
                }

                Test-TargetResource @testTargetParams | Should -BeTrue
            }
        }
    }

    Context 'When ComputerName and Domain name is same as specified' {
        BeforeAll {
            Mock -CommandName Get-WMIObject -MockWith {
                [PSCustomObject] @{
                    Domain       = 'Contoso.com';
                    Workgroup    = 'Contoso.com';
                    PartOfDomain = $true
                }
            }

            Mock -CommandName Get-ComputerDomain -MockWith {
                'contoso.com'
            }
        }

        BeforeDiscovery {
            $testCases = @(
                @{ Name = $env:COMPUTERNAME }
                @{ Name = 'localhost' }
            )
        }

        It 'Should return $true when ''Name'' is <Name>' -ForEach $testCases {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetParams = @{
                    Name       = $Name
                    DomainName = 'contoso.com'
                    Credential = $credential
                }

                Test-TargetResource @testTargetParams | Should -BeTrue
            }
        }
    }

    Context 'When ComputerName and Workgroup is same as specified' {
        BeforeAll {
            Mock -CommandName Get-WMIObject -MockWith {
                [PSCustomObject] @{
                    Domain       = 'Workgroup';
                    Workgroup    = 'Workgroup';
                    PartOfDomain = $false
                }
            }

            Mock -CommandName Get-ComputerDomain -MockWith {
                ''
            }
        }

        BeforeDiscovery {
            $testCases = @(
                @{ Name = $env:COMPUTERNAME }
                @{ Name = 'localhost' }
            )
        }

        It 'Should return $true when ''Name'' is <Name>' -ForEach $testCases {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetParams = @{
                    Name          = $Name
                    WorkGroupName = 'workgroup'
                }

                Test-TargetResource @testTargetParams | Should -BeTrue
            }
        }
    }

    Context 'When ComputerName is the same and no Domain or Workgroup specified' {
        Context 'When no Domain Specified' {
            BeforeAll {
                Mock -CommandName Get-WmiObject {
                    [PSCustomObject] @{
                        Domain       = 'Contoso.com';
                        Workgroup    = 'Contoso.com';
                        PartOfDomain = $true
                    }
                }

                Mock -CommandName Get-ComputerDomain -MockWith {
                    'contoso.com'
                }
            }

            BeforeDiscovery {
                $testCases = @(
                    @{ Name = $env:COMPUTERNAME }
                    @{ Name = 'localhost' }
                )
            }

            It 'Should return $true when ''Name'' is <Name>' -ForEach $testCases {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetParams = @{
                        Name = $Name
                    }

                    Test-TargetResource @testTargetParams | Should -BeTrue
                }
            }
        }

        Context 'When no Workgroup specified' {
            BeforeAll {
                Mock -CommandName Get-WmiObject -MockWith {
                    [PSCustomObject] @{
                        Domain       = 'Workgroup';
                        Workgroup    = 'Workgroup';
                        PartOfDomain = $false
                    }
                }

                Mock -CommandName Get-ComputerDomain -MockWith {
                    ''
                }
            }

            BeforeDiscovery {
                $testCases = @(
                    @{ Name = $env:COMPUTERNAME }
                    @{ Name = 'localhost' }
                )
            }

            It 'Should return $true when ''Name'' is <Name>' -ForEach $testCases {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetParams = @{
                        Name = $Name
                    }

                    Test-TargetResource @testTargetParams | Should -BeTrue
                }
            }
        }
    }

    Context 'When ComputerName is not same and no Domain or Workgroup specified' {
        Context 'When no workgroup specified' {
            BeforeAll {
                Mock -CommandName Get-WmiObject -MockWith {
                    [PSCustomObject] @{
                        Domain       = 'Workgroup';
                        Workgroup    = 'Workgroup';
                        PartOfDomain = $false
                    }
                }

                Mock -CommandName Get-ComputerDomain -MockWith {
                    ''
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetParams = @{
                        Name = 'otherName'
                    }

                    Test-TargetResource @testTargetParams | Should -BeFalse
                }
            }

            Context 'When no domain specified' {
                BeforeAll {
                    Mock -CommandName Get-WmiObject -MockWith {
                        [PSCustomObject] @{
                            Domain       = 'Contoso.com';
                            Workgroup    = 'Contoso.com';
                            PartOfDomain = $true
                        }
                    }

                    Mock -CommandName Get-ComputerDomain -MockWith {
                        'contoso.com'
                    }
                }

                It 'Should return $false' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $testTargetParams = @{
                            Name = 'otherName'
                        }

                        Test-TargetResource @testTargetParams | Should -BeFalse
                    }
                }
            }
        }
    }

    Context 'When Domain name is not same as specified' {
        BeforeAll {
            Mock -CommandName Get-WMIObject {
                [PSCustomObject] @{
                    Domain       = 'Contoso.com';
                    Workgroup    = 'Contoso.com';
                    PartOfDomain = $true
                }
            }

            Mock -CommandName Get-ComputerDomain -MockWith {
                'contoso.com'
            }
        }

        BeforeDiscovery {
            $testCases = @(
                @{ Name = $env:COMPUTERNAME }
                @{ Name = 'localhost' }
            )
        }

        It 'Should return $false when ''Name'' is <Name>' -ForEach $testCases {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetParams = @{
                    Name       = $Name
                    DomainName = 'adventure-works.com'
                    Credential = $credential
                }

                Test-TargetResource @testTargetParams | Should -BeFalse
            }
        }
    }

    Context 'When Workgroup name is not same as specified' {
        BeforeAll {
            Mock -CommandName Get-WMIObject -MockWith {
                [PSCustomObject] @{
                    Domain       = 'Workgroup';
                    Workgroup    = 'Workgroup';
                    PartOfDomain = $false
                }
            }

            Mock -CommandName Get-ComputerDomain -MockWith {
                ''
            }
        }

        BeforeDiscovery {
            $testCases = @(
                @{ Name = $env:COMPUTERNAME }
                @{ Name = 'localhost' }
            )
        }

        It 'Should return $false when ''Name'' is <Name>' -ForEach $testCases {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetParams = @{
                    Name          = $Name
                    WorkGroupName = 'NOTworkgroup'
                }

                Test-TargetResource @testTargetParams | Should -BeFalse
            }
        }
    }

    Context 'When ComputerName is not same as specified' {
        Context 'When workgroup is specified' {
            BeforeAll {
                Mock -CommandName Get-WMIObject -MockWith {
                    [PSCustomObject] @{
                        Domain       = 'Workgroup';
                        Workgroup    = 'Workgroup';
                        PartOfDomain = $false
                    }
                }

                Mock -CommandName Get-ComputerDomain -MockWith {
                    ''
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetParams = @{
                        Name          = 'otherName'
                        WorkGroupName = 'workgroup'
                    }

                    Test-TargetResource @testTargetParams | Should -BeFalse
                }
            }
        }

        Context 'When domain is specified' {
            BeforeAll {
                Mock -CommandName Get-WMIObject -MockWith {
                    [PSCustomObject] @{
                        Domain       = 'Contoso.com';
                        Workgroup    = 'Contoso.com';
                        PartOfDomain = $true
                    }
                }

                Mock -CommandName Get-ComputerDomain -MockWith {
                    'contoso.com'
                }
            }
            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetParams = @{
                        Name       = 'otherName'
                        DomainName = 'contoso.com'
                        credential = $credential
                    }

                    Test-TargetResource @testTargetParams | Should -BeFalse
                }
            }
        }
    }

    Context 'When Computer is in Workgroup and Domain is specified' {
        BeforeAll {
            Mock -CommandName Get-WMIObject {
                [PSCustomObject] @{
                    Domain       = 'Contoso.com';
                    Workgroup    = 'Contoso.com';
                    PartOfDomain = $false
                }
            }

            Mock -CommandName Get-ComputerDomain -MockWith {
                ''
            }
        }

        BeforeDiscovery {
            $testCases = @(
                @{ Name = $env:COMPUTERNAME }
                @{ Name = 'localhost' }
            )
        }

        It 'Should return $false when ''Name'' is <Name>' -ForEach $testCases {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetParams = @{
                    Name       = $Name
                    DomainName = 'contoso.com'
                    Credential = $credential
                }

                Test-TargetResource @testTargetParams | Should -BeFalse
            }
        }
    }

    Context 'When ComputerName is in Domain and Workgroup is specified' {
        BeforeAll {
            Mock -CommandName Get-WMIObject {
                [PSCustomObject] @{
                    Domain       = 'Contoso.com';
                    Workgroup    = 'Contoso.com';
                    PartOfDomain = $true
                }
            }

            Mock -CommandName Get-ComputerDomain -MockWith {
                'contoso.com'
            }
        }

        BeforeDiscovery {
            $testCases = @(
                @{ Name = $env:COMPUTERNAME }
                @{ Name = 'localhost' }
            )
        }

        It 'Should return $false when ''Name'' is <Name>' -ForEach $testCases {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetParams = @{
                    Name             = $Name
                    WorkGroupName    = 'Contoso'
                    Credential       = $credential
                    UnjoinCredential = $credential
                }

                Test-TargetResource @testTargetParams | Should -BeFalse
            }
        }
    }

    Context 'When ''Name'' is invalid' {
        BeforeDiscovery {
            $testCases = @(
                @{
                    Name        = 'ThisNameIsTooLong'
                    Description = 'is too long'
                }
                @{
                    Name        = 'ThisIsBad<>'
                    Description = 'contains illegal characters'
                }
            )
        }

        It 'Should throw when ''Name'' <Description>' -ForEach $testCases {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetParams = @{
                    Name = $Name
                }

                { Test-TargetResource @testTargetParams } | Should -Throw
            }
        }

        It 'Should not throw when ''Name'' is localhost' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetParams = @{
                    Name = 'localhost'
                }

                { Test-TargetResource @testTargetParams } | Should -Not -Throw
            }
        }
    }

    Context 'When description is same as specified' {
        BeforeAll {
            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    Description = 'This is my computer'
                }
            }
        }

        BeforeDiscovery {
            $testCases = @(
                @{ Name = $env:COMPUTERNAME }
                @{ Name = 'localhost' }
            )
        }

        It 'Should return $true when Name is ''<Name>''' -ForEach $testCases {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetParams = @{
                    Name        = $Name
                    Description = 'This is my computer'
                }

                Test-TargetResource @testTargetParams | Should -BeTrue
            }
        }
    }

    Context 'When description is not as specified' {
        BeforeAll {
            Mock -CommandName Get-CimInstance -MockWith {
                [PSCustomObject] @{
                    Description = 'This is not my computer'
                }
            }
        }

        BeforeEach {
            $testCases = @(
                @{ Name = $env:COMPUTERNAME }
                @{ Name = 'localhost' }
            )
        }

        It 'Should return $false when Name is ''<Name>''' -ForEach $testCases {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testTargetParams = @{
                    Name        = $Name
                    Description = 'This is my computer'
                }

                Test-TargetResource @testTargetParams | Should -BeFalse
            }
        }
    }
}

Describe 'DSC_Computer\Get-TargetResource' {
    Context 'When getting the resource' {
        It 'Should not throw' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getTargetParams = @{
                    Name = $env:COMPUTERNAME
                }

                { Get-TargetResource @getTargetParams } | Should -Not -Throw
            }
        }

        It 'Should return a hashtable containing Name, DomainName, JoinOU, CurrentOU, Credential, UnjoinCredential, WorkGroupName and Description' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getTargetParams = @{
                    Name = $env:COMPUTERNAME
                }

                $result = Get-TargetResource @getTargetParams

                $result.GetType().Fullname | Should -Be 'System.Collections.Hashtable'
                $result.Keys | Sort-Object | Should -Be @('Credential', 'CurrentOU', 'Description', 'DomainName', 'JoinOU', 'Name', 'Server', 'UnjoinCredential', 'WorkGroupName')
            }
        }
    }

    Context 'When name is too long' {
        It 'Should throw exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getTargetParams = @{
                    Name = 'ThisNameIsTooLong'
                }

                { Get-TargetResource @getTargetParams } | Should -Throw
            }
        }
    }

    Context 'When name contains illegal characters' {
        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getTargetParams = @{
                    Name = 'ThisIsBad<>'
                }

                { Get-TargetResource @getTargetParams } | Should -Throw
            }
        }
    }
}

Describe 'DSC_Computer\Set-TargetResource' {
    BeforeAll {
        Mock -CommandName Rename-Computer
        Mock -CommandName Set-CimInstance
        Mock -CommandName Get-ADSIComputer
        Mock -CommandName Remove-ADSIObject
    }

    Context 'When both DomainName and WorkGroupName are specified' {
        BeforeAll {
            Mock -CommandName Add-Computer
        }

        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($LocalizedData.DomainNameAndWorkgroupNameError)

                $setTargetParams = @{
                    Name          = $env:COMPUTERNAME
                    DomainName    = 'contoso.com'
                    WorkGroupName = 'workgroup'
                }

                { Set-TargetResource @setTargetParams } | Should -Throw $errorRecord
            }

            Should -Invoke -CommandName Rename-Computer -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Add-Computer -Exactly -Times 0 -Scope It
        }
    }

    Context 'When Domain is specified without Credentials' {
        BeforeAll {
            Mock -CommandName Add-Computer
        }

        It 'Should throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($LocalizedData.CredentialsNotSpecifiedError) `
                    -ArgumentName 'Credentials'

                $setTargetParams = @{
                    Name       = $env:COMPUTERNAME
                    DomainName = 'contoso.com'
                }

                { Set-TargetResource @setTargetParams } | Should -Throw $errorRecord
            }

            Should -Invoke -CommandName Rename-Computer -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Add-Computer -Exactly -Times 0 -Scope It
        }
    }

    Context 'Changes ComputerName and changes Domain to new Domain' {
        BeforeAll {
            Mock -CommandName Get-WMIObject -MockWith {
                [PSCustomObject] @{
                    Domain       = 'Contoso.com';
                    Workgroup    = 'Contoso.com';
                    PartOfDomain = $true
                }
            }

            Mock -CommandName Get-ADSIComputer -MockWith {
                [PSCustomObject] @{
                    Path = 'LDAP://Contoso.com/CN=mocked-comp,OU=Computers,DC=Contoso,DC=com';
                }
            }

            Mock -CommandName Get-ComputerDomain -MockWith {
                'contoso.com'
            }

            Mock -CommandName Add-Computer
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetParams = @{
                    Name             = 'othername'
                    DomainName       = 'adventure-works.com'
                    Credential       = $credential
                    UnjoinCredential = $credential
                }

                Set-TargetResource @setTargetParams | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Rename-Computer -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName -and $NewName }
            Should -Invoke -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $WorkGroupName }
            Should -Invoke -CommandName Get-ADSIComputer -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Remove-ADSIObject -Exactly -Times 1 -Scope It
        }
    }

    Context 'When ComputerName changes and Domain changes to new Domain with specified OU' {
        BeforeAll {
            Mock -CommandName Get-WMIObject -MockWith {
                [PSCustomObject] @{
                    Domain       = 'Contoso.com';
                    Workgroup    = 'Contoso.com';
                    PartOfDomain = $true
                }
            }

            Mock -CommandName Get-ComputerDomain -MockWith {
                'contoso.com'
            }

            Mock -CommandName Get-ADSIComputer -MockWith {
                [PSCustomObject] @{
                    Path = 'LDAP://Contoso.com/CN=mocked-comp,OU=Computers,DC=Contoso,DC=com';
                }
            }

            Mock -CommandName Add-Computer
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetParams = @{
                    Name             = 'othername'
                    DomainName       = 'adventure-works.com'
                    JoinOU           = 'OU=Computers,DC=contoso,DC=com'
                    Credential       = $credential
                    UnjoinCredential = $credential
                }

                Set-TargetResource @setTargetParams | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Rename-Computer -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName -and $NewName }
            Should -Invoke -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $WorkGroupName }
            Should -Invoke -CommandName Get-ADSIComputer -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Remove-ADSIObject -Exactly -Times 1 -Scope It
        }
    }

    Context 'When ComputerName changes and Domain changes to Workgroup' {
        BeforeAll {
            Mock -CommandName Get-WMIObject -MockWith {
                [PSCustomObject] @{
                    Domain       = 'Contoso.com';
                    Workgroup    = 'Contoso.com';
                    PartOfDomain = $true
                }
            }

            Mock -CommandName Get-ComputerDomain -MockWith {
                'contoso.com'
            }

            Mock -CommandName Add-Computer
        }

        It 'Should return correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetParams = @{
                    Name          = 'othername'
                    WorkGroupName = 'contoso'
                    Credential    = $credential
                }

                Set-TargetResource @setTargetParams | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Rename-Computer -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $WorkGroupName -and $NewName -and $credential }
            Should -Invoke -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $DomainName -or $UnjoinCredential }
        }
    }

    Context 'When ComputerName changes and Workgroup changes to Domain' {
        BeforeAll {
            Mock -CommandName Get-WMIObject -MockWith {
                [PSCustomObject] @{
                    Domain       = 'Contoso';
                    Workgroup    = 'Contoso';
                    PartOfDomain = $false
                }
            }

            Mock -CommandName Get-ADSIComputer -MockWith {
                [PSCustomObject] @{
                    Path = 'LDAP://Contoso.com/CN=mocked-comp,OU=Computers,DC=Contoso,DC=com';
                }
            }

            Mock -CommandName Get-ComputerDomain -MockWith {
                ''
            }

            Mock -CommandName Add-Computer
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetParams = @{
                    Name       = 'othername'
                    DomainName = 'Contoso.com'
                    Credential = $credential
                }

                Set-TargetResource @setTargetParams | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Rename-Computer -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName -and $NewName }
            Should -Invoke -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $WorkGroupName }
            Should -Invoke -CommandName Get-ADSIComputer -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Remove-ADSIObject -Exactly -Times 1 -Scope It
        }
    }

    Context 'When ComputerName changes and Workgroup changes to Domain with specified Domain Controller' {
        BeforeAll {
            Mock -CommandName Get-WMIObject -MockWith {
                [PSCustomObject] @{
                    Domain       = 'Contoso';
                    Workgroup    = 'Contoso';
                    PartOfDomain = $false
                }
            }

            Mock -CommandName Get-ADSIComputer -MockWith {
                [PSCustomObject] @{
                    Path = 'LDAP://Contoso.com/CN=mocked-comp,OU=Computers,DC=Contoso,DC=com';
                }
            }

            Mock -CommandName Get-ComputerDomain -MockWith {
                ''
            }

            Mock -CommandName Add-Computer
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetParams = @{
                    Name       = 'othername'
                    DomainName = 'Contoso.com'
                    Server     = 'dc01.contoso.com'
                    Credential = $credential
                }

                Set-TargetResource @setTargetParams | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Rename-Computer -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName -and $NewName -and $Server }
            Should -Invoke -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $WorkGroupName }
            Should -Invoke -CommandName Get-ADSIComputer -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Remove-ADSIObject -Exactly -Times 1 -Scope It
        }
    }

    Context 'When ComputerName changes and Workgroup changes to Domain with specified OU' {
        BeforeAll {
            Mock -CommandName Get-WMIObject -MockWith {
                [PSCustomObject] @{
                    Domain       = 'Contoso';
                    Workgroup    = 'Contoso';
                    PartOfDomain = $false
                }
            }

            Mock -CommandName Get-ADSIComputer -MockWith {
                [PSCustomObject] @{
                    Path = 'LDAP://Contoso.com/CN=mocked-comp,OU=Computers,DC=Contoso,DC=com';
                }
            }

            Mock -CommandName Get-ComputerDomain -MockWith {
                ''
            }

            Mock -CommandName Add-Computer
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetParams = @{
                    Name       = 'othername'
                    DomainName = 'Contoso.com'
                    JoinOU     = 'OU=Computers,DC=contoso,DC=com'
                    Credential = $credential
                }

                Set-TargetResource @setTargetParams | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Rename-Computer -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName -and $NewName }
            Should -Invoke -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $WorkGroupName }
            Should -Invoke -CommandName Get-ADSIComputer -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Remove-ADSIObject -Exactly -Times 1 -Scope It
        }
    }

    Context 'When ComputerName changes and Domain changes to new Domain with Options passed' {
        BeforeAll {
            Mock -CommandName Get-WMIObject -MockWith {
                [PSCustomObject] @{
                    Domain       = 'Contoso.com';
                    Workgroup    = 'Contoso.com';
                    PartOfDomain = $true
                }
            }

            Mock -CommandName Get-ComputerDomain -MockWith {
                'contoso.com'
            }

            Mock -CommandName Add-Computer
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetParams = @{
                    Name             = 'othername'
                    DomainName       = 'adventure-works.com'
                    Credential       = $credential
                    UnjoinCredential = $credential
                    Options          = @('InstallInvoke')
                }

                Set-TargetResource @setTargetParams | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Rename-Computer -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName -and $NewName }
            Should -Invoke -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $WorkGroupName }
        }
    }

    Context 'When ''FailToRenameAfterJoinDomain'' occured during domain join' {
        BeforeAll {
            $message = "Computer '' was successfully joined to the new domain '', but renaming it to '' failed with the following error message: The directory service is busy."
            $exception = [System.InvalidOperationException]::new($message)
            $errorID = 'FailToRenameAfterJoinDomain,Microsoft.PowerShell.Commands.AddComputerCommand'
            $errorCategory = [Management.Automation.ErrorCategory]::InvalidOperation
            $errorRecord = [System.Management.Automation.ErrorRecord]::new($exception, $errorID, $errorCategory, $null)

            Mock -CommandName Get-WMIObject -MockWith {
                [PSCustomObject] @{
                    Domain       = 'Contoso'
                    Workgroup    = 'Contoso'
                    PartOfDomain = $false
                }
            }

            Mock -CommandName Get-ADSIComputer -MockWith {
                $null
            }

            Mock -CommandName Get-ComputerDomain -MockWith {
                ''
            }

            Mock -CommandName Add-Computer -MockWith {
                Throw $errorRecord
            }
        }

        It 'Should try a separate rename' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetParams = @{
                    Name       = 'othername'
                    DomainName = 'Contoso.com'
                    JoinOU     = 'OU=Computers,DC=contoso,DC=com'
                    Credential = $credential
                }

                Set-TargetResource @setTargetParams | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Rename-Computer -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName -and $NewName }
            Should -Invoke -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $WorkGroupName }
            Should -Invoke -CommandName Get-ADSIComputer -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Remove-ADSIObject -Exactly -Times 0 -Scope It
        }
    }

    Context 'When Add-Computer errors with an unknown InvalidOperationException' {
        BeforeAll {
            Mock -CommandName Get-WMIObject -MockWith {
                [PSCustomObject] @{
                    Domain       = 'Contoso'
                    Workgroup    = 'Contoso'
                    PartOfDomain = $false
                }
            }

            Mock -CommandName Get-ComputerDomain -MockWith {
                ''
            }

            Mock -CommandName Add-Computer -MockWith {
                throw [System.InvalidOperationException]::new('Unknown Error')
            }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockErrorRecord = Get-InvalidOperationRecord -Message (
                    'Unknown Error'
                )

                $setTargetParams = @{
                    Name       = 'othername'
                    DomainName = 'Contoso.com'
                    JoinOU     = 'OU=Computers,DC=contoso,DC=com'
                    Credential = $credential
                }

                { Set-TargetResource @setTargetParams } |
                    Should -Throw -ExpectedMessage ($mockErrorRecord.Exception.Message + '*')
            }

            Should -Invoke -CommandName Rename-Computer -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName -and $NewName }
            Should -Invoke -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $WorkGroupName }
        }
    }

    Context 'When Add-Computer errors with an unknown error' {
        BeforeAll {
            Mock -CommandName Get-WMIObject -MockWith {
                [PSCustomObject] @{
                    Domain       = 'Contoso'
                    Workgroup    = 'Contoso'
                    PartOfDomain = $false
                }
            }

            Mock -CommandName Get-ComputerDomain -MockWith {
                ''
            }

            $errorRecord = 'Unknown Error'

            Mock -CommandName Add-Computer -MockWith {
                Throw $errorRecord
            }
        }

        It 'Should Throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockErrorRecord = New-InvalidOperationException -Message (
                    'Unknown Error'
                ) -PassThru

                $setTargetParams = @{
                    Name       = 'othername'
                    DomainName = 'Contoso.com'
                    JoinOU     = 'OU=Computers,DC=contoso,DC=com'
                    Credential = $credential
                }

                { Set-TargetResource @setTargetParams } | Should -Throw -ExpectedMessage ($mockErrorRecord.Exception.Message + '*')
            }

            Should -Invoke -CommandName Rename-Computer -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName -and $NewName }
            Should -Invoke -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $WorkGroupName }
            Should -Invoke -CommandName Get-ADSIComputer -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Remove-ADSIObject -Exactly -Times 0 -Scope It
        }
    }

    Context 'When ComputerName changes and Workgroup changes to new Workgroup' {
        BeforeAll {
            Mock -CommandName Get-WMIObject -MockWith {
                [PSCustomObject] @{
                    Domain       = 'Contoso';
                    Workgroup    = 'Contoso';
                    PartOfDomain = $false
                }
            }

            Mock -CommandName Get-ComputerDomain -MockWith {
                ''
            }

            Mock -CommandName Add-Computer
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetParams = @{
                    Name          = 'othername'
                    WorkGroupName = 'adventure-works'
                }

                Set-TargetResource @setTargetParams | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Rename-Computer -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $WorkGroupName -and $NewName }
            Should -Invoke -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $DomainName }
        }
    }

    Context 'When only the Domain is changed to new Domain' {
        BeforeAll {
            Mock -CommandName Get-WMIObject -MockWith {
                [PSCustomObject] @{
                    Domain       = 'Contoso.com';
                    Workgroup    = 'Contoso.com';
                    PartOfDomain = $true
                }
            }

            Mock -CommandName Get-ComputerDomain -MockWith {
                'contoso.com'
            }

            Mock -CommandName Add-Computer
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetParams = @{
                    Name             = $env:COMPUTERNAME
                    DomainName       = 'adventure-works.com'
                    Credential       = $credential
                    UnjoinCredential = $credential
                }

                Set-TargetResource @setTargetParams | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Rename-Computer -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName }
            Should -Invoke -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $NewName }
            Should -Invoke -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $WorkGroupName }
            Should -Invoke -CommandName Get-ADSIComputer -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Remove-ADSIObject -Exactly -Times 0 -Scope It
        }
    }

    Context 'Changes only the Domain to new Domain when name is [localhost]' {
        BeforeAll {
            Mock -CommandName Get-WMIObject -MockWith {
                [PSCustomObject] @{
                    Domain       = 'Contoso.com';
                    Workgroup    = 'Contoso.com';
                    PartOfDomain = $true
                }
            }

            Mock -CommandName Get-ComputerDomain -MockWith {
                'contoso.com'
            }

            Mock -CommandName Add-Computer
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetParams = @{
                    Name             = 'localhost'
                    DomainName       = 'adventure-works.com'
                    Credential       = $credential
                    UnjoinCredential = $credential
                }

                Set-TargetResource @setTargetParams | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Rename-Computer -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName }
            Should -Invoke -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $NewName }
            Should -Invoke -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $WorkGroupName }
            Should -Invoke -CommandName Get-ADSIComputer -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Remove-ADSIObject -Exactly -Times 0 -Scope It
        }
    }

    Context 'When only the Domain changes to new Domain with specified OU' {
        BeforeAll {
            Mock -CommandName Get-WMIObject -MockWith {
                [PSCustomObject] @{
                    Domain       = 'Contoso.com';
                    Workgroup    = 'Contoso.com';
                    PartOfDomain = $true
                }
            }

            Mock -CommandName Get-ComputerDomain -MockWith {
                'contoso.com'
            }

            Mock -CommandName Add-Computer
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetParams = @{
                    Name             = $env:COMPUTERNAME
                    DomainName       = 'adventure-works.com'
                    JoinOU           = 'OU=Computers,DC=contoso,DC=com'
                    Credential       = $credential
                    UnjoinCredential = $credential
                }

                Set-TargetResource @setTargetParams | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Rename-Computer -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName }
            Should -Invoke -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $NewName }
            Should -Invoke -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $WorkGroupName }
            Should -Invoke -CommandName Get-ADSIComputer -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Remove-ADSIObject -Exactly -Times 0 -Scope It
        }
    }

    Context 'When the Domain changes to a new Domain with specified OU when Name is [localhost]' {
        BeforeAll {
            Mock -CommandName Get-WMIObject -MockWith {
                [PSCustomObject] @{
                    Domain       = 'Contoso.com';
                    Workgroup    = 'Contoso.com';
                    PartOfDomain = $true
                }
            }

            Mock -CommandName Get-ComputerDomain -MockWith {
                'contoso.com'
            }

            Mock -CommandName Add-Computer
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetParams = @{
                    Name             = 'localhost'
                    DomainName       = 'adventure-works.com'
                    JoinOU           = 'OU=Computers,DC=contoso,DC=com'
                    Credential       = $credential
                    UnjoinCredential = $credential
                }

                Set-TargetResource @setTargetParams | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Rename-Computer -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $DomainName }
            Should -Invoke -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $NewName }
            Should -Invoke -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $WorkGroupName }
            Should -Invoke -CommandName Get-ADSIComputer -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Remove-ADSIObject -Exactly -Times 0 -Scope It
        }
    }

    Context 'When Domain changes to a Workgroup' {
        BeforeAll {
            Mock -CommandName Get-WMIObject -MockWith {
                [PSCustomObject] @{
                    Domain       = 'Contoso.com';
                    Workgroup    = 'Contoso.com';
                    PartOfDomain = $true
                }
            }

            Mock -CommandName Get-ComputerDomain -MockWith {
                ''
            }

            Mock -CommandName Add-Computer
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetParams = @{
                    Name             = $env:COMPUTERNAME
                    WorkGroupName    = 'Contoso'
                    UnjoinCredential = $credential
                }

                Set-TargetResource @setTargetParams | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Rename-Computer -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $NewName }
            Should -Invoke -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $WorkGroupName }
            Should -Invoke -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $DomainName }
        }
    }

    Context 'When only Domain changes to Workgroup and Name is [localhost]' {
        BeforeAll {
            Mock -CommandName Get-WMIObject -MockWith {
                [PSCustomObject] @{
                    Domain       = 'Contoso.com';
                    Workgroup    = 'Contoso.com';
                    PartOfDomain = $true
                }
            }

            Mock -CommandName Get-ComputerDomain -MockWith {
                ''
            }

            Mock -CommandName Add-Computer
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetParams = @{
                    Name             = 'localhost'
                    WorkGroupName    = 'Contoso'
                    UnjoinCredential = $credential
                }

                Set-TargetResource @setTargetParams | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Rename-Computer -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $NewName }
            Should -Invoke -CommandName Add-Computer -Exactly -Times 1 -Scope It -ParameterFilter { $WorkGroupName }
            Should -Invoke -CommandName Add-Computer -Exactly -Times 0 -Scope It -ParameterFilter { $DomainName }
        }
    }

    Context 'When only ComputerName changes and in Domain' {
        BeforeAll {
            Mock -CommandName Get-WMIObject -MockWith {
                [PSCustomObject] @{
                    Domain       = 'Contoso.com';
                    Workgroup    = 'Contoso.com';
                    PartOfDomain = $true
                }
            }

            Mock -CommandName Get-ComputerDomain -MockWith {
                'contoso.com'
            }

            Mock -CommandName Add-Computer
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetParams = @{
                    Name       = 'othername'
                    Credential = $credential
                }

                Set-TargetResource @setTargetParams | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Rename-Computer -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Add-Computer -Exactly -Times 0 -Scope It
        }
    }

    Context 'When only ComputerName changes and in Workgroup' {
        BeforeAll {
            Mock -CommandName Get-ComputerDomain -MockWith {
                ''
            }

            Mock -CommandName Get-WMIObject -MockWith {
                [PSCustomObject] @{
                    Domain       = 'Contoso';
                    Workgroup    = 'Contoso';
                    PartOfDomain = $false
                }
            }

            Mock -CommandName Add-Computer
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetParams = @{
                    Name = 'othername'
                }

                Set-TargetResource @setTargetParams | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Rename-Computer -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Add-Computer -Exactly -Times 0 -Scope It
        }
    }

    Context 'When name is too long' {
        It 'Should throw' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetParams = @{
                    Name = 'ThisNameIsTooLong'
                }

                { Set-TargetResource @setTargetParams } | Should -Throw
            }
        }
    }

    Context 'When name contains illegal characters' {
        It 'Should throw' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetParams = @{
                    Name = 'ThisIsBad<>'
                }

                { Set-TargetResource @setTargetParams } | Should -Throw
            }
        }
    }

    Context 'When computer description changes in a workgroup' {
        BeforeAll {
            Mock -CommandName Get-ComputerDomain -MockWith {
                ''
            }

            Mock -CommandName Get-WMIObject {
                [PSCustomObject] @{
                    Domain       = 'Contoso';
                    Workgroup    = 'Contoso';
                    PartOfDomain = $false
                }
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetParams = @{
                    Name        = $env:COMPUTERNAME
                    Description = 'This is my computer'
                    DomainName  = ''
                }

                Set-TargetResource @setTargetParams | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Set-CimInstance -Exactly -Times 1 -Scope It
        }
    }

    Context 'When computer description changes in a domain' {
        BeforeAll {
            Mock -CommandName Get-WMIObject -MockWith {
                [PSCustomObject] @{
                    Domain       = 'Contoso.com';
                    Workgroup    = 'Contoso.com';
                    PartOfDomain = $true
                }
            }

            Mock -CommandName Get-ComputerDomain -MockWith {
                'contoso.com'
            }
        }

        It 'Should return the correct result' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetParams = @{
                    Name = $env:COMPUTERNAME
                }

                Set-TargetResource @setTargetParams | Should -BeNullOrEmpty

                $setTargetParams = @{
                    Name             = $env:COMPUTERNAME
                    DomainName       = 'Contoso.com'
                    Credential       = $credential
                    UnjoinCredential = $credential
                    Description      = 'This is my computer'
                }

                Set-TargetResource @setTargetParams | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Set-CimInstance -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'DSC_Computer\Get-ComputerDomain' -Tag 'Private' {
    Context 'When computer is a domain member' {
        BeforeAll {
            Mock -CommandName Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_ComputerSystem' } -MockWith {
                [PSCustomObject] @{
                    Domain       = 'contoso.com';
                    PartOfDomain = $true
                }
            }

            Mock -CommandName Get-Item -ParameterFilter { $Path -eq 'Env:\USERDOMAIN' } -MockWith {
                [PSCustomObject] @{
                    Value = 'CONTOSO'
                }
            }
        }

        BeforeDiscovery {
            $testCases = @(
                @{ value = $true; result = 'CONTOSO'; GetItemCount = 1 }
                @{ value = $false; result = 'contoso.com'; GetItemCount = 0 }
            )
        }

        Context 'When netbios is <value>' -ForEach $testCases {
            It 'Should return the correct result' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getComputerDomainParameters = @{
                        netbios = $value
                    }

                    Get-ComputerDomain @getComputerDomainParameters | Should -Be $result
                }

                Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Get-Item -Exactly -Times $GetItemCount -Scope It
            }
        }

        Context 'When netbios not specified' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_ComputerSystem' } -MockWith {
                    [PSCustomObject] @{
                        Domain       = 'contoso.com';
                        PartOfDomain = $true
                    }
                }

                Mock -CommandName Get-Item -ParameterFilter { $Path -eq 'Env:\USERDOMAIN' } -MockWith {
                    [PSCustomObject] @{
                        Value = 'CONTOSO'
                    }
                }
            }
            It 'Should return domain DNS name' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    Get-ComputerDomain | Should -Be 'contoso.com'
                }

                Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Get-Item -Exactly -Times 0 -Scope It
            }
        }

        Context 'When computer is in a workgroup' {
            BeforeDiscovery {
                $testCases = @(
                    @{ value = $true }
                    @{ value = $false }
                )
            }

            Context 'When netbios is <value>' -ForEach $testCases {
                BeforeAll {
                    Mock -CommandName Get-CimInstance -ParameterFilter { $ClassName -eq 'Win32_ComputerSystem' } -MockWith {
                        [PSCustomObject] @{
                            Domain       = 'WORKGROUP';
                            PartOfDomain = $false
                        }
                    }

                    Mock -CommandName Get-Item -ParameterFilter { $Path -eq 'Env:\USERDOMAIN' } -MockWith {
                        [PSCustomObject] @{
                            Value = 'Computer1'
                        }
                    }
                }

                It 'Should return the correct result' {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $getComputerDomainParameters = @{
                            netbios = $value
                        }

                        Get-ComputerDomain @getComputerDomainParameters | Should -BeNullOrEmpty
                    }

                    Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Get-Item -Exactly -Times 0 -Scope It
                }
            }
        }
    }
}

Describe 'DSC_Computer\Get-LogonServer' -Tag 'Private' {
    It 'Should return a non-empty string' {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            Get-LogonServer | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'DSC_Computer\Get-ADSIComputer' -Tag 'Private' {
    BeforeAll {
        $mockDirectoryEntry = New-MockObject -Type Object -Properties @{
            Domain   = ''
            UserName = ''
            Password = ''
        }
        $mockSearcher = New-MockObject -Type Object -Methods @{
            FindOne = {
                return @{
                    path = 'LDAP://contoso.com/CN=fake-computer,OU=Computers,DC=contoso,DC=com'
                }
            }
        } -Properties @{
            SearchRoot = ''
            Filter     = ''
        }
    }

    Context 'When the name is too long' {
        It 'Should throw the expected exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $message = "Cannot validate argument on parameter 'Name'. The character length of the 17 argument is too long. Shorten the character length of the argument so it is fewer than or equal to `"15`" characters, and then try the command again."

                $mockParams = @{
                    Name       = 'ThisNameIsTooLong'
                    Domain     = 'Contoso.com'
                    Credential = $credential
                }

                { Get-ADSIComputer @mockParams } | Should -Throw $message
            }
        }
    }

    Context 'When the name contains illegal characters' {
        It 'Should throws the expected exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                #$message = "Cannot validate argument on parameter 'Name'. The `" `$_ -inotmatch '[\/\\:*?`"<>|]' `" validation script for the argument with value `"IllegalName[<`" did not return a result of True. Determine why the validation script failed, and then try the command again."

                $mockParams = @{
                    Name       = 'IllegalName[<'
                    Domain     = 'Contoso.com'
                    Credential = $credential
                }

                { Get-ADSIComputer @mockParams } | Should -Throw
            }
        }
    }

    Context 'When the command runs successfully' {
        BeforeAll {
            Mock -CommandName New-Object -MockWith {
                return $mockDirectoryEntry
            }

            Mock -CommandName New-Object -MockWith {
                return $mockSearcher
            }
        }

        Context 'When using DirectoryEntry' {
            It 'Returns ADSI object with ADSI path' {
                InModuleScope -Parameters @{
                    credential = $credential
                } -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParams = @{
                        Name       = 'LegalName'
                        Domain     = 'LDAP://Contoso.com'
                        Credential = $credential
                    }

                    $obj = Get-ADSIComputer @mockParams

                    $obj.path | Should -Be 'LDAP://contoso.com/CN=fake-computer,OU=Computers,DC=contoso,DC=com'
                }

                Should -Invoke -CommandName New-Object -Exactly -Times 2 -Scope It
            }
        }

        Context 'When using ADSI Searcher' {
            It 'Returns ADSI object with domain name' {
                InModuleScope -Parameters @{
                    credential = $credential
                } -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockParams = @{
                        Name       = 'LegalName'
                        Domain     = 'Contoso.com'
                        Credential = $credential
                    }

                    $obj = Get-ADSIComputer @mockParams

                    $obj.Path | Should -Be 'LDAP://contoso.com/CN=fake-computer,OU=Computers,DC=contoso,DC=com'
                }

                Should -Invoke -CommandName New-Object -Exactly -Times 2 -Scope It
            }
        }
    }

    Context 'When Credential is incorrect' {
        BeforeAll {
            Mock -CommandName New-Object -MockWith {
                Write-Error -message 'Invalid Credentials'
            }
        }

        It 'Should throw the expected exception' {
            InModuleScope -Parameters @{
                credential = $credential
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParams = @{
                    Name       = 'LegalName'
                    Domain     = 'Contoso.com'
                    Credential = $credential
                }

                { Get-ADSIComputer @mockParams } | Should -Throw 'Invalid Credentials'
            }

            Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'DSC_Computer\Remove-ADSIObject' -Tag 'Private' {
    Context 'When the path is correct' {
        BeforeAll {
            Mock New-Object -MockWith {
                return $mockObject
            }

            $mockObject = New-MockObject -Type Object -Methods @{
                DeleteTree = { }
            }
        }

        It 'Should delete the ADSI Object' {
            InModuleScope -Parameters @{
                credential = $credential
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockParams = @{
                    Path       = 'LDAP://contoso.com/CN=fake-computer,OU=Computers,DC=contoso,DC=com'
                    Credential = $credential
                }

                { Remove-ADSIObject @mockParams } | Should -Not -Throw
            }

            Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It
        }
    }

    Context 'When path does not begin with LDAP://' {
        It 'Should throw correct exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorMessage = "Cannot validate argument on parameter 'Path'. The `" `$_ -imatch `"LDAP://*`" `" validation script for the argument with value `"contoso.com/CN=fake-computer,OU=Computers,DC=contoso,DC=com`" did not return a result of True. Determine why the validation script failed, and then try the command again."

                $deleteADSIObjectParams = @{
                    Path       = 'contoso.com/CN=fake-computer,OU=Computers,DC=contoso,DC=com'
                    Credential = $credential
                }

                { Remove-ADSIObject @deleteADSIObjectParams } | Should -Throw -ExpectedMessage $errorMessage
            }
        }
    }

    Context 'When Credential is incorrect' {
        BeforeAll {
            Mock -CommandName New-Object -MockWith {
                Write-Error -message 'Invalid Credential'
            } -ParameterFilter {
                $TypeName -and
                $TypeName -eq 'System.DirectoryServices.DirectoryEntry'
            }
        }

        It 'Should throw the expected exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $deleteADSIObjectParams = @{
                    Path       = 'LDAP://contoso.com/CN=fake-computer,OU=Computers,DC=contoso,DC=com'
                    Credential = $credential
                }

                { Remove-ADSIObject @deleteADSIObjectParams } | Should -Throw 'Invalid Credential'
            }

            Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'DSC_Computer\Assert-ResourceProperty' -Tag 'Private' {
    Context 'When PasswordPass and UnsecuredJoin is present but credential username is not null' {
        It 'Should throw correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($LocalizedData.InvalidOptionCredentialUnsecuredJoinNullUsername) `
                    -ArgumentName 'Credential'

                $assertResourcePropertyParams = @{
                    Name       = $env:COMPUTERNAME
                    Options    = @('PasswordPass', 'UnsecuredJoin')
                    Credential = $credential
                }

                { Assert-ResourceProperty @assertResourcePropertyParams } | Should -Throw -ExpectedMessage ($errorRecord.Exception.Message + '*')
            }
        }
    }

    Context 'When PasswordPass is present in options without UnsecuredJoin' {
        It 'Should throw correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($LocalizedData.InvalidOptionPasswordPassUnsecuredJoin) `
                    -ArgumentName 'PasswordPass'

                $assertResourcePropertyParams = @{
                    Name    = $env:COMPUTERNAME
                    Options = @('PasswordPass')
                }

                { Assert-ResourceProperty @assertResourcePropertyParams } | Should -Throw -ExpectedMessage ($errorRecord.Exception.Message + '*')
            }
        }
    }
}
