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
            $r.ResolvedCommandName | Should be New-RawResourceConfigInfo
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
Describe 'Import-DscResource using sample configuration scriptblock' {
    It 'create the scriptblock' {
        $records.BoundScriptBlock = (Get-Module ZeroDsc).NewBoundScriptBlock({
            Get-DscResource StubResource4A |
                ? { $_.Version -eq '1.0' } |
                Import-DscResource

            StubResource4A ConfigName @{
                StringParam1 = 's1'
                BoolParam = $true
            }
        })
    }
    It 'returns items' {
        $records.SbResults2 = & $records.BoundScriptBlock
        $records.SbResults2 | Should not beNullOrEmpty
    }
    It 'items includes a DscResourceInfo object that seems right' {
        $records.SbResults2[0] | Should beOfType ([Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo])
        $records.SbResults2[0].ResourceType | Should be $records.'StubResource4A_1.0'.ResourceType
        $records.SbResults2[0].Path | Should be $records.'StubResource4A_1.0'.Path
    }
    It 'items includes a ResourceConfigInfo object' {
        $records.SbResults2[1].GetType() |
            Should be 'RawResourceConfigInfo'
    }    
}
