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
    It 'simulate step always invoked' {
        $h.InvokedCurrentStep = (Get-Module ZeroDsc).NewBoundScriptBlock({
            New-Object ConfigStep -Property @{ Invoked = $true }
        }).InvokeReturnAsIs()
    }
    It '.MoveNext()' {
        $h.e.MoveNext() | Should be $true
    }
    It 'enumerator at node of first resource' {
        $h.e.NodeEnumerator.Current.Key | Should be '[StubResource5]a'
    }
    It 'state PretestWaitForTestExternal' {
        $h.e.StateMachine.CurrentState.StateName | Should be 'PretestWaitForTestExternal'
    }
    It 'simulate Test- resource success' {
        $h.e.NodeEnumerator.Current.Value.Progress = 'Complete'
        $h.e.StateMachine.RaiseEvent('TestCompleteSuccess')
        $h.e.CurrentStep = $h.InvokedCurrentStep
    }
    It '.MoveNext()' {
        $h.e.MoveNext() | Should be $true
    }
    It 'enumerator at node of second resource' {
        $h.e.NodeEnumerator.Current.Key | Should be '[StubResource5]b'
    }
    It 'state PretestWaitForTestExternal' {
        $h.e.StateMachine.CurrentState.StateName | Should be 'PretestWaitForTestExternal'
    }
    It 'simulate Test- resource failure' {
        $h.e.StateMachine.RaiseEvent('TestCompleteFailure')
        $h.e.CurrentStep = $h.InvokedCurrentStep
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
        $h.e.CurrentStep = $h.InvokedCurrentStep
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
        $h.e.CurrentStep = $h.InvokedCurrentStep
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

Describe '.MoveNext() no step invokations' {
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
    Context 'Pretest' {
        It 'in correct state' {
            $h.e.NodeEnumerator.Current.Key | Should be '[StubResource5]a'
            $h.e.StateMachine.CurrentState.StateName | Should be 'PretestWaitForTestExternal'
        }
        It '.MoveNext()' {
            $h.e.MoveNext() | Should be $true
        }
        It 'progress changed to skipped' {
            $h.e.Nodes.'[StubResource5]a'.Progress | Should be 'skipped'
        }
        It 'moved to correct state' {
            $h.e.NodeEnumerator.Current.Key | Should be '[StubResource5]b'
            $h.e.StateMachine.CurrentState.StateName | Should be 'PretestWaitForTestExternal'
        }
        It 'progress changed to skipped' {
            $h.e.Nodes.'[StubResource5]a'.Progress | Should be 'skipped'
        }
    }
    Context 'Ended' {
        It '.MoveNext()' {
            $h.e.MoveNext() | Should be $false
        }
        It 'moved to correct state' {
            $h.e.StateMachine.CurrentState.StateName | Should be 'Ended'
        }
    }
}

Describe '.MoveNext() skip configure set invokation (no progress)' {
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
    Context 'Pretest' {
        It '.MoveNext()' { $h.e.MoveNext() | Should be $true }
        It '.Invoke()' { $h.e.Current.Invoke() | Should not beNullOrEmpty }
        It '.MoveNext()' { $h.e.MoveNext() | Should be $true }
        It '.Invoke()' { $h.e.Current.Invoke() | Should not beNullOrEmpty }
    }
    Context 'skipping invokation of Configure Set...' {
        It '.MoveNext()' { $h.e.MoveNext() | Should be $true }
        It 'in correct state' {
            $h.e.NodeEnumerator.Current.Key | Should be '[StubResource5]a'
            $h.e.StateMachine.CurrentState.StateName | Should be 'ConfigureWaitForSetExternal'
        }
    }
    Context '...skips invokation Configure Test' {
        It '.MoveNext()' { $h.e.MoveNext() | Should be $true }
        It 'in correct state' {
            $h.e.NodeEnumerator.Current.Key | Should be '[StubResource5]b'
            $h.e.StateMachine.CurrentState.StateName | Should be 'ConfigureWaitForSetExternal'
        }
        It 'node marked skipped' {
            $h.e.Nodes.'[StubResource5]a'.Progress | Should be 'Skipped'
        }
    }
    Context 'Set and Test of remaining node unaffected' {
        It '.Invoke()' { $h.e.Current.Invoke() | Should not beNullOrEmpty }
        It '.MoveNext()' { $h.e.MoveNext() | Should be $true }
        It '.Invoke()' { $h.e.Current.Invoke() | Should not beNullOrEmpty }
    }
    Context 'End' {
        It '.MoveNext()' { $h.e.MoveNext() | Should be $false }
    }
}

Describe '.MoveNext() skip configure set invokation (progress)' {
    $h = @{}
    It 'create test document' {
        $h.doc = New-ConfigDocument Name {
            Get-DscResource StubResource5 | Import-DscResource
            StubResource5 'a' @{ Mode = 'Normal' ; DependsOn = '[StubResource5]b' }
            StubResource5 'b' @{ Mode = 'Normal' }
            StubResource5 'c' @{ Mode = 'Normal' }
        } |
            ConvertTo-ConfigDocument
    }
    It 'New-' {
        $h.e = $h.doc | New-ConfigInstructionEnumerator
    }
    Context 'Pretest' {
        It '.MoveNext()' { $h.e.MoveNext() | Should be $true }
        It '.Invoke()' { $h.e.Current.Invoke() | Should not beNullOrEmpty }
        It '.MoveNext()' { $h.e.MoveNext() | Should be $true }
        It '.Invoke()' { $h.e.Current.Invoke() | Should not beNullOrEmpty }
        It '.MoveNext()' { $h.e.MoveNext() | Should be $true }
        It '.Invoke()' { $h.e.Current.Invoke() | Should not beNullOrEmpty }
    }
    Context 'Set/Test (no progress)' {
        It '.MoveNext()' { $h.e.MoveNext() | Should be $true }
        It '.Invoke()' { $h.e.Current.Invoke() | Should not beNullOrEmpty }
        It '.MoveNext()' { $h.e.MoveNext() | Should be $true }
        It '.Invoke()' { $h.e.Current.Invoke() | Should not beNullOrEmpty }
    }
    Context 'skipping invokation of Configure Set (progress)...' {
        It '.MoveNext()' { $h.e.MoveNext() | Should be $true }
        It 'in correct state' {
            $h.e.NodeEnumerator.Current.Key | Should be '[StubResource5]c'
            $h.e.StateMachine.CurrentState.StateName | Should be 'ConfigureProgressWaitForSetExternal'
        }
    }
    Context '...skips invokation Configure Test' {
        It '.MoveNext()' { $h.e.MoveNext() | Should be $true }
        It 'in correct state' {
            $h.e.NodeEnumerator.Current.Key | Should be '[StubResource5]a'
            $h.e.StateMachine.CurrentState.StateName | Should be 'ConfigureWaitForSetExternal'
        }
    }
    Context 'Set and Test of remaining node unaffected' {
        It '.Invoke()' { $h.e.Current.Invoke() | Should not beNullOrEmpty }
        It '.MoveNext()' { $h.e.MoveNext() | Should be $true }
        It '.Invoke()' { $h.e.Current.Invoke() | Should not beNullOrEmpty }
    }
    Context 'End' {
        It '.MoveNext()' { $h.e.MoveNext() | Should be $false }
    }
}

Describe '.MoveNext() skip configure test invokation (no progress)' {
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
    Context 'Pretest' {
        It '.MoveNext()' { $h.e.MoveNext() | Should be $true }
        It '.Invoke()' { $h.e.Current.Invoke() | Should not beNullOrEmpty }
        It '.MoveNext()' { $h.e.MoveNext() | Should be $true }
        It '.Invoke()' { $h.e.Current.Invoke() | Should not beNullOrEmpty }
    }
    Context 'skipping invokation of Configure Test (progress)...' {
        It '.MoveNext()' { $h.e.MoveNext() | Should be $true }
        It '.Invoke()' { $h.e.Current.Invoke() | Should not beNullOrEmpty }
        It '.MoveNext()' { $h.e.MoveNext() | Should be $true }
        It 'in correct state' {
            $h.e.NodeEnumerator.Current.Key | Should be '[StubResource5]a'
            $h.e.StateMachine.CurrentState.StateName | Should be 'ConfigureWaitForTestExternal'
        }
    }
    Context '...marks node as skipped.' {
        It '.MoveNext()' { $h.e.MoveNext() | Should be $true }
        It 'node marked as skipped' {
            $h.e.Nodes.'[StubResource5]a'.Progress | Should be 'skipped'
        }
        It 'in correct state' {
            $h.e.NodeEnumerator.Current.Key | Should be '[StubResource5]b'
            $h.e.StateMachine.CurrentState.StateName | Should be 'ConfigureWaitForSetExternal'
        }
    }
    Context 'Set and Test of remaining node unaffected' {
        It '.Invoke()' { $h.e.Current.Invoke() | Should not beNullOrEmpty }
        It '.MoveNext()' { $h.e.MoveNext() | Should be $true }
        It '.Invoke()' { $h.e.Current.Invoke() | Should not beNullOrEmpty }
    }
    Context 'End' {
        It '.MoveNext()' { $h.e.MoveNext() | Should be $false }
    }
}

Describe '.MoveNext() skip configure test invokation (progress)' {
    $h = @{}
    It 'create test document' {
        $h.doc = New-ConfigDocument Name {
            Get-DscResource StubResource5 | Import-DscResource
            StubResource5 'a' @{ Mode = 'Normal' ; DependsOn = '[StubResource5]b' }
            StubResource5 'b' @{ Mode = 'Normal' }
            StubResource5 'c' @{ Mode = 'Normal' }
        } |
            ConvertTo-ConfigDocument
    }
    It 'New-' {
        $h.e = $h.doc | New-ConfigInstructionEnumerator
    }
    Context 'Pretest' {
        It '.MoveNext()' { $h.e.MoveNext() | Should be $true }
        It '.Invoke()' { $h.e.Current.Invoke() | Should not beNullOrEmpty }
        It '.MoveNext()' { $h.e.MoveNext() | Should be $true }
        It '.Invoke()' { $h.e.Current.Invoke() | Should not beNullOrEmpty }
        It '.MoveNext()' { $h.e.MoveNext() | Should be $true }
        It '.Invoke()' { $h.e.Current.Invoke() | Should not beNullOrEmpty }
    }
    Context 'Set/Test (no progress)' {
        It '.MoveNext()' { $h.e.MoveNext() | Should be $true }
        It '.Invoke()' { $h.e.Current.Invoke() | Should not beNullOrEmpty }
        It '.MoveNext()' { $h.e.MoveNext() | Should be $true }
        It '.Invoke()' { $h.e.Current.Invoke() | Should not beNullOrEmpty }
    }
    Context 'skipping invokation of Configure Test (progress)...' {
        It '.MoveNext()' { $h.e.MoveNext() | Should be $true }
        It '.Invoke()' { $h.e.Current.Invoke() | Should not beNullOrEmpty }
        It '.MoveNext()' { $h.e.MoveNext() | Should be $true }
        It 'in correct state' {
            $h.e.NodeEnumerator.Current.Key | Should be '[StubResource5]c'
            $h.e.StateMachine.CurrentState.StateName | Should be 'ConfigureProgressWaitForTestExternal'
        }
    }
    Context '...marks node as skipped.' {
        It '.MoveNext()' { $h.e.MoveNext() | Should be $true }
        It 'node marked as skipped' {
            $h.e.Nodes.'[StubResource5]c'.Progress | Should be 'skipped'
        }
        It 'in correct state' {
            $h.e.NodeEnumerator.Current.Key | Should be '[StubResource5]a'
            $h.e.StateMachine.CurrentState.StateName | Should be 'ConfigureWaitForSetExternal'
        }
    }
    Context 'Set and Test of remaining node unaffected' {
        It '.Invoke()' { $h.e.Current.Invoke() | Should not beNullOrEmpty }
        It '.MoveNext()' { $h.e.MoveNext() | Should be $true }
        It '.Invoke()' { $h.e.Current.Invoke() | Should not beNullOrEmpty }
    }
    Context 'End' {
        It '.MoveNext()' { $h.e.MoveNext() | Should be $false }
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
    It 'simulate step always invoked' {
        $h.InvokedCurrentStep = (Get-Module ZeroDsc).NewBoundScriptBlock({
            New-Object ConfigStep -Property @{ Invoked = $true }
        }).InvokeReturnAsIs()
    }
    Context 'Pretest Test' {
        It '.MoveNext()' {
            $h.e.MoveNext() | Should be $true
        }
        It 'enumerator at node of first resource' {
            $h.e.NodeEnumerator.Current.Key | Should be '[StubResource5]a'
        }
        It 'correct state' {
            $h.e.StateMachine.CurrentState.StateName | Should be 'PretestWaitForTestExternal'
        }
        It '.CurrentStep is empty' {
            $h.e.CurrentStep | Should beNullOrEmpty
        }
        It 'returns exactly one ConfigStep object' {
            $h.PretestTest = Get-CurrentConfigStep -InputObject $h.e
            $h.PretestTest.Count | Should be 1
            $h.PretestTest.GetType() | Should be 'ConfigStep'
        }
        It 'a reference to the ConfigStep object is kept' {
            $h.e.CurrentStep -eq $h.PreTestTest | Should be $true
        }
        It 'populates Message' {
            $h.PretestTest.Message | Should match 'Test resource \[StubResource5\]a'
        }
        It 'populates verb' {
            $h.PretestTest.Verb | Should be 'Test'
        }
        It 'populates phase' {
            $h.PretestTest.Phase | Should match 'Pretest'
        }
        It 'populates action' {
            $h.PretestTest.Action | Should not beNullOrEmpty
        }
        It 'populates action args' {
            $h.PretestTest.ActionArgs | Should not beNullOrEmpty
        }
        It 'includes a reference to the state machine' {
            $h.PretestTest.StateMachine.GetType() | Should be 'StateMachine'
        }
    }
    Context 'Configure Set' {
        It '.MoveNext()' {
            $h.e.CurrentStep = $h.InvokedCurrentStep
            $h.e.StateMachine.RaiseEvent('TestCompleteSuccess')
            $h.e.MoveNext() | Should be $true
        }
        It '.CurrentStep is empty' {
            $h.e.CurrentStep | Should beNullOrEmpty
        }
        It '.MoveNext()' {
            $h.e.CurrentStep = $h.InvokedCurrentStep
            $h.e.StateMachine.RaiseEvent('TestCompleteSuccess')
            $h.e.MoveNext() | Should be $true
        }
        It 'enumerator at node of first resource' {
            $h.e.NodeEnumerator.Current.Key | Should be '[StubResource5]a'
        }
        It 'correct state' {
            $h.e.StateMachine.CurrentState.StateName | Should be 'ConfigureWaitForSetExternal'
        }
        It '.CurrentStep is empty' {
            $h.e.CurrentStep | Should beNullOrEmpty
        }
        It 'returns exactly one ConfigStep object' {
            $h.ConfigureSet = Get-CurrentConfigStep -InputObject $h.e
            $h.ConfigureSet.Count | Should be 1
            $h.ConfigureSet.GetType() | Should be 'ConfigStep'
        }
        It 'a reference to the ConfigStep object is kept' {
            $h.e.CurrentStep -eq $h.ConfigureSet | Should be $true
        }
        It 'populates Message' {
            $h.ConfigureSet.Message | Should match 'Set resource \[StubResource5\]a'
        }
        It 'populates verb' {
            $h.ConfigureSet.Verb | Should be 'Set'
        }
        It 'populates phase' {
            $h.ConfigureSet.Phase | Should match 'Configure'
        }
    }
    Context 'Configure Test' {
        It '.MoveNext()' {
            $h.e.CurrentStep = $h.InvokedCurrentStep
            $h.e.StateMachine.RaiseEvent('SetComplete')
            $h.e.MoveNext() | Should be $true
        }
        It 'enumerator at node of first resource' {
            $h.e.NodeEnumerator.Current.Key | Should be '[StubResource5]a'
        }
        It 'correct state' {
            $h.e.StateMachine.CurrentState.StateName | Should be 'ConfigureWaitForTestExternal'
        }
        It 'returns exactly one ConfigStep object' {
            $h.ConfigureTest = Get-CurrentConfigStep -InputObject $h.e
            $h.ConfigureTest.Count | Should be 1
            $h.ConfigureTest.GetType() | Should be 'ConfigStep'
        }
        It 'populates Message' {
            $h.ConfigureTest.Message | Should match 'Test resource \[StubResource5\]a'
        }
        It 'populates verb' {
            $h.ConfigureTest.Verb | Should be 'Test'
        }
        It 'populates phase' {
            $h.ConfigureTest.Phase | Should match 'Configure'
        }
    }
}

Describe 'Invoke-ConfigStep' {
    $h = @{}
    Context 'arrange' {
        It 'create test document' {
            $h.doc = New-ConfigDocument Name {
                Get-DscResource StubResource5 | Import-DscResource
                StubResource5 'a' @{ Mode = 'already set' }
                StubResource5 'b' @{ Mode = 'normal' }
                StubResource5 'c' @{ Mode = 'incorrigible' }
            } |
                ConvertTo-ConfigDocument
        }
        It 'New-' {
            $h.e = $h.doc | New-ConfigInstructionEnumerator
        }
        It '.MoveNext()' {
            $h.e.MoveNext() | Should be $true
        }
    }
    Context 'Pretest Test- Success' {
        It 'returns a test step' {
            $h.Step = Get-CurrentConfigStep -InputObject $h.e
            $h.Step.Verb | Should be 'Test'
            $h.Step.Phase | Should be 'Pretest'
        }
        It 'state machine initially has empty trigger queue' {
            $h.e.StateMachine.TriggerQueue.Count | Should be 0
        }
        It 'progress was initially pending' {
            $h.e.NodeEnumerator.Value.Progress | Should be 'Pending'
        }
        It 'invoked was initially false' {
            $h.e.CurrentStep.Invoked | Should be $false
        }
        It 'Invoke' {
            $h.TestResult = $h.Step | Invoke-ConfigStep
        }
        It 'correct event was raised' {
            $h.e.StateMachine.TriggerQueue.Count | Should be 1
            $h.e.StateMachine.TriggerQueue.Peek() | Should be 'TestCompleteSuccess'
        }
        It 'reports correct progress' {
            $h.e.NodeEnumerator.Value.Progress | Should be 'Complete'
        }
        It 'invoked was set to true' {
            $h.e.CurrentStep.Invoked | Should be $true
        }
        It 'returns exactly one result object' {
            $h.TestResult.Count | Should be 1
            $h.TestResult.GetType() | Should be ConfigStepResult
        }
        It 'populates message' {
            $h.TestResult.Message | Should match 'Test'
            $h.TestResult.Message | Should match '\[StubResource5\]a'
            $h.TestResult.Message | Should match 'Complete'
        }
        It 'populates result code' {
            $h.TestResult.Code | Should be 'Success'
        }
        It 'populates step' {
            $h.TestResult.Step.GetType() | Should be 'ConfigStep'
        }
    }
    Context 'Pretest Test- Failure' {
        It '.MoveNext()' {
            $h.e.MoveNext() | Should be $true
        }
        It 'returns correct step' {
            $h.Step = Get-CurrentConfigStep -InputObject $h.e
            $h.Step.Verb | Should be 'Test'
            $h.Step.Phase | Should be 'Pretest'
        }
        It 'state machine initially has empty trigger queue' {
            $h.e.StateMachine.TriggerQueue.Count | Should be 0
        }
        It 'progress was initially pending' {
            $h.e.NodeEnumerator.Value.Progress | Should be 'Pending'
        }
        It 'invoked was initially false' {
            $h.e.CurrentStep.Invoked | Should be $false
        }
        It 'Invoke' {
            $h.TestResult = $h.Step | Invoke-ConfigStep
        }
        It 'reports correct progress' {
            $h.e.NodeEnumerator.Value.Progress | Should be 'Pending'
        }
        It 'correct event was raised' {
            $h.e.StateMachine.TriggerQueue.Count | Should be 1
            $h.e.StateMachine.TriggerQueue.Peek() | Should be 'TestCompleteFailure'
        }
        It 'invoked was set to true' {
            $h.e.CurrentStep.Invoked | Should be $true
        }
        It 'populates message' {
            $h.TestResult.Message | Should match 'Test'
        }
        It 'populates result code' {
            $h.TestResult.Code | Should be 'Failure'
        }
    }
    Context 'Advance' {
        It '.MoveNext()' {
            $h.e.MoveNext() | Should be $true
        }
        It 'invoke the step' {
            Get-CurrentConfigStep -InputObject $h.e | 
                Invoke-ConfigStep
        }
    }
    Context 'Configure Set-' {
        It '.MoveNext()' {
            $h.e.MoveNext() | Should be $true
        }
        It 'returns correct step' {
            $h.Step = Get-CurrentConfigStep -InputObject $h.e
            $h.Step.Verb | Should be 'Set'
            $h.Step.Phase | Should be 'Configure'
        }
        It 'state machine initially has empty trigger queue' {
            $h.e.StateMachine.TriggerQueue.Count | Should be 0
        }
        It 'progress was initially pending' {
            $h.e.NodeEnumerator.Value.Progress | Should be 'Pending'
        }
        It 'Invoke' {
            $h.TestResult = $h.Step | Invoke-ConfigStep
        }
        It 'progress remains pending' {
            $h.e.NodeEnumerator.Value.Progress | Should be 'Pending'
        }
        It 'correct event was raised' {
            $h.e.StateMachine.TriggerQueue.Count | Should be 1
            $h.e.StateMachine.TriggerQueue.Peek() | Should be 'SetComplete'
        }
        It 'populates message' {
            $h.TestResult.Message | Should match 'Set'
        }
        It 'populates result code' {
            $h.TestResult.Code | Should be 'Complete'
        }
    }
    Context 'Configure Test- Success' {
        It '.MoveNext()' {
            $h.e.MoveNext() | Should be $true
        }
        It 'returns correct step' {
            $h.Step = Get-CurrentConfigStep -InputObject $h.e
            $h.Step.Verb | Should be 'Test'
            $h.Step.Phase | Should be 'Configure'
        }
        It 'state machine initially has empty trigger queue' {
            $h.e.StateMachine.TriggerQueue.Count | Should be 0
        }
        It 'progress was initially pending' {
            $h.e.NodeEnumerator.Value.Progress | Should be 'Pending'
        }
        It 'Invoke' {
            $h.TestResult = $h.Step | Invoke-ConfigStep
        }
        It 'reports correct progress' {
            $h.e.NodeEnumerator.Value.Progress | Should be 'Complete'
        }
        It 'correct event was raised' {
            $h.e.StateMachine.TriggerQueue.Count | Should be 1
            $h.e.StateMachine.TriggerQueue.Peek() | Should be 'TestCompleteSuccess'
        }
        It 'populates message' {
            $h.TestResult.Message | Should match 'Test'
        }
        It 'populates result code' {
            $h.TestResult.Code | Should be 'Success'
        }
    }
    Context 'Advance' {
        It '.MoveNext()' {
            $h.e.MoveNext() | Should be $true
        }
        It 'invoke the step' {
            Get-CurrentConfigStep -InputObject $h.e | 
                Invoke-ConfigStep
        }
    }
    Context 'Configure Test- Failure' {
        It '.MoveNext()' {
            $h.e.MoveNext() | Should be $true
        }
        It 'returns correct step' {
            $h.Step = Get-CurrentConfigStep -InputObject $h.e
            $h.Step.Verb | Should be 'Test'
            $h.Step.Phase | Should be 'Configure'
        }
        It 'state machine initially has empty trigger queue' {
            $h.e.StateMachine.TriggerQueue.Count | Should be 0
        }
        It 'progress was initially pending' {
            $h.e.NodeEnumerator.Value.Progress | Should be 'Pending'
        }
        It 'Invoke' {
            $h.TestResult = $h.Step | Invoke-ConfigStep
        }
        It 'reports correct progress' {
            $h.e.NodeEnumerator.Value.Progress | Should be 'Failed'
        }
        It 'correct event was raised' {
            $h.e.StateMachine.TriggerQueue.Count | Should be 1
            $h.e.StateMachine.TriggerQueue.Peek() | Should be 'TestCompleteFailure'
        }
        It 'populates message' {
            $h.TestResult.Message | Should match 'Test'
        }
        It 'populates result code' {
            $h.TestResult.Code | Should be 'Failure'
        }
    }
}
