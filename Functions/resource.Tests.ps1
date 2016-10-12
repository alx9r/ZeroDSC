Import-Module ZeroDSC -Force

Describe Test-ValidResourceParams {
    It 'returns true' {
        $splat = @{
            DependsOn = '[ResourceName]ConfigName'
            TestOnly  = $true
        }
        $r = Test-ValidResourceParams @splat
        $r | Should be $true
    }
}