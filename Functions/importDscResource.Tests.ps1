Import-Module ZeroDSC -Force

Describe Import-ZeroDscModule {
    It 'correctly invokes Import-Module' {}
    It 'correctly invokes Get-Module' {}
    It 'correctly imports all NestedModules' {}
    It 'correctly invokes Get-ChildItem to discover DSC Resources' {}
    It 'correctly calls get DSC Resource for each' {}
    It 'correctly calls Import-Module for each DSC Resource' {}
    It 'correctly invokes Assert-ValidZeroDscResource for each DSC Resource' {}
    It 'correctly invokes Set-DscResourceFunctions for each DSC Resource' {}
    It 'correctly invokes Remove-Module for the top-level module' {}
}
Describe Assert-ValidZeroDscResource {
    It 'correctly invoke Get-DscResource' {}
    It 'throws when the DSC Resource is not implemented in PowerShell' {}
    It 'throws when Test-TargetResource is not exported' {}
    It 'throws when Set-TargetResource is not exported' {}
    It 'throws when Get-TargetResource is not exported' {}
    It 'correctly invokes Compare-Signatures' {}
    It 'throws when Test- signature does not match Set-' {}
    It 'throws when Set- signature does mathc Get-' {}
}
Describe Set-DscResourceConfigFunction {
    It 'correctly calls Set-Item' {}
}