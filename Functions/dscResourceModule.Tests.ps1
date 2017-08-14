Import-Module ZeroDsc #-Force

InModuleScope ZeroDsc {

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
    It 'correctly creates an alias' {
        $records.'StubResource4A_1.0' | Import-DscResource
        Get-Alias StubResource4A -ea Stop
    }
    It 'the alias is for New-ResourceConfigInfo' {
        $records.'StubResource4A_1.0' | Import-DscResource
        $r = Get-Alias StubResource4A -ea Stop
        $r.ResolvedCommandName | Should be New-RawResourceConfigInfo
    }
    It 'but not outside modulescope' {
        { Get-Alias StubResource4A -ea Stop } |
            Should throw 'cannot find a matching alias'
    }
    It 'Remove- returns nothing' {
        $records.'StubResource4A_1.0' | Import-DscResource
        $r = $records.'StubResource4A_1.0' | Remove-DscResource -ea Stop
        $r | Should beNullOrEmpty
    }
    It 'correctly removes the alias'  {
        $records.'StubResource4A_1.0' | Import-DscResource
        $records.'StubResource4A_1.0' | Remove-DscResource
        { Get-Alias StubResource4A -ea Stop } |
            Should throw 'cannot find a matching alias'
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

Describe Test-DscResourceModuleLoaded {
    foreach ( $value in @(
            #         Paths      |  Result
            #   Module  Resource |
            @( 'c:\file.psm1', 'c:\file.psd1', $true ),
            @( 'c:\file.psd1', 'c:\file.psm1', $true ),
            @( 'c:\file.psm1', 'c:\otherfile.psm1', $false ),
            @( 'c:\file.psm1', 'c:\otherpath\file.psm1', $false)
        )
    )
    {
        $modulePath,$resourcePath,$result = $value
        Context "$modulePath, $resourcePath" {
            Mock Get-Module -Verifiable {
                New-Object psobject -Property @{ Path = $modulePath }
            }
            $resourceInfo = New-Object psobject -Property @{ Path = $resourcePath }
            It "returns $result" {
                $r = Test-DscResourceModuleLoaded $resourceInfo
                $r | Should be $result
            }
            It 'invoked Get-Module' {
                Assert-MockCalled Get-Module -Exactly -Times 1
            }
        }
    }
}
}
