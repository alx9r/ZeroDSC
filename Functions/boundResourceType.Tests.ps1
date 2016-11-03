Import-Module ZeroDSC -Force

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
        }) |
            ConvertTo-ResourceConfigInfo
    }
    It 'create an AggregateConfigInfo' {
        $records.AggregateConfigInfo =  & (Get-Module ZeroDsc).NewBoundScriptBlock({
            Set-Alias Aggregate New-RawResourceConfigInfo
            Aggregate AggregateConfigName @{}
        }) | 
            ConvertTo-ResourceConfigInfo
    }
}

Describe 'ConvertTo-BoundResource' {
    $resSplat = @{
        Resource = $records.DscResource
        Config = $records.ResourceConfigInfo
    }
    $aggSplat = @{
        Config = $records.AggregateConfigInfo
    }
    It 'creates exactly one new object' {
        $r = ConvertTo-BoundResource @resSplat
        $r.Count | Should be 1
    }
    It 'the object type is BoundResource...' {
        $r = ConvertTo-BoundResource @resSplat
        $r.GetType() | Should be 'BoundResource'
    }
    It '...except when ConfigInfo is type AggregateConfigInfo' {

        $r = ConvertTo-BoundResource @aggSplat
        $r.GetType() | Should be 'BoundAggregate'
    }
    It 'correctly populates Config property' {
        $r = ConvertTo-BoundResource @resSplat
        $r.Config | Should be $resSplat.Config
    }
    It 'correctly populates Resource property' {
        $r = ConvertTo-BoundResource @resSplat
        $r.Resource | Should be $resSplat.Resource
    }
    It 'throws when Resource is missing' {
        { ConvertTo-BoundResource -Config $records.ResourceConfigInfo } |
            Should throw 'Resource argument is missing'
    }
    It 'throws when Resource present for aggregate' {
        $splat = @{
            Resource = $records.DscResource
            Config = $records.AggregateConfigInfo
        }
        { ConvertTo-BoundResource @splat } |
            Should throw 'Resource argument was provided'
    }
}