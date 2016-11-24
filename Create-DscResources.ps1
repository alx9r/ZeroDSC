#Import-Module xDSCResourceDesigner

$Key = New-xDscResourceProperty -Name Key -Type String -Attribute Key
$Mode = New-xDscResourceProperty -Name Mode -Type String -ValidateSet 'already set','incorrigible','normal','reset' -Attribute Write
$ThrowOnGet = New-xDscResourceProperty -Name ThrowOnGet -Type String -ValidateSet 'always' -Attribute Write
$ThrowOnSet = New-xDscResourceProperty -Name ThrowOnSet -Type String -ValidateSet 'always' -Attribute Write
$ThrowOnTest = New-xDscResourceProperty -Name ThrowOnTest -Type String -ValidateSet 'always','after set' -Attribute Write

New-xDscResource -Name TestStub -FriendlyName TestStub -Property $Key,$Mode,$ThrowOnGet,$ThrowOnSet,$ThrowOnTest
