IMport-Module ZeroDSC -Force

Describe Test-ValidConfigObject {
    It 'returns true for a New-ConfigObject' {
        $splat = @{
            Params       = @{}
            ResourceName = 'ResourceName'
            ConfigName   = 'ConfigName'
        }
        $r = New-ConfigObject @splat | Test-ValidConfigObject
        $r | Should be $true
    }
    It '...even without Params' {
        $splat = @{
            ResourceName = 'ResourceName'
            ConfigName   = 'ConfigName'
        }
        $r = New-ConfigObject @splat | Test-ValidConfigObject
        $r | Should be $true
    }
    It 'returns true for a New-PrereqObject' {
        $splat = @{
            Params       = @{}
            ResourceName = 'ResourceName'
            ConfigName   = 'ConfigName'
        }
        $r = New-PrereqObject @splat | Test-ValidConfigObject
        $r | Should be $true
    }
    It 'returns true for a list of good objects' {}
    It 'accepts output of New-ConfigObject' {}
    It 'accepts output of New-PrerequisitesObject' {}
    It 'throws when ClassId is wrong' {}
    It 'throws when ResourceName contains invalid characters' {}
    It 'throws when Set- is not found' {}
    It 'throws when Test- is not found' {}
    It 'throws when Set- is ambiguous' {}
    It 'throws when Test- is ambiguous' {}
    It 'invokes check that Set- and Test- signatures are the same' {}
    It 'throws when DependsOn refers to an unknown ConfigPath' {}
}
