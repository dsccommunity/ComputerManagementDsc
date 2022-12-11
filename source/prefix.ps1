$script:dscResourceCommonModulePath = Join-Path -Path $PSScriptRoot -ChildPath 'Modules/DscResource.Common'
Import-Module -Name $script:dscResourceCommonModulePath

$script:computerManagementDscCommonModulePath = Join-Path -Path $PSScriptRoot -ChildPath 'Modules/ComputerManagementDsc.Common'
Import-Module -Name $script:computerManagementDscCommonModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'
