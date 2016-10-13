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
    It 'returns false for invalid DependsOn' {
        $splat = @{
            DependsOn = '[Resource[Name]ConfigName'
            TestOnly  = $true
        }
        $r = Test-ValidResourceParams @splat
        $r | Should be $false        
    }
    It 'returns true for plain psobject' {
        $r = New-Object psobject | Test-ValidResourceParams
        $r | Should be $true
    }
    It 'returns true for plain hashtable' {
        $r = @{} | Test-ValidResourceParams
        $r | Should be $true
    }
    It 'returns false for invalid hashtable' {
        $r = @{DependsOn = '[Resource[Name]ConfigName'} | Test-ValidResourceParams
        $r | Should be $false
    }
    It 'returns false for invalid object' {
        $o = New-Object psobject -Property @{
            DependsOn = '[Resource[Name]ConfigName'
            TestOnly  = $true
        }
        $r = $o | Test-ValidResourceParams
        $r | Should be $false
    }
}