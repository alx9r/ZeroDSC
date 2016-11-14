Import-Module ZeroDsc -Force

Describe 'Test Environment' {
    It 'add the test stubs to PSModulePath' {
        . "$($PSCommandPath | Split-Path -Parent)\..\Add-StubsToModulePath.ps1"
    }
}

Describe New-ProgressNodes {
    $h = @{}
    It 'create test document' {
        $h.ConfigDocument = New-ConfigDocument Name {
            Get-DscResource StubResource5 | Import-DscResource
            StubResource5 'a' @{ Mode = 'Normal' }
            StubResource5 'b' @{ Mode = 'Normal' }
        } |
            ConvertTo-ConfigDocument
    }
    It 'new' {
        $h.ProgressNodes = $h.ConfigDocument.Resources | New-ProgressNodes
    }
    It 'returns a dictionary object' {
        $h.ProgressNodes.GetType().ToString() | Should be 'System.Collections.Generic.Dictionary`2[System.String,ProgressNode]'
    }
    It 'populates Resources' {
        $h.ProgressNodes.'[StubResource5]a'.Resource.Config.ConfigName | Should be 'a'
        $h.ProgressNodes.'[StubResource5]b'.Resource.Config.ConfigName | Should be 'b'
    }
}

