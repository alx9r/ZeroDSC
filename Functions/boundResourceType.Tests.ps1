Import-Module ZeroDSC -Force

$records = @{}

Describe 'Test Environment' {
    It 'add the test stubs to PSModulePath' {
        . "$($PSCommandPath | Split-Path -Parent)\..\Add-StubsToModulePath.ps1"
    }
    It 'retrieve a DscResource' {
        $records.DscResource = Get-DscResource StubResource1A
        $records.MofDscResource = $records.DscResource
    }
    It 'retrieve another DscResource' {
        $records.ClassDscResource = Get-DscResource StubResource2A
    }
    It 'create a ResourceConfigInfo' {
        $records.ResourceConfigInfo =  & (Get-Module ZeroDsc).NewBoundScriptBlock({
            Set-Alias ResourceName New-RawResourceConfigInfo
            ResourceName ResourceConfigName @{
                StringParam1 = 's1'
                BoolParam = $true
            }
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
    It '...except when ConfigDocument is type AggregateConfigInfo' {

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
    Context 'invoker (stub)' {
        It 'correctly populates Invoker property' {
            $r = ConvertTo-BoundResource @resSplat
            $r.Invoker.ResourceInfo | Should be $resSplat.Resource
        }
    }
    InModuleScope ZeroDsc {
        Context 'invoker (mock)' {
            $res = Get-DscResource StubResource1A
            Mock New-ResourceInvoker -Verifiable {
                [ResourceInvoker]::new($res)
            }
            It 'correctly invokes New-ResourceInvoker' {
                $splat = @{
                    Resource = $res
                    Config = & (Get-Module ZeroDsc).NewBoundScriptBlock({
                        Set-Alias ResourceName New-RawResourceConfigInfo
                        ResourceName ResourceConfigName @{}
                    }) |
                        ConvertTo-ResourceConfigInfo
                }
                ConvertTo-BoundResource @splat
                Assert-MockCalled New-ResourceInvoker -Times 1 {
                    $DscResource.ResourceType -eq 'StubResource1A'
                }
            }
        }
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
Describe '.Invoke() stub' {
    foreach ( $typeName in 'Mof','Class' )
    {
        $splat = @{
            Resource = $records."$typeName`DscResource"
            Config = $records.ResourceConfigInfo
        }
        $res = ConvertTo-BoundResource @splat
        Context "correctly invokes the stub ($typeName Resource)" {
            It 'get' {
                $r = $res.Invoke('Get')
                $r.StringParam1 | Should be 's1'
            }
            It 'set' {
                $res.Invoke('Set')
            }
            It 'test' {
                $r = $res.Invoke('Test')
                $r | Should be $true
            }
        }
    }
}