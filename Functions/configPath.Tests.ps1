Describe Assert-ValidConfigPath {
    It "throws on ']ResourceName]ConfigName' " {}
    It "throws on '[ResourceName][ConfigName'" {}
    It "returns nothing for '[ResourceName]ConfigName'" {}
    It 'returns nothing for empty string' {}
}
Describe ConvertTo-ConfigPath {
    It "correctly composes '[ResourceName]ConfigName'" {}
}
Describe Get-ConfigPathPart {
    It 'gets ResourceName' {}
    It 'gets ConfigName' {}
}
Describe Assert-ValidConfigName {
    It "throws on 'Resource[ConfigName'" {}
    It "returns nothing for 'ConfigName'" {}
    It 'throws on empty string' {}
}
Describe Assert-ValidResourceName {
    It "throws on 'Resource-Name'" {}
    It "throws on 'Resource[Name'" {}
    It "returns nothing for 'ResourceName'" {}
}