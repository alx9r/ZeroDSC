Import-Module ZeroDsc -Force

$records = @{}

Describe 'Test Environment' {
    It 'add the test stubs to PSModulePath' {
        . "$($PSCommandPath | Split-Path -Parent)\..\Add-StubsToModulePath.ps1"
    }
    It 'retrieve a DscResource' {
        $records.DscResource = Get-DscResource StubResource1A
    }
    It 'create a resourceConfigInfo' {
        $records.ResourceConfigInfo =  & {
            Set-Alias ResourceName New-ResourceConfigInfo
            ResourceName ConfigName @{}
        }
    }
}

Describe ConfigInfo {
    InModuleScope ZeroDsc {
        It 'creates new object' {
            $records.ConfigInfo = [ConfigInfo]::new('name')
        }
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
            $records.ConfigInfo.ResourceConfigs.'[ResourceName]ConfigName' |
                Should be $records.ResourceConfigInfo
        }
    }
    Context 'duplicates' {
        It 'throws on adding a duplicate' {
            { $records.ConfigInfo.Add( $records.ResourceConfigInfo ) } |
                Should throw 'same key'
        }
    }
}