Import-Module xDSCResourceDesigner

$StringParam1 = New-xDscResourceProperty -Name StringParam1 -Type String -Attribute Key
$StringParam2 = New-xDscResourceProperty -Name StringParam2 -Type String -Attribute Write
$BoolParam = New-xDscResourceProperty -Name BoolParam -Type Boolean -Attribute Write

New-xDscResource �Name StubResource1 �Property $StringParam1,$StringParam2,$BoolParam �Path $PSScriptRoot �ModuleName StubResourceModule1
New-xDscResource �Name StubResource2 �Property $StringParam1,$StringParam2,$BoolParam �Path $PSScriptRoot �ModuleName StubResourceModule1