Import-Module ZeroDSC -Force

. "$($PSCommandPath | Split-Path -Parent)\..\Add-StubsToModulePath.ps1"

$records = @{}

Describe 'set up environment' {
    It 'retrieve the stub resources' {
        $records.StubResources = Get-DscResource StubResource4A
    }
    It 'extract the first stub resource' {
        $records.'StubResource4A_1.1' = $records.StubResources | ? {$_.Version -eq '1.1'}
        $records.'StubResource4A_1.1' |
            Should not beNullOrEmpty
    }
    It 'extract the second stub resource' {
        $records.'StubResource4A_1.0' = $records.StubResources | ? {$_.Version -eq '1.0'}
        $records.'StubResource4A_1.0' |
            Should not beNullOrEmpty
    }
}
Describe 'ConvertTo- and Remove-ZeroDscResourceModule' {
    It 'correctly creates a module' {
        $r = $records.'StubResource4A_1.1' | 
            ConvertTo-ZeroDscResourceModule
        $r | Should beOfType ([psmoduleinfo])
        $r.Name | Should be 'StubResource4A_1.1-Dyn'
        $r.ExportedCommands.Keys[0] | Should be 'StubResource4A'
    }
    It 'importing the module correctly creates a function' {
        $r = $records.'StubResource4A_1.1' |
            ConvertTo-ZeroDscResourceModule |
            Import-Module
        $r = Get-Item function:\StubResource4A
        $r.Name | Should be 'StubResource4A'
        $r.Module.Name | Should be 'StubResource4A_1.1-Dyn'
    }
    It 'removing returns nothing' {
        $r = $records.'StubResource4A_1.1' |
            Remove-ZeroDscResourceModule
        $r | Should beNullOrEmpty
    }
    It 'correctly removes the module' {
        $r = Get-Module 'StubResource4A_1.1-Dyn'
        $r | Should beNullOrEmpty        
    }
    It 'correctly removes a function' {
        { Get-Item function:\StubResource4A -ea Stop } |
            Should throw 'does not exist'
    }
}

Describe 'Get-DynamicModuleName' {
    It 'returns correct module name' {
        $r = $records.'StubResource4A_1.1' |
            Get-DynamicModuleName
        $r | Should be 'StubResource4A_1.1-Dyn'
    }
}