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
            Set-Alias ResourceName New-ResourceConfigInfo
            ResourceName ResourceConfigName @{}
        })
    }
    It 'create an AggregateConfigInfo' {
        $records.AggregateConfigInfo =  & (Get-Module ZeroDsc).NewBoundScriptBlock({
            Set-Alias Aggregate New-ResourceConfigInfo
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
        $records.ConfigInfo.DscResources |
            Should not be $null
    }
    It '.ResourceConfigs is initialized' {
        $records.ConfigInfo.ResourceConfigs |
            Should not be $null
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
        It 'retrieve that item by name' {
            $records.ConfigInfo.DscResources.StubResource1A |
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
        It 'retrieve that item by name' {
            $records.ConfigInfo.ResourceConfigs.'[ResourceName]ResourceConfigName' |
                Should be $records.ResourceConfigInfo
        }
        It 'add an AggregateConfigInfo object' {
            $records.ConfigInfo.Add( $records.AggregateConfigInfo )
        }
        It '.ResourceConfigs has two items' {
            $records.ConfigInfo.ResourceConfigs.Count |
                Should be 2            
        }
        It 'retrieve that item by name' {
            $records.ConfigInfo.ResourceConfigs.'[Aggregate]AggregateConfigName' |
                Should be $records.AggregateConfigInfo
        }
    }
    Context 'duplicates' {
        It 'throws on adding a duplicate' {
            { $records.ConfigInfo.Add( $records.ResourceConfigInfo ) } |
                Should throw 'same key'
        }
    }
}