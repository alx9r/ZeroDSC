Import-Module ZeroDsc -Force

$records = @{}

Describe 'Configuration sample' {
    $sb = {
        Get-DscResource StubResource1A | Import-DscResource
        StubResource1A ConfigName1 @{
            StringParam1 = 's1'
            BoolParam = $true
        }
    }
    It 'returns a ConfigInfo object' {
        $records.Sample1Result = zConfiguration ConfigName2 $sb
    }
    It 'has the correct name' {
        $records.Sample1Result.Name |
            Should be 'ConfigName2'
    }
    It 'has the correct DSC Resource' {
        $records.Sample1Result.DscResources.StubResource1A.ResourceType |
            Should be StubResource1A
    }
    It 'has the correct ResourceConfigInfo' {
        $r = $records.Sample1Result.ResourceConfigs.'[StubResource1A]ConfigName1'
        $r.Params.StringParam1 | Should be 's1'
        $r.Params.BoolParam | Should be $true
        $r.ResourceName | Should be StubResource1A
        $r.ConfigName | Should be ConfigName1
    }
}