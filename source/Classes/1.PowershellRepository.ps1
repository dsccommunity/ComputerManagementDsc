<#
    .DESCRIPTION
        Parent class for DSC resource PSResourceRepository
#>

$modulePath =

Import-Module -Name (Join-Path -Path $modulePath -ChildPath DscResource.Common)
Import-Module -Name (Join-Path -Path $modulePath -ChildPath (Join-Path -Path ComputerManagementDsc.Common -ChildPath JeaDsc.Common.psm1))

$script:localizedDataRole = Get-LocalizedData -DefaultUICulture en-US -FileName 'PSResourceRepository.strings.psd1'

class PowershellRepository
{

}
