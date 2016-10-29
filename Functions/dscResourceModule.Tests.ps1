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
Describe 'Import- and Remove-DscResource' {
    It 'Import- passes through the DscResourceInfo' {
        $r = $records.'StubResource4A_1.0' | Import-DscResource
        $r | Should be $records.'StubResource4A_1.0'
    }
    InModuleScope ZeroDsc {
        It 'correctly creates an alias' {
            Get-Alias StubResource4A -ea Stop
        }
        It 'the alias is for New-ResourceConfigInfo' {
            $r = Get-Alias StubResource4A -ea Stop
            $r.ResolvedCommandName | Should be New-ResourceConfigInfo
        }
    }
    It 'but not outside modulescope' {
        { Get-Alias StubResource4A -ea Stop } |
            Should throw 'cannot find a matching alias'
    }
    It 'Remove- returns nothing' {
        $r = $records.'StubResource4A_1.0' | Remove-DscResource
        $r | Should beNullOrEmpty
    }
    InModuleScope ZeroDsc {
        It 'correctly removes the alias'  {
            { Get-Alias StubResource4A -ea Stop } |
                Should throw 'cannot find a matching alias'
        }
    }
}
Describe 'sample configuration scriptblock' {
    InModuleScope ZeroDsc {
        $sb = {
            $records.'StubResource4A_1.0' | Import-DscResource

            StubResource4A ConfigName @{
                StringParam1 = 's1'
                BoolParam = $true
            }
        }
        It 'scriptblock returns items' {
            $records.SbResults = & $sb
        }
    }
    It 'items includes the DscResourceInfo object' {
        $records.SbResults[0] | Should be $records.'StubResource4A_1.0'
    }
    It 'items includes a ResourceConfigInfo object' {
        $records.SbResults[1].GetType() |
            Should be 'ResourceConfigInfo'
    }
}
