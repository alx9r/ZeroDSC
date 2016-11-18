Import-Module ZeroDsc -Force

Describe 'Test Environment' {
    It 'add the test stubs to PSModulePath' {
        . "$($PSCommandPath | Split-Path -Parent)\..\Add-StubsToModulePath.ps1"
    }
}

Describe 'ConfigInstructions as iEnumerable' {
    $h = @{}
    It 'create test document' {
        $h.doc = New-RawConfigDocument Name {
            Get-DscResource StubResource5 | Import-DscResource
            StubResource5 'a' @{ Mode = 'Normal' ; DependsOn = '[StubResource5]b' }
            StubResource5 'b' @{ Mode = 'Normal' }
        } |
            ConvertTo-ConfigDocument
    }
    It 'New-' {
        $h.Instructions = $h.doc | New-ConfigInstructions
    }
    Context 'foreach without invokation (1)' {
        $i = 0
        foreach ( $step in $h.Instructions )
        {
            It $step.Message {
                $step.GetType() | Should be 'ConfigStep'
            }
            $i++
        }
        $i | Should be 2
    }
    Context 'foreach without invokation (2)' {
        $i = 0
        foreach ( $step in $h.Instructions )
        {
            It $step.Message {
                $step.GetType() | Should be 'ConfigStep'
            }
            $i++
        }
        $i | Should be 2
    }
    Context 'foreach with invokation' {
        $i = 0
        foreach ( $step in $h.Instructions )
        {
            $h = @{}
            It "invoke $($step.Message)" {
                $h.r = $step.Invoke()
            }
            It "result is successful" {}
            $i++
        }
        $i | Should be 6
    }
}