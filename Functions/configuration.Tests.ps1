Import-Module ZeroDsc -Force

$records = @{}

Describe 'Test Environment' {
    It 'add the test stubs to PSModulePath' {
        . "$($PSCommandPath | Split-Path -Parent)\..\Add-StubsToModulePath.ps1"
    }
}

Describe 'Configuration sample' {
    It 'returns a ConfigInfo object' {
        $records.Sample1Result = zConfiguration ConfigName {
            Get-DscResource StubResource1A | Import-DscResource
            StubResource1A ResourceName @{
                StringParam1 = 's1'
                BoolParam = $true
            }
            Aggregate AggregateName @{
                StringParam1 = 's1'
                BoolParam = $true
            }
        }
        $records.Sample1Result |
            Should not beNullOrEmpty
    }
    It 'has the correct name' {
        $records.Sample1Result.Name |
            Should be 'ConfigName'
    }
    It 'has the correct DSC Resource' {
        $records.Sample1Result.DscResources[0].ResourceType |
            Should be StubResource1A
    }
    It 'has the correct resource in ResourceConfigs' {
        $r = $records.Sample1Result.ResourceConfigs[0]
        $r.Params.StringParam1 | Should be 's1'
        $r.Params.BoolParam | Should be $true
        $r.InvocationInfo.PositionMessage | Should match $($PSCommandPath | Split-Path -Leaf)
        $r.ConfigName | Should be ResourceName
    }
    It 'has the correct aggregate in ResourceConfigs' {
        $r = $records.Sample1Result.ResourceConfigs[1]
        $r.Params.StringParam1 | Should be 's1'
        $r.Params.BoolParam | Should be $true
        $r.InvocationInfo.PositionMessage | Should match $($PSCommandPath | Split-Path -Leaf)
        $r.ConfigName | Should be AggregateName
    }
}