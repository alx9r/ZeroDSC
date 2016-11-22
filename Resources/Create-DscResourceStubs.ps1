#Import-Module xDSCResourceDesigner

$StringParam1 = New-xDscResourceProperty -Name StringParam1 -Type String -Attribute Key
$StringParam2 = New-xDscResourceProperty -Name StringParam2 -Type String -Attribute Write
$BoolParam = New-xDscResourceProperty -Name BoolParam -Type Boolean -Attribute Write

New-xDscResource –Name StubResource1A -FriendlyName StubResource1AFriendlyName –Property $StringParam1,$StringParam2,$BoolParam –Path $PSScriptRoot –ModuleName StubResourceModule1
New-xDscResource –Name StubResource1B -FriendlyName StubResource1BFriendlyName –Property $StringParam1,$StringParam2,$BoolParam –Path $PSScriptRoot –ModuleName StubResourceModule1

$Mode = New-xDscResourceProperty -Name Mode -Type String -Attribute Key -ValidateSet 'already set','incorrigible','normal'

New-xDscResource -Name StubResource6 -FriendlyName StubResource6FriendlyName -Property $Mode
