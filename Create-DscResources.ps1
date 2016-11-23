#Import-Module xDSCResourceDesigner

$Mode = New-xDscResourceProperty -Name Mode -Type String -Attribute Key -ValidateSet 'already set','incorrigible','normal'
$ThrowOnGet = New-xDscResourceProperty -Name ThrowOnGet -Type String -ValidateSet 'always' -Attribute Write
$ThrowOnSet = New-xDscResourceProperty -Name ThrowOnSet -Type String -ValidateSet 'always' -Attribute Write
$ThrowOnTest = New-xDscResourceProperty -Name ThrowOnTest -Type String -ValidateSet 'always','after set' -Attribute Write

New-xDscResource -Name TestStub -FriendlyName TestStub -Property $Mode,$ThrowOnGet,$ThrowOnSet,$ThrowOnTest
