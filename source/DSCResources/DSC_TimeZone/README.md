# Description

The resource will use the `Get-TimeZone` cmdlet to get the current
time zone. If `Get-TimeZone` is not available them CIM will be used to retrieve
the current time zone. To update the time zone, .NET reflection will be used to
update the time zone if required. If .NET reflection is not supported on the node
(in the case of Nano Server) then tzutil.exe will be used to set the time zone.
