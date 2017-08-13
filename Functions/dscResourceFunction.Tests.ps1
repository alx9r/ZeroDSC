Import-Module ZeroDsc -Force

InModuleScope ZeroDsc {

Describe 'Import- and Remove-DscFunction' {
    $guidFrag = [guid]::NewGuid().Guid.Split('-')[0]
    $moduleName = "module-$guidFrag"
    BeforeEach {
        $m = New-Module $moduleName { function f {} }
        $m | Import-Module
    }
    AfterEach {
        Get-Module $moduleName | Remove-Module
    }
    It 'the function is usually bound to the module...' {
        $r = Get-Command f -Module $m.Name
        $r.Source | Should be $m.Name
    }
    It 'Import- returns nothing' {
        $r = Get-Command f | Import-DscFunction
        $r | Should beNullOrEmpty
    }
    It 'correctly removes the module-bound function' {
        Get-Command f | Import-DscFunction
        $r = Get-Command f -Module $m.Name -ea SilentlyContinue
        $r | Should beNullOrEmpty
    }
    It 'correctly adds the non-bound function' {
        Get-Command f | Import-DscFunction
        $r = Get-Command f
        $r.Source | Should beNullOrEmpty
    }
    It 'Remove- returns nothing' {
        $r = Get-Command f | Remove-DscFunction -ea Stop
        $r | Should beNullOrEmpty
    }
    It 'correctly removes the function' {
        Get-Command f | Import-DscFunction
        Get-Command f | Remove-DscFunction
        $r = Get-Command f -ea SilentlyContinue
        $r | Should beNullOrEmpty
    }
}
}
