<#
    .SYNOPSIS
        Unit test for DSC_SmbServerConfiguration DSC resource.

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
    $script:dscResourceName = 'DSC_SmbServerConfiguration'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName
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

Describe 'DSC_SmbServerConfiguration\Get-TargetResource' -Tag 'Get' {
    Context 'When getting the Target Resource information' {
        It 'Should get the current SMB server configuration state' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $SmbServerConfiguration = Get-TargetResource -IsSingleInstance Yes

                $SmbServerConfiguration.EnableSMB1Protocol | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.AnnounceComment | Should -BeOfType String
                $SmbServerConfiguration.AnnounceServer | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.AsynchronousCredits | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.AuditSmb1Access | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.AutoDisconnectTimeout | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.AutoShareServer | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.AutoShareWorkstation | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.CachedOpenLimit | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.DurableHandleV2TimeoutInSeconds | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.EnableAuthenticateUserSharing | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.EnableDownlevelTimewarp | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.EnableForcedLogoff | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.EnableLeasing | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.EnableMultiChannel | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.EnableOplocks | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.EnableSecuritySignature | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.EnableSMB2Protocol | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.EnableStrictNameChecking | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.EncryptData | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.IrpStackSize | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.KeepAliveTime | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.MaxChannelPerSession | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.MaxMpxCount | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.MaxSessionPerConnection | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.MaxThreadsPerQueue | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.MaxWorkItems | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.NullSessionPipes | Should -BeOfType String
                $SmbServerConfiguration.NullSessionShares | Should -BeOfType String
                $SmbServerConfiguration.OplockBreakWait | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.PendingClientTimeoutInSeconds | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.RejectUnencryptedAccess | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.RequireSecuritySignature | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.ServerHidden | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.Smb2CreditsMax | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.Smb2CreditsMin | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.SmbServerNameHardeningLevel | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.TreatHostAsStableStorage | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.ValidateAliasNotCircular | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.ValidateShareScope | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.ValidateShareScopeNotAliased | Should -Not -BeNullOrEmpty
                $SmbServerConfiguration.ValidateTargetName | Should -Not -BeNullOrEmpty
            }
        }
    }
}

Describe 'DSC_SmbServerConfiguration\Test-TargetResource' -Tag 'Test' {
    Context 'When the SMB Server is in the desired state' {
        BeforeAll {
            Mock -CommandName Get-SmbServerConfiguration {
                return @{
                    AnnounceComment                 = ''
                    AnnounceServer                  = $false
                    AsynchronousCredits             = 64
                    AuditSmb1Access                 = $false
                    AutoDisconnectTimeout           = 15
                    AutoShareServer                 = $true
                    AutoShareWorkstation            = $true
                    CachedOpenLimit                 = 10
                    DurableHandleV2TimeoutInSeconds = 180
                    EnableAuthenticateUserSharing   = $false
                    EnableDownlevelTimewarp         = $false
                    EnableForcedLogoff              = $true
                    EnableLeasing                   = $true
                    EnableMultiChannel              = $true
                    EnableOplocks                   = $true
                    EnableSecuritySignature         = $false
                    EnableSMB1Protocol              = $false
                    EnableSMB2Protocol              = $true
                    EnableStrictNameChecking        = $true
                    EncryptData                     = $false
                    IrpStackSize                    = 15
                    KeepAliveTime                   = 2
                    MaxChannelPerSession            = 32
                    MaxMpxCount                     = 50
                    MaxSessionPerConnection         = 16384
                    MaxThreadsPerQueue              = 20
                    MaxWorkItems                    = 1
                    NullSessionPipes                = ''
                    NullSessionShares               = ''
                    OplockBreakWait                 = 35
                    PendingClientTimeoutInSeconds   = 120
                    RejectUnencryptedAccess         = $true
                    RequireSecuritySignature        = $false
                    ServerHidden                    = $true
                    Smb2CreditsMax                  = 2048
                    Smb2CreditsMin                  = 128
                    SmbServerNameHardeningLevel     = 0
                    TreatHostAsStableStorage        = $false
                    ValidateAliasNotCircular        = $true
                    ValidateShareScope              = $true
                    ValidateShareScopeNotAliased    = $true
                    ValidateTargetName              = $true
                }
            }
        }

        It 'Should return true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $fullParams = @{
                    IsSingleInstance                = 'Yes'
                    AnnounceComment                 = ''
                    AnnounceServer                  = $false
                    AsynchronousCredits             = 64
                    AuditSmb1Access                 = $false
                    AutoDisconnectTimeout           = 15
                    AutoShareServer                 = $true
                    AutoShareWorkstation            = $true
                    CachedOpenLimit                 = 10
                    DurableHandleV2TimeoutInSeconds = 180
                    EnableAuthenticateUserSharing   = $false
                    EnableDownlevelTimewarp         = $false
                    EnableForcedLogoff              = $true
                    EnableLeasing                   = $true
                    EnableMultiChannel              = $true
                    EnableOplocks                   = $true
                    EnableSecuritySignature         = $false
                    EnableSMB1Protocol              = $false
                    EnableSMB2Protocol              = $true
                    EnableStrictNameChecking        = $true
                    EncryptData                     = $false
                    IrpStackSize                    = 15
                    KeepAliveTime                   = 2
                    MaxChannelPerSession            = 32
                    MaxMpxCount                     = 50
                    MaxSessionPerConnection         = 16384
                    MaxThreadsPerQueue              = 20
                    MaxWorkItems                    = 1
                    NullSessionPipes                = ''
                    NullSessionShares               = ''
                    OplockBreakWait                 = 35
                    PendingClientTimeoutInSeconds   = 120
                    RejectUnencryptedAccess         = $true
                    RequireSecuritySignature        = $false
                    ServerHidden                    = $true
                    Smb2CreditsMax                  = 2048
                    Smb2CreditsMin                  = 128
                    SmbServerNameHardeningLevel     = 0
                    TreatHostAsStableStorage        = $false
                    ValidateAliasNotCircular        = $true
                    ValidateShareScope              = $true
                    ValidateShareScopeNotAliased    = $true
                    ValidateTargetName              = $true
                }

                $TestEnvironmentResult = Test-TargetResource @fullParams
                $TestEnvironmentResult | Should -BeTrue
            }
        }
    }

    Context 'When the SMB Server is not in the desired state' {
        BeforeDiscovery {
            $testCases = @(
                @{
                    smbSetting = 'AnnounceComment'
                    newValue   = 'Test String'
                }
                @{
                    smbSetting = 'AnnounceServer'
                    newValue   = $true
                }
                @{
                    smbSetting = 'AsynchronousCredits'
                    newValue   = 32
                }
                @{
                    smbSetting = 'AuditSmb1Access'
                    newValue   = $true
                }
                @{
                    smbSetting = 'AutoDisconnectTimeout'
                    newValue   = 30
                }
                @{
                    smbSetting = 'AutoShareServer'
                    newValue   = $false
                }
                @{
                    smbSetting = 'AutoShareWorkstation'
                    newValue   = $false
                }
                @{
                    smbSetting = 'CachedOpenLimit'
                    newValue   = 20
                }
                @{
                    smbSetting = 'DurableHandleV2TimeoutInSeconds'
                    newValue   = 360
                }
                @{
                    smbSetting = 'EnableAuthenticateUserSharing'
                    newValue   = $true
                }
                @{
                    smbSetting = 'EnableDownlevelTimewarp'
                    newValue   = $true
                }
                @{
                    smbSetting = 'EnableForcedLogoff'
                    newValue   = $false
                }
                @{
                    smbSetting = 'EnableLeasing'
                    newValue   = $false
                }
                @{
                    smbSetting = 'EnableMultiChannel'
                    newValue   = $false
                }
                @{
                    smbSetting = 'EnableOplocks'
                    newValue   = $false
                }
                @{
                    smbSetting = 'EnableSecuritySignature'
                    newValue   = $true
                }
                @{
                    smbSetting = 'EnableSMB1Protocol'
                    newValue   = $true
                }
                @{
                    smbSetting = 'EnableSMB2Protocol'
                    newValue   = $false
                }
                @{
                    smbSetting = 'EnableStrictNameChecking'
                    newValue   = $false
                }
                @{
                    smbSetting = 'EncryptData'
                    newValue   = $true
                }
                @{
                    smbSetting = 'IrpStackSize'
                    newValue   = 30
                }
                @{
                    smbSetting = 'KeepAliveTime'
                    newValue   = 4
                }
                @{
                    smbSetting = 'MaxChannelPerSession'
                    newValue   = 16
                }
                @{
                    smbSetting = 'MaxMpxCount'
                    newValue   = 25
                }
                @{
                    smbSetting = 'MaxSessionPerConnection'
                    newValue   = 16000
                }
                @{
                    smbSetting = 'MaxThreadsPerQueue'
                    newValue   = 10
                }
                @{
                    smbSetting = 'MaxWorkItems'
                    newValue   = 2
                }
                @{
                    smbSetting = 'NullSessionPipes'
                    newValue   = 'TestPipe'
                }
                @{
                    smbSetting = 'NullSessionShares'
                    newValue   = 'TestShare'
                }
                @{
                    smbSetting = 'OplockBreakWait'
                    newValue   = 60
                }
                @{
                    smbSetting = 'PendingClientTimeoutInSeconds'
                    newValue   = 240
                }
                @{
                    smbSetting = 'RejectUnencryptedAccess'
                    newValue   = $false
                }
                @{
                    smbSetting = 'RequireSecuritySignature'
                    newValue   = $true
                }
                @{
                    smbSetting = 'ServerHidden'
                    newValue   = $false
                }
                @{
                    smbSetting = 'Smb2CreditsMax'
                    newValue   = 1024
                }
                @{
                    smbSetting = 'Smb2CreditsMin'
                    newValue   = 256
                }
                @{
                    smbSetting = 'SmbServerNameHardeningLevel'
                    newValue   = 1
                }
                @{
                    smbSetting = 'TreatHostAsStableStorage'
                    newValue   = $true
                }
                @{
                    smbSetting = 'ValidateAliasNotCircular'
                    newValue   = $false
                }
                @{
                    smbSetting = 'ValidateShareScope'
                    newValue   = $false
                }
                @{
                    smbSetting = 'ValidateShareScopeNotAliased'
                    newValue   = $false
                }
                @{
                    smbSetting = 'ValidateTargetName'
                    newValue   = $false
                }
            )
        }

        BeforeAll {
            Mock -CommandName Get-SmbServerConfiguration {
                return @{
                    AnnounceComment                 = ''
                    AnnounceServer                  = $false
                    AsynchronousCredits             = 64
                    AuditSmb1Access                 = $false
                    AutoDisconnectTimeout           = 15
                    AutoShareServer                 = $true
                    AutoShareWorkstation            = $true
                    CachedOpenLimit                 = 10
                    DurableHandleV2TimeoutInSeconds = 180
                    EnableAuthenticateUserSharing   = $false
                    EnableDownlevelTimewarp         = $false
                    EnableForcedLogoff              = $true
                    EnableLeasing                   = $true
                    EnableMultiChannel              = $true
                    EnableOplocks                   = $true
                    EnableSecuritySignature         = $false
                    EnableSMB1Protocol              = $false
                    EnableSMB2Protocol              = $true
                    EnableStrictNameChecking        = $true
                    EncryptData                     = $false
                    IrpStackSize                    = 15
                    KeepAliveTime                   = 2
                    MaxChannelPerSession            = 32
                    MaxMpxCount                     = 50
                    MaxSessionPerConnection         = 16384
                    MaxThreadsPerQueue              = 20
                    MaxWorkItems                    = 1
                    NullSessionPipes                = ''
                    NullSessionShares               = ''
                    OplockBreakWait                 = 35
                    PendingClientTimeoutInSeconds   = 120
                    RejectUnencryptedAccess         = $true
                    RequireSecuritySignature        = $false
                    ServerHidden                    = $true
                    Smb2CreditsMax                  = 2048
                    Smb2CreditsMin                  = 128
                    SmbServerNameHardeningLevel     = 0
                    TreatHostAsStableStorage        = $false
                    ValidateAliasNotCircular        = $true
                    ValidateShareScope              = $true
                    ValidateShareScopeNotAliased    = $true
                    ValidateTargetName              = $true
                }
            }
        }
        It 'Should return false when <smbSetting> setting changes are required' -TestCases $testCases {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $caseParams = @{
                    IsSingleInstance = 'Yes'
                    $smbSetting      = $newValue
                }

                $TestEnvironmentResult = Test-TargetResource @caseParams
                $TestEnvironmentResult | Should -BeFalse
            }
        }
    }
}

Describe 'DSC_SmbServerConfiguration\Set-TargetResource' -Tag 'Set' {
    Context 'When configuration is required' {
        BeforeDiscovery {
            $testCases = @(
                @{
                    smbSetting = 'AnnounceComment'
                    newValue   = 'Test String'
                }
                @{
                    smbSetting = 'AnnounceServer'
                    newValue   = $true
                }
                @{
                    smbSetting = 'AsynchronousCredits'
                    newValue   = 32
                }
                @{
                    smbSetting = 'AuditSmb1Access'
                    newValue   = $true
                }
                @{
                    smbSetting = 'AutoDisconnectTimeout'
                    newValue   = 30
                }
                @{
                    smbSetting = 'AutoShareServer'
                    newValue   = $false
                }
                @{
                    smbSetting = 'AutoShareWorkstation'
                    newValue   = $false
                }
                @{
                    smbSetting = 'CachedOpenLimit'
                    newValue   = 20
                }
                @{
                    smbSetting = 'DurableHandleV2TimeoutInSeconds'
                    newValue   = 360
                }
                @{
                    smbSetting = 'EnableAuthenticateUserSharing'
                    newValue   = $true
                }
                @{
                    smbSetting = 'EnableDownlevelTimewarp'
                    newValue   = $true
                }
                @{
                    smbSetting = 'EnableForcedLogoff'
                    newValue   = $false
                }
                @{
                    smbSetting = 'EnableLeasing'
                    newValue   = $false
                }
                @{
                    smbSetting = 'EnableMultiChannel'
                    newValue   = $false
                }
                @{
                    smbSetting = 'EnableOplocks'
                    newValue   = $false
                }
                @{
                    smbSetting = 'EnableSecuritySignature'
                    newValue   = $true
                }
                @{
                    smbSetting = 'EnableSMB1Protocol'
                    newValue   = $true
                }
                @{
                    smbSetting = 'EnableSMB2Protocol'
                    newValue   = $false
                }
                @{
                    smbSetting = 'EnableStrictNameChecking'
                    newValue   = $false
                }
                @{
                    smbSetting = 'EncryptData'
                    newValue   = $true
                }
                @{
                    smbSetting = 'IrpStackSize'
                    newValue   = 30
                }
                @{
                    smbSetting = 'KeepAliveTime'
                    newValue   = 4
                }
                @{
                    smbSetting = 'MaxChannelPerSession'
                    newValue   = 16
                }
                @{
                    smbSetting = 'MaxMpxCount'
                    newValue   = 25
                }
                @{
                    smbSetting = 'MaxSessionPerConnection'
                    newValue   = 16000
                }
                @{
                    smbSetting = 'MaxThreadsPerQueue'
                    newValue   = 10
                }
                @{
                    smbSetting = 'MaxWorkItems'
                    newValue   = 2
                }
                @{
                    smbSetting = 'NullSessionPipes'
                    newValue   = 'TestPipe'
                }
                @{
                    smbSetting = 'NullSessionShares'
                    newValue   = 'TestShare'
                }
                @{
                    smbSetting = 'OplockBreakWait'
                    newValue   = 60
                }
                @{
                    smbSetting = 'PendingClientTimeoutInSeconds'
                    newValue   = 240
                }
                @{
                    smbSetting = 'RejectUnencryptedAccess'
                    newValue   = $false
                }
                @{
                    smbSetting = 'RequireSecuritySignature'
                    newValue   = $true
                }
                @{
                    smbSetting = 'ServerHidden'
                    newValue   = $false
                }
                @{
                    smbSetting = 'Smb2CreditsMax'
                    newValue   = 1024
                }
                @{
                    smbSetting = 'Smb2CreditsMin'
                    newValue   = 256
                }
                @{
                    smbSetting = 'SmbServerNameHardeningLevel'
                    newValue   = 1
                }
                @{
                    smbSetting = 'TreatHostAsStableStorage'
                    newValue   = $true
                }
                @{
                    smbSetting = 'ValidateAliasNotCircular'
                    newValue   = $false
                }
                @{
                    smbSetting = 'ValidateShareScope'
                    newValue   = $false
                }
                @{
                    smbSetting = 'ValidateShareScopeNotAliased'
                    newValue   = $false
                }
                @{
                    smbSetting = 'ValidateTargetName'
                    newValue   = $false
                }
            )
        }

        BeforeAll {
            Mock -CommandName Get-SmbServerConfiguration {
                return @{
                    AnnounceComment                 = ''
                    AnnounceServer                  = $false
                    AsynchronousCredits             = 64
                    AuditSmb1Access                 = $false
                    AutoDisconnectTimeout           = 15
                    AutoShareServer                 = $true
                    AutoShareWorkstation            = $true
                    CachedOpenLimit                 = 10
                    DurableHandleV2TimeoutInSeconds = 180
                    EnableAuthenticateUserSharing   = $false
                    EnableDownlevelTimewarp         = $false
                    EnableForcedLogoff              = $true
                    EnableLeasing                   = $true
                    EnableMultiChannel              = $true
                    EnableOplocks                   = $true
                    EnableSecuritySignature         = $false
                    EnableSMB1Protocol              = $false
                    EnableSMB2Protocol              = $true
                    EnableStrictNameChecking        = $true
                    EncryptData                     = $false
                    IrpStackSize                    = 15
                    KeepAliveTime                   = 2
                    MaxChannelPerSession            = 32
                    MaxMpxCount                     = 50
                    MaxSessionPerConnection         = 16384
                    MaxThreadsPerQueue              = 20
                    MaxWorkItems                    = 1
                    NullSessionPipes                = ''
                    NullSessionShares               = ''
                    OplockBreakWait                 = 35
                    PendingClientTimeoutInSeconds   = 120
                    RejectUnencryptedAccess         = $true
                    RequireSecuritySignature        = $false
                    ServerHidden                    = $true
                    Smb2CreditsMax                  = 2048
                    Smb2CreditsMin                  = 128
                    SmbServerNameHardeningLevel     = 0
                    TreatHostAsStableStorage        = $false
                    ValidateAliasNotCircular        = $true
                    ValidateShareScope              = $true
                    ValidateShareScopeNotAliased    = $true
                    ValidateTargetName              = $true
                }
            }

            Mock -CommandName Set-SmbServerConfiguration
        }

        It 'Runs the Set-SmbServerConfiguration cmdlet when the <smbSetting> needs to be changed' -TestCases $testCases {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                $caseParams = @{
                    IsSingleInstance = 'Yes'
                    $smbSetting      = $newValue
                }

                Set-TargetResource @caseParams
            }

            Assert-MockCalled -CommandName Set-SmbServerConfiguration -Times 1
        }
    }
}
