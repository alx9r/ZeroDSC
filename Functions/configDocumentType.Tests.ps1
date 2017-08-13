Import-Module ZeroDsc -Force

InModuleScope ZeroDsc {

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

Describe RawConfigDocument {
    It 'creates new object' {
        $records.RawConfigDocument = & (Get-Module ZeroDsc).NewBoundScriptBlock({
            [RawConfigDocument]::new('name')
        })
    }
    It '.DscResources is initialized' {
        $null -ne $records.RawConfigDocument.DscResources |
            Should be $true
    }
    It '.ResourceConfigs is initialized' {
        $null -ne $records.RawConfigDocument.ResourceConfigs |
            Should be $true
    }
    Context '.Add()' {
        It '.DscResources starts out empty' {
            $records.RawConfigDocument.DscResources.Count |
                Should be 0
        }
        It 'add a DSC resource' {
            $records.RawConfigDocument.Add($records.DscResource)
        }
        It '.DscResources has one item' {
            $records.RawConfigDocument.DscResources.Count |
                Should be 1
        }
        It 'retrieve that item by index' {
            $records.RawConfigDocument.DscResources[0] |
                Should be $records.DscResource
        }
        It '.ResourceConfigs starts out empty' {
            $records.RawConfigDocument.ResourceConfigs.Count |
                Should be 0
        }
        It 'add a ResourceConfigInfo object' {
            $records.RawConfigDocument.Add( $records.ResourceConfigInfo )
        }
        It '.ResourceConfigs has one item' {
            $records.RawConfigDocument.ResourceConfigs.Count |
                Should be 1
        }
        It 'retrieve that item by index' {
            $records.RawConfigDocument.ResourceConfigs[0] |
                Should be $records.ResourceConfigInfo
        }
        It 'add an AggregateConfigInfo object' {
            $records.RawConfigDocument.Add( $records.AggregateConfigInfo )
        }
        It '.ResourceConfigs has two items' {
            $records.RawConfigDocument.ResourceConfigs.Count |
                Should be 2
        }
        It 'retrieve that item by index' {
            $records.RawConfigDocument.ResourceConfigs[1] |
                Should be $records.AggregateConfigInfo
        }
    }
}

Describe New-RawConfigDocument {
    It 'returns exactly one object of correct type' {
        $r = New-RawConfigDocument ConfigName {}
        $r.Count | Should be 1
        $r.GetType() | Should be 'RawConfigDocument'
    }
    It 'correctly populates name' {
        $r = New-RawConfigDocument ConfigName {}
        $r.Name | Should be 'ConfigName'
    }
    It 'correctly adds an object' {
        $r = New-RawConfigDocument ConfigName { Get-DscResource StubResource1A }
        $r.DscResources.Count | Should be 1
        $r.DscResources[0].Name | Should be 'StubResource1AFriendlyName'
    }
    Context 'emits invalid object type' {
        It 'throws correct exception type' {
            {
                New-RawConfigDocument ConfigName { @{} }
            } |
                Should throw 'Invalid object type System.Collections.Hashtable'
        }
        It 'the exception shows the filename of the offending call' {}
        It 'the exception shows the line number of the offending call' {}
        It 'the exception contains an informative message' {}
    }
}

Describe 'Configuration sample' {
    It 'returns a ConfigDocument object' {
        $records.Sample1Result = New-RawConfigDocument ConfigName {
            $r = Get-DscResource StubResource2A
            $r | Import-DscResource
            StubResource2A ResourceName @{
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
        $records.Sample1Result.DscResources[0].Name |
            Should be 'StubResource2A'
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

Describe ConvertTo-ConfigDocument {
    It 'creates exactly one new object' {
        $r = New-RawConfigDocument 'DocumentName' {} | ConvertTo-ConfigDocument
        $r.Count | Should be 1
    }
    It 'the object type is ConfigDocument' {
        $r = New-RawConfigDocument 'DocumentName' {} | ConvertTo-ConfigDocument
        $r.GetType() | Should be 'ConfigDocument'
    }
    It 'correctly populates Name' {
        $r = New-RawConfigDocument 'DocumentName' {} | ConvertTo-ConfigDocument
        $r.Name | Should be 'DocumentName'
    }
    Context 'convert config info and bind to resources' {
        $raw = New-RawConfigDocument 'DocumentName' {
            Get-DscResource StubResource2A | Import-DscResource
            Get-DscResource StubResource2B | Import-DscResource
            StubResource2A ConfigName2A @{}
        }
        Mock ConvertTo-ResourceConfigInfo -Verifiable {
            $o = [ResourceConfigInfo]::new()
            $o.ConfigName = 'ConfigName2A'
            $o.ResourceName = 'StubResource2A'
            $o
        }
        Mock ConvertTo-BoundResource -Verifiable {
            $o = [BoundResourceBase]::new()
            $o.Config = $Config
            $o
        }
        It 'correctly invokes ConvertTo-ResourceConfigInfo' {
            $raw | ConvertTo-ConfigDocument
            Assert-MockCalled ConvertTo-ResourceConfigInfo -Times 1 {
                $InputObject.ConfigName -eq 'ConfigName2A'
            }
        }
        It 'correctly passes that result and the correct resource type to ConvertTo-BoundResource' {
            Assert-MockCalled ConvertTo-BoundResource -Times 1 {
                $Config.ConfigName -eq 'ConfigName2A' -and
                $Resource.Name -eq 'StubResource2A'
            }
        }
        It 'correctly adds result of ConvertTo-BoundResource to Resources' {
            $o = $raw | ConvertTo-ConfigDocument
            $r = $o.Resources.'[StubResource2A]ConfigName2A'
            $r.Config.ConfigName | Should be 'ConfigName2A'
            $r.Config.ResourceName | Should be 'StubResource2A'
        }
    }
    Context 'duplicate config paths' {
        $h = @{}
        It 'throws correct exception type' {
            $h.CallSite = & {$MyInvocation}
            $raw = New-RawConfigDocument 'DocumentName' {
                Get-DscResource StubResource2A | Import-DscResource
                StubResource2A ConfigName2A @{}
                StubResource2A ConfigName2A @{}
            }
            try
            {
                $raw | ConvertTo-ConfigDocument
            }
            catch [FormatException]
            {
                $h.Exception = $_
            }
            $h.Exception | Should not beNullOrEmpty
        }
        It 'the exception shows the filename of the offending call' {
            $h.Exception.ToString() | Should match ($PSCommandPath | Split-Path -Leaf)
        }
        It 'the exception shows the line number of the offending call' {
            $h.Exception.ToString() | Should match ":$($h.CallSite.ScriptLineNumber+4)"
        }
        It 'the exception contains an informative message' {
            $h.Exception.ToString() | Should match 'Duplicate ConfigPath \[StubResource2A\]ConfigName2A'
        }
    }
    Context 'duplicate Resources' {
        $h = @{}
        It 'tolerates exact duplicates' {
            $raw = New-RawConfigDocument 'DocumentName' {
                Get-DscResource StubResource2A | Import-DscResource
                Get-DscResource StubResource2A | Import-DscResource
                StubResource2A ConfigName2A @{}
            }
            $r = $raw | ConvertTo-ConfigDocument
            $r.Resources.Count | Should be 1
            $r.Resources.Keys[0] | Should be '[StubResource2A]ConfigName2A'
        }
        It 'binds to the later version...' {
            $raw = New-RawConfigDocument 'DocumentName' {
                Get-DscResource StubResource4A | ? {$_.Version -eq '1.1'} | Import-DscResource
                Get-DscResource StubResource4A | ? {$_.Version -eq '1.0'} | Import-DscResource
                StubResource4A ConfigName4A @{}
            }
            $r = $raw | ConvertTo-ConfigDocument
            $r.Resources.Count | Should be 1
            $r.Resources.'[StubResource4A]ConfigName4A'.Resource.Version |
                Should be '1.1'
        }
        It '...regardless of order encountered' {
            $raw = New-RawConfigDocument 'DocumentName' {
                Get-DscResource StubResource4A | ? {$_.Version -eq '1.0'} | Import-DscResource
                Get-DscResource StubResource4A | ? {$_.Version -eq '1.1'} | Import-DscResource
                StubResource4A ConfigName4A @{}
            }
            $r = $raw | ConvertTo-ConfigDocument
            $r.Resources.Count | Should be 1
            $r.Resources.'[StubResource4A]ConfigName4A'.Resource.Version |
                Should be '1.1'
        }
    }
    Context 'bad resource binding' {
        $h = @{}
        Mock ConvertTo-BoundResource { throw 'mock resource binding exception message' }
        It 'throws correct exception type' {
            $h.CallSite = & {$MyInvocation}
            $raw = New-RawConfigDocument 'DocumentName' {
                Set-Alias ResourceName New-RawResourceConfigInfo
                ResourceName ResourceConfigName @{}
            }
            try
            {
                $raw | ConvertTo-ConfigDocument
            }
            catch [FormatException]
            {
                $h.Exception = $_
            }
            $h.Exception | Should not beNullOrEmpty
        }
        It 'the exception shows the filename of the offending call' {
            $h.Exception.ToString() | Should match ($PSCommandPath | Split-Path -Leaf)
        }
        It 'the exception shows the line number of the offending call' {
            $h.Exception.ToString() | Should match ":$($h.CallSite.ScriptLineNumber+3)"
        }
        It 'the exception contains an informative message' {
            $h.Exception.ToString() | Should match 'Error binding Config \[ResourceName\]ResourceConfigName to resource ResourceName'
        }
    }
    Context 'DependsOn points to non-existent resource' {
        It 'throws correct exception type' {}
        It 'the exception shows the filename of the offending call' {}
        It 'the exception shows the line number of the offending call' {}
        It 'the exception contains an informative message' {}
    }
    Context 'DependsOn points to itself' {
        It 'throws correct exception type' {}
        It 'the exception shows the filename of the offending call' {}
        It 'the exception shows the line number of the offending call' {}
        It 'the exception contains an informative message' {}
    }
}
}
