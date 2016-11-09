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

Describe ConvertTo-ConfigDocument {
    It 'creates exactly one new object' {
        $r = New-ConfigDocument 'DocumentName' {} | ConvertTo-ConfigDocument
        $r.Count | Should be 1
    }
    It 'the object type is ConfigDocument' {
        $r = New-ConfigDocument 'DocumentName' {} | ConvertTo-ConfigDocument
        $r.GetType() | Should be 'ConfigDocument'
    }
    It 'correctly populates Name' {
        $r = New-ConfigDocument 'DocumentName' {} | ConvertTo-ConfigDocument
        $r.Name | Should be 'DocumentName'
    }
    InModuleScope ZeroDsc {
        Context 'convert config info and bind to resources' {
            $raw = New-ConfigDocument 'DocumentName' {
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
    }
    Context 'duplicate config paths' {
        $h = @{}
        It 'throws correct exception type' {
            $h.CallSite = & {$MyInvocation}            
            $raw = New-ConfigDocument 'DocumentName' {
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
        It 'throws correct exception type' {
            $h.CallSite = & {$MyInvocation}            
            $raw = New-ConfigDocument 'DocumentName' {
                Get-DscResource StubResource2A | Import-DscResource
                Get-DscResource StubResource2A | Import-DscResource
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
        It 'the exception shows the filename of the offending call' {}
        It 'the exception shows the line number of the offending call' {}
        It 'the exception contains an informative message' {
            $h.Exception.ToString() | Should match 'Duplicate resource named StubResource2A'
        }
    }
    InModuleScope ZeroDsc {
        Context 'bad resource binding' {
            $h = @{}
            Mock ConvertTo-BoundResource { throw 'mock resource binding exception message' }
            It 'throws correct exception type' {
                $h.CallSite = & {$MyInvocation}            
                $raw = New-ConfigDocument 'DocumentName' {
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
    }
}