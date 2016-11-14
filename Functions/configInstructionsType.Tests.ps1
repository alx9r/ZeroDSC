Import-Module ZeroDsc -Force

Describe 'Test Environment' {
    It 'add the test stubs to PSModulePath' {
        . "$($PSCommandPath | Split-Path -Parent)\..\Add-StubsToModulePath.ps1"
    }
}

Describe 'New-ConfigInstructionEnumerator' {
    $h = @{}
    It 'create test document' {
        $h.doc = New-ConfigDocument Name {
            Get-DscResource StubResource5 | Import-DscResource
            StubResource5 'a' @{ Mode = 'Normal' }
            StubResource5 'b' @{ Mode = 'Normal' }
        } |
            ConvertTo-ConfigDocument
    }
    It 'New-' {
        $h.e = $h.doc | New-ConfigInstructionEnumerator
    }
    It 'populates .Nodes' {
        $r = $h.e.Nodes
        $r.Count | Should be 2
        $r.'[StubResource5]a' | Should not beNullOrEmpty
    }
    It 'populates .NodeEnumerator' {
        $r = $h.e.NodeEnumerator
        $null -eq $r | Should be $false
        $r.GetType().ToString() | Should be 'System.Collections.Generic.Dictionary`2+Enumerator[System.String,ProgressNode]'
    }
    It 'populates .StateMachine' {
        $r = $h.e.StateMachine
        $r | Should not beNullOrEmpty
    }
    It 'starts .StateMachine' {
        $r = $h.e.StateMachine.TriggerQueue.Peek()
        $r | Should be 'Start'
    }
}

Describe '.MoveNext()' {
    $h = @{}
    It 'create test document' {
        $h.doc = New-ConfigDocument Name {
            Get-DscResource StubResource5 | Import-DscResource
            StubResource5 'a' @{ Mode = 'Normal' }
            StubResource5 'b' @{ Mode = 'Normal' }
        } |
            ConvertTo-ConfigDocument
    }
    It 'New-' {
        $h.e = $h.doc | New-ConfigInstructionEnumerator
    }
    It '.MoveNext()' {
        $h.e.MoveNext() | Should be $true
    }
    It 'enumerator at node of first resource' {
        $h.e.NodeEnumerator.Current.Key | Should be '[StubResource5]a'
    }
    It 'state PretestWaitForExternalTest' {
        $h.e.StateMachine.CurrentState.StateName | Should be 'PretestWaitForExternalTest'
    }
    It 'simulate Test- resource success' {
        $h.e.NodeEnumerator.Current.Value.Progress = 'Complete'
        $h.e.StateMachine.RaiseEvent('TestCompleteSuccess')
    }
    It '.MoveNext()' {
        $h.e.MoveNext() | Should be $true
    }
    It 'enumerator at node of second resource' {
        $h.e.NodeEnumerator.Current.Key | Should be '[StubResource5]b'
    }
    It 'state PretestWaitForExternalTest' {
        $h.e.StateMachine.CurrentState.StateName | Should be 'PretestWaitForExternalTest'
    }
    It 'simulate Test- resource failure' {
        $h.e.StateMachine.RaiseEvent('TestCompleteFailure')
    }
    It '.MoveNext()' {
        $h.e.MoveNext() | Should be $true
    }
    It 'enumerator at node of second resource' {
        $h.e.NodeEnumerator.Current.Key | Should be '[StubResource5]b'
    }
    It 'state ConfigureWaitForSetExternal' {
        $h.e.StateMachine.CurrentState.StateName | Should be 'ConfigureWaitForSetExternal'
    }
    It 'simulate Set- resource completion' {
        $h.e.StateMachine.RaiseEvent('SetComplete')
    }
    It '.MoveNext()' {
        $h.e.MoveNext() | Should be $true
    }
    It 'enumerator at node of second resource' {
        $h.e.NodeEnumerator.Current.Key | Should be '[StubResource5]b'
    }
    It 'state ConfigureWaitForTestExternal' {
        $h.e.StateMachine.CurrentState.StateName | Should be 'ConfigureWaitForTestExternal'
    }
    It 'simulate Test- resource success' {
        $h.e.NodeEnumerator.Current.Value.Progress = 'Complete'
        $h.e.StateMachine.RaiseEvent('TestCompleteSuccess')
    }
    It '.MoveNext()' {
        $h.e.MoveNext() | Should be $false
    }
    It 'enumerator at end of collection' {
        $h.e.NodeEnumerator.Current.Key | Should beNullOrEmpty
    }
    It 'state Ended' {
        $h.e.StateMachine.CurrentState.StateName | Should be 'Ended'
    }
}

Describe 'Get-CurrentConfigStep' {
    $h = @{}
    It 'create test document' {
        $h.doc = New-ConfigDocument Name {
            Get-DscResource StubResource5 | Import-DscResource
            StubResource5 'a' @{ Mode = 'Normal' }
            StubResource5 'b' @{ Mode = 'Normal' }
        } |
            ConvertTo-ConfigDocument
    }
    It 'New-' {
        $h.e = $h.doc | New-ConfigInstructionEnumerator
    }
    It 'returns $null' {
        $r = Get-CurrentConfigStep -InputObject $h.e
        $r | Should beNullOrEmpty
    }
    Context 'Pretest Test' {
        It '.MoveNext()' {
            $h.e.MoveNext() | Should be $true
        }
        It 'enumerator at node of second resource' {
            $h.e.NodeEnumerator.Current.Key | Should be '[StubResource5]a'
        }
        It 'state PretestWaitForExternalTest' {
            $h.e.StateMachine.CurrentState.StateName | Should be 'PretestWaitForExternalTest'
        }
        It 'returns exactly one ConfigStep object' {
            $h.Test = Get-CurrentConfigStep -InputObject $h.e
            $h.Test.Count | Should be 1
            $h.Test.GetType() | Should be 'ConfigStep'
        }
        It 'populates Message' {
            $h.Test.Message | Should match 'Test resource \[StubResource5\]a'
        }
        It 'populates phase' {
            $h.Test.Phase | Should match 'Pretest'
        }
        It 'populates action' {
            $h.Test.Action | Should not beNullOrEmpty
        }
    }
    Context 'Configure Set' {}
    Context 'Configure Test' {}
}