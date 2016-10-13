Describe Test-Prerequisites {
    Context 'only ConfigObjects' {
        It 'returns true when DependsOn is empty' {}
        It 'returns true when DependsOn refers to a completed instruction' {}
        It 'returns false when DependsOn refers to an uncompleted instruction' {}
        It 'returns true when DependsOn refers to two completed instructions' {}
        It 'returns false when DependsOn refers to one completed and one uncompleted instruction' {}
        It 'returns false when DependsOn refers to two uncompleted instructions' {}
        It 'returns true when an aggregate condition is met' {}
        It 'returns false whan an aggregate condition is not met' {}
    }
    Context 'only PrereqObjects' {
        It 'correctly invokes each objects'' Test- command' {}
        It 'correctly returns false for Count -eq 0' {}
        It 'correctly returns true for Count -eq 0' {}
        It 'correctly returns false for COunt -ge 1' {}
        It 'correctly returns true for Count -ge 1' {}
    }
}

Describe Test-ValidPrereqParams {
    It 'returns true' {
        $splat = @{
            DependsOn = '[ResourceName]ConfigName'
            TestOnly  = $true
        }
        $r = Test-ValidPrereqParams @splat
        $r | Should be $true
    }
    It 'returns false for invalid DependsOn' {
        $splat = @{
            DependsOn = '[Resource[Name]ConfigName'
            TestOnly  = $true
        }
        $r = Test-ValidPrereqParams @splat
        $r | Should be $false        
    }
    It 'returns true for plain psobject' {
        $r = New-Object psobject | Test-ValidPrereqParams
        $r | Should be $true
    }
    It 'returns true for plain hashtable' {
        $r = @{} | Test-ValidPrereqParams
        $r | Should be $true
    }
    It 'returns false for invalid hashtable' {
        $r = @{DependsOn = '[Resource[Name]ConfigName'} | Test-ValidPrereqParams
        $r | Should be $false
    }
    It 'returns false for invalid object' {
        $o = New-Object psobject -Property @{
            DependsOn = '[Resource[Name]ConfigName'
            TestOnly  = $true
        }
        $r = $o | Test-ValidPrereqParams
        $r | Should be $false
    }
}