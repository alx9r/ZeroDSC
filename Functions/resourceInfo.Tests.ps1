Import-Module ZeroDSC -Force

$stubModule1Path = "$($PSCommandPath | Split-Path -Parent)\..\Resources\StubResourceModule1\StubResourceModule1.psd1"
$stubModule3Path = "$($PSCommandPath | Split-Path -Parent)\..\Resources\StubResourceModule3\StubResourceModule3.psd1"

Describe 'Get-ResourceName using mocks' {
    It 'invokes Get-ResourceModule' {}
}
Describe 'Get-ResourceModule' {
    It 'gets module when name is the path' {}
    It 'gets module when name is the name' {}
    It 'gets module when name is the friendly name' {}
}
Describe 'Get-ResourceNameFromImplementingAssembly' {
    It 'returns only the DSC resource names' {
        $module = Import-Module $stubModule3Path -Force -PassThru
        $r = Get-ResourceNameFromImplementingAssembly $module
        $r.Count | Should be 2
        $r[0] | Should be 'StubResource3A'
        $r[1] | Should be 'StubResource3B'
    }
}
Describe 'Get-ResourceNameFromDscResourcesFolder' {
    It 'returns the DSC resource names' {
        $module = Import-Module $stubModule1Path -Force -PassThru
        $r = Get-ResourceNameFromDscResourcesFolder $module
        $r.Count | Should be 2
        $r[0] | Should be StubResource1AFriendlyName
        $r[1] | Should be StubResource1BFriendlyName
    }
}
Describe 'Get-FriendlyNameFromMof' {
    foreach ( $folderName in 'StubResource1A','StubResource1B' )
    {
        It "extracts name from file $folderName.schema.mof" {
            $mofFilePath = "$($PSCommandPath | Split-Path -Parent)\..\Resources\StubResourceModule1\DSCResources\$folderName\$folderName.schema.mof"
            $r = Get-FriendlyNameFromMof $mofFilePath
            $r | Should be "$folderName`FriendlyName"
        }
    }
}
Describe 'Get-ResourceNameFromExportedDscResources' {}