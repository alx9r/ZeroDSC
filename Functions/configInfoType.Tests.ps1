Import-Module ZeroDsc -Force

$records = @{}

Describe 'Test Environment' {
    It 'add the test stubs to PSModulePath' {
        . "$($PSCommandPath | Split-Path -Parent)\..\Add-StubsToModulePath.ps1"
    }
    It 'retrieve a DscResource' {
        $records.DscResource = Get-DscResource StubResource1A
    }
    It 'create a ResourceConfigInfo' {
        $records.ResourceConfigInfo =  & (Get-Module ZeroDsc).NewBoundScriptBlock({
            Set-Alias ResourceName New-RawResourceConfigInfo
            ResourceName ResourceConfigName @{}
        })
    }
    It 'create an AggregateConfigInfo' {
        $records.AggregateConfigInfo =  & (Get-Module ZeroDsc).NewBoundScriptBlock({
            Set-Alias Aggregate New-RawResourceConfigInfo
            Aggregate AggregateConfigName @{}
        })
    }
}

Describe ConfigInfo {
    It 'creates new object' {
        $records.ConfigInfo = & (Get-Module ZeroDsc).NewBoundScriptBlock({
            [ConfigInfo]::new('name')
        })
    }
    It '.DscResources is initialized' {
        $null -ne $records.ConfigInfo.DscResources |
            Should be $true
    }
    It '.ResourceConfigs is initialized' {
        $null -ne $records.ConfigInfo.ResourceConfigs |
            Should be $true
    }
    Context '.Add()' {
        It '.DscResources starts out empty' {
            $records.ConfigInfo.DscResources.Count |
                Should be 0
        }
        It 'add a DSC resource' {
            $records.ConfigInfo.Add($records.DscResource)
        }
        It '.DscResources has one item' {
            $records.ConfigInfo.DscResources.Count |
                Should be 1
        }
        It 'retrieve that item by index' {
            $records.ConfigInfo.DscResources[0] |
                Should be $records.DscResource
        }
        It '.ResourceConfigs starts out empty' {
            $records.ConfigInfo.ResourceConfigs.Count |
                Should be 0
        }
        It 'add a ResourceConfigInfo object' {
            $records.ConfigInfo.Add( $records.ResourceConfigInfo )
        }
        It '.ResourceConfigs has one item' {
            $records.ConfigInfo.ResourceConfigs.Count |
                Should be 1
        }
        It 'retrieve that item by index' {
            $records.ConfigInfo.ResourceConfigs[0] |
                Should be $records.ResourceConfigInfo
        }
        It 'add an AggregateConfigInfo object' {
            $records.ConfigInfo.Add( $records.AggregateConfigInfo )
        }
        It '.ResourceConfigs has two items' {
            $records.ConfigInfo.ResourceConfigs.Count |
                Should be 2            
        }
        It 'retrieve that item by index' {
            $records.ConfigInfo.ResourceConfigs[1] |
                Should be $records.AggregateConfigInfo
        }
    }
}