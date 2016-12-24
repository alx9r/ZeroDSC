Import-Module ZeroDsc -Force

InModuleScope ZeroDsc {

Describe 'Test Environment' {
    It 'add the test stubs to PSModulePath' {
        . "$($PSCommandPath | Split-Path -Parent)\..\Add-StubsToModulePath.ps1"
    }
}

Describe 'New-ConfigInstructionEnumerator' {
    $h = @{}
    It 'create test document' {
        $h.doc = New-RawConfigDocument Name {
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

$tests = [ordered]@{
    Basic = @{
        ConfigDocument = {
            Get-DscResource StubResource5 | Import-DscResource
            StubResource5 'a' @{ Mode = 'Normal'; DependsOn = '[StubResource5]b' }
            StubResource5 'b' @{ Mode = 'Normal' }
        }
        Values = @(
            # NodeKey           | StateName                    | Node Progress | Raise Event
            @('[StubResource5]a','PretestWaitForTestExternal',  'Complete',      'TestCompleteSuccess' ),
            @('[StubResource5]b','PretestWaitForTestExternal',  $null,           'TestCompleteFailure' ),
            @('[StubResource5]b','ConfigureWaitForSetExternal', $null,           'SetComplete' ),
            @('[StubResource5]b','ConfigureWaitForTestExternal','Complete',      'TestCompleteSuccess'),
            @($null,            ,'Ended' )
        )
    }
    'Progress causes results in second pass' = @{
        ConfigDocument = {
            Get-DscResource StubResource5 | Import-DscResource
            StubResource5 'a' @{ Mode = 'Normal'; DependsOn = '[StubResource5]b' }
            StubResource5 'b' @{ Mode = 'Normal' }
        }
        Values = @(
            @('[StubResource5]a','PretestWaitForTestExternal',  $null,           'TestCompleteFailure' ),
            @('[StubResource5]b','PretestWaitForTestExternal',  $null,           'TestCompleteFailure' ),
            @('[StubResource5]b','ConfigureWaitForSetExternal', $null,           'SetComplete' ),
            @('[StubResource5]b','ConfigureWaitForTestExternal','Complete',      'TestCompleteSuccess'),
            @('[StubResource5]a','ConfigureWaitForSetExternal', $null,           'SetComplete' ),
            @('[StubResource5]a','ConfigureWaitForTestExternal','Complete',      'TestCompleteSuccess'),
            @($null,            ,'Ended' )
        )
    }
    'Progress ending with incorrigible' = @{
        ConfigDocument = {
            Get-DscResource StubResource5 | Import-DscResource
            StubResource5 'a' @{ Mode = 'already set' }
            StubResource5 'b' @{ Mode = 'normal' }
            StubResource5 'c' @{ Mode = 'incorrigible' }
        }
        Values = @(
            @('[StubResource5]a','PretestWaitForTestExternal',          'Complete',    'TestCompleteSuccess'),
            @('[StubResource5]b','PretestWaitForTestExternal',          'Pending',     'TestCompleteFailure'),
            @('[StubResource5]c','PretestWaitForTestExternal',          'Pending',     'TestCompleteFailure'),
            @('[StubResource5]b','ConfigureWaitForSetExternal',         'Pending',     'SetComplete'),
            @('[StubResource5]b','ConfigureWaitForTestExternal',        'Complete',    'TestCompleteSuccess'),
            @('[StubResource5]c','ConfigureProgressWaitForSetExternal', 'Pending',     'SetComplete'),
            @('[StubResource5]c','ConfigureProgressWaitForTestExternal','Failed',      'TestCompleteFailure'),
            @($null,            ,'Ended')
        )
    }
    'Exception during Pretest' = @{
        ConfigDocument = {
            Get-DscResource StubResource5 | Import-DscResource
            StubResource5 'a' @{ Mode = 'Normal'; DependsOn = '[StubResource5]b' }
            StubResource5 'b' @{ Mode = 'Normal' }
        }
        Values = @(
            # NodeKey           | StateName                    | Node Progress | Raise Event
            @('[StubResource5]a','PretestWaitForTestExternal',  'Complete',      'TestCompleteSuccess' ),
            @('[StubResource5]b','PretestWaitForTestExternal',  'Exception',     'TestThrew' ),
            @($null,            ,'Ended' )
        )
    }
    'Exception during Configure Test' = @{
        ConfigDocument = {
            Get-DscResource StubResource5 | Import-DscResource
            StubResource5 'a' @{ Mode = 'Normal'; DependsOn = '[StubResource5]b' }
            StubResource5 'b' @{ Mode = 'Normal' }
        }
        Values = @(
            # NodeKey           | StateName                    | Node Progress | Raise Event
            @('[StubResource5]a','PretestWaitForTestExternal',  'Complete',      'TestCompleteSuccess' ),
            @('[StubResource5]b','PretestWaitForTestExternal',  $null,           'TestCompleteFailure' ),
            @('[StubResource5]b','ConfigureWaitForSetExternal', $null,           'SetComplete' ),
            @('[StubResource5]b','ConfigureWaitForTestExternal','Exception',     'TestThrew'),
            @($null,            ,'Ended' )
        )
    }
    'Exception during Configure Set' = @{
        ConfigDocument = {
            Get-DscResource StubResource5 | Import-DscResource
            StubResource5 'a' @{ Mode = 'Normal'; DependsOn = '[StubResource5]b' }
            StubResource5 'b' @{ Mode = 'Normal' }
        }
        Values = @(
            # NodeKey           | StateName                    | Node Progress | Raise Event
            @('[StubResource5]a','PretestWaitForTestExternal',  'Complete',      'TestCompleteSuccess' ),
            @('[StubResource5]b','PretestWaitForTestExternal',  $null,           'TestCompleteFailure' ),
            @('[StubResource5]b','ConfigureWaitForSetExternal', 'Exception',      'SetThrew' ),
            @('[StubResource5]b','ConfigureWaitForTestExternal','Complete',      'TestCompleteSuccess'),
            @($null,            ,'Ended' )
        )
    }
    'Skip All' = @{
        ConfigDocument = {
            Get-DscResource StubResource5 | Import-DscResource
            StubResource5 'a' @{ Mode = 'Normal'; DependsOn = '[StubResource5]b' }
            StubResource5 'b' @{ Mode = 'Normal' }
        }
        Values = @(
            @('[StubResource5]a','PretestWaitForTestExternal',  'Skipped',       'StepSkipped' ),
            @('[StubResource5]b','PretestWaitForTestExternal',  'Skipped',       'StepSkipped' ),
            @($null,            ,'Ended' )
        )
    }
    'Skip a Pretest' = @{
        ConfigDocument = {
            Get-DscResource StubResource5 | Import-DscResource
            StubResource5 'a' @{ Mode = 'Normal'; DependsOn = '[StubResource5]b' }
            StubResource5 'b' @{ Mode = 'Normal' }
        }
        Values = @(
            @('[StubResource5]a','PretestWaitForTestExternal',  'Skipped',       'StepSkipped' ),
            @('[StubResource5]b','PretestWaitForTestExternal',  $null,           'TestCompleteFailure' ),
            @('[StubResource5]b','ConfigureWaitForSetExternal', $null,           'SetComplete' ),
            @('[StubResource5]b','ConfigureWaitForTestExternal','Complete',      'TestCompleteSuccess'),
            @($null,            ,'Ended' )
        )
    }
    'Skip a Configure Set' = @{
        ConfigDocument = {
            Get-DscResource StubResource5 | Import-DscResource
            StubResource5 'a' @{ Mode = 'Normal'; DependsOn = '[StubResource5]b' }
            StubResource5 'b' @{ Mode = 'Normal' }
        }
        Values = @(
            @('[StubResource5]a','PretestWaitForTestExternal',  'Complete',      'TestCompleteSuccess' ),
            @('[StubResource5]b','PretestWaitForTestExternal',  $null,           'TestCompleteFailure' ),
            @('[StubResource5]b','ConfigureWaitForSetExternal', 'Skipped',       'StepSkipped' ),
            @($null,            ,'Ended' )
        )
    }
    'Skip a Configure Test' = @{
        ConfigDocument = {
            Get-DscResource StubResource5 | Import-DscResource
            StubResource5 'a' @{ Mode = 'Normal'; DependsOn = '[StubResource5]b' }
            StubResource5 'b' @{ Mode = 'Normal' }
        }
        Values = @(
            @('[StubResource5]a','PretestWaitForTestExternal',  'Complete',      'TestCompleteSuccess' ),
            @('[StubResource5]b','PretestWaitForTestExternal',  $null,           'TestCompleteFailure' ),
            @('[StubResource5]b','ConfigureWaitForSetExternal', $null,           'SetComplete' ),
            @('[StubResource5]b','ConfigureWaitForTestExternal','Skipped',       'StepSkipped'),
            @($null,            ,'Ended' )
        )
    }
}
foreach ( $testName in $tests.Keys )
{
    Describe "ConfigInstructionEnumerator.MoveNext() using simulated ConfigStep ($testName)" {
        $h = @{}
        It 'create test document' {
            $h.doc = New-RawConfigDocument Name $tests.$testName.ConfigDocument |
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
        $i = 0
        foreach
        (
            $value in $tests.$testName.Values
        )
        {
            $nodeKey,$stateName,$nodeProgress,$raiseEvent = $value
            Context "Step $i" {
                $moveNextResult = [bool]($stateName -ne 'Ended')
                It ".MoveNext() returns $moveNextResult" {
                    $h.e.MoveNext() | Should be $moveNextResult
                }
                It "enumerator at node $nodeKey" {
                    $h.e.NodeEnumerator.Key | Should be $nodeKey
                }
                It "state machine in state $stateName" {
                    $h.e.StateMachine.CurrentState.StateName | Should be $stateName
                }
                if ( $nodeProgress )
                {
                    It "simulate node progressing to $nodeProgress" {
                        $h.e.NodeEnumerator.Current.Value.Progress = $nodeProgress
                    }
                }
                if ( $raiseEvent )
                {
                    It "simulate raising event $raiseEvent" {
                        $h.e.StateMachine.RaiseEvent($raiseEvent)
                    }
                }
                It 'simulate CurrentStep being tagged as invoked' {
                    $h.e.CurrentStep = $h.InvokedCurrentStep
                }
            }
            $i ++
        }
    }
}

Describe 'Get-CurrentConfigStep' {
    $h = @{}
    It 'create test document' {
        $h.doc = New-RawConfigDocument Name {
            Get-DscResource StubResource5 | Import-DscResource
            StubResource5 'a' @{ Mode = 'Normal' }
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
    $i = 0
    foreach ( $value in @(
            # nodeKey           | StateName                      | Event Name         | Progress  | Verb  | Phase     | Message
            @('[StubResource5]a','PretestWaitForTestExternal',   'TestCompleteFailure', $null,      'Test', 'PreTest',  'Test resource \[StubResource5\]a'),
            @('[StubResource5]a','ConfigureWaitForSetExternal',  'SetComplete',         $null,      'Set',  'Configure','Set resource \[StubResource5\]a'),
            @('[StubResource5]a','ConfigureWaitForTestExternal', 'TestCompleteSuccess', 'Complete', 'Test', 'Configure','Test resource \[StubResource5\]a'),
            @($null             ,'Ended' )
        )
    )
    {
        $nodeKey,$stateName,$eventName,$progress,$verb,$phase,$message = $value
        Context "Step $i" {
            $moveNextResult = [bool]($stateName -ne 'Ended')
            It ".MoveNext() returns $moveNextResult" {
                $h.e.MoveNext() | Should be $moveNextResult
            }
            It "enumerator at node $nodeKey" {
                $h.e.NodeEnumerator.Key | Should be $nodeKey
            }
            It "state machine in state $stateName" {
                $h.e.StateMachine.CurrentState.StateName | Should be $stateName
            }
            if ( $stateName -ne 'Ended' )
            {
                It 'returns exactly one ConfigStep object' {
                    $h.Step = Get-CurrentConfigStep -InputObject $h.e
                    $h.Step.Count | Should be 1
                    $h.Step.GetType() | Should be 'ConfigStep'
                }
                It 'a reference to the ConfigStep object is kept' {
                    $h.e.CurrentStep -eq $h.Step | Should be $true
                }
                It 'populates ResourceName' {
                    $h.Step.ResourceName | Should be $nodeKey
                }
                It 'populates Message' {
                    $h.Step.Message | Should match $message
                }
                It 'populates verb' {
                    $h.Step.Verb | Should be $verb
                }
                It 'populates phase' {
                    $h.Step.Phase | Should match $phase
                }
                It 'populates action' {
                    $h.Step.Action | Should not beNullOrEmpty
                }
                It 'populates action args' {
                    $h.Step.ActionArgs | Should not beNullOrEmpty
                }
                It 'populates node' {
                    $h.Step.Node | Should be $h.e.NodeEnumerator.Value
                }
                It 'includes a reference to the state machine' {
                    $h.Step.StateMachine.GetType() | Should be 'StateMachine'
                }
                It 'simulate invokation of current step' {
                    $h.e.CurrentStep = $h.InvokedCurrentStep
                    if ( $progress )
                    {
                        $h.e.NodeEnumerator.Value.Progress = $progress
                    }
                    $h.e.StateMachine.RaiseEvent($eventName)
                }
            }
            else
            {
                It 'it returns nothing' {
                    $h.Step = Get-CurrentConfigStep -InputObject $h.e
                    $h.Step | Should beNullOrEmpty
                }
            }
        }
        $i ++
    }
}

Describe 'Invoke-ConfigStep' {
    $h = @{}
    Context 'arrange' {
        It 'create test document' {
            $h.doc = New-RawConfigDocument Name {
                Get-DscResource StubResource5 | Import-DscResource
#                Get-DscResource TestStub | Import-DscResource
                StubResource5 'a' @{ Mode = 'already set' }
                StubResource5 'b' @{ Mode = 'normal' }
                StubResource5 'c' @{ Mode = 'incorrigible' }
#                TestStub 'd' @{ Key = 'd'; ThrowOnTest = 'always' }
#                TestStub 'e' @{ Key = 'e'; ThrowOnSet = 'always' }
            } |
                ConvertTo-ConfigDocument
        }
        It 'New-' {
            $h.e = $h.doc | New-ConfigInstructionEnumerator
        }
    }
    $i = 0
    foreach ( $value in @(
            # nodeKey           | StateName                             | EventName            | ProgressBefore | ProgressAfter | Result | Verb  | Phase
            @('[StubResource5]a','PretestWaitForTestExternal',          'TestCompleteSuccess',  'Pending',       'Complete',      $true,  'Test', 'PreTest' ),
            @('[StubResource5]b','PretestWaitForTestExternal',          'TestCompleteFailure',  'Pending',       'Pending',       $false, 'Test', 'PreTest' ),
            @('[StubResource5]c','PretestWaitForTestExternal',          'TestCompleteFailure',  'Pending',       'Pending',       $false, 'Test', 'PreTest' ),
#            @('[TestStub]d',     'PretestWaitForTestExternal',          'TestThrew',            'Pending',       'Exception',     $null,  'Test', 'PreTest' ),
#            @('[TestStub]e',     'PretestWaitForTestExternal',          'TestCompleteFailure',  'Pending',       'Pending',       $false, 'Test', 'PreTest' ),
            @('[StubResource5]b','ConfigureWaitForSetExternal',         'SetComplete',          'Pending',       'Pending',       $null,  'Set',  'Configure' ),
            @('[StubResource5]b','ConfigureWaitForTestExternal',        'TestCompleteSuccess',  'Pending',       'Complete',      $true,  'Test', 'Configure' ),
            @('[StubResource5]c','ConfigureProgressWaitForSetExternal', 'SetComplete',          'Pending',       'Pending',       $null,  'Set',  'Configure' ),
            @('[StubResource5]c','ConfigureProgressWaitForTestExternal','TestCompleteFailure',  'Pending',       'Failed',        $false, 'Test', 'Configure' ),
#            @('[TestStub]e',     'ConfigureProgressWaitForSetExternal', 'SetThrew',             'Pending',       'Exception',     $null,  'Set',  'Configure' ),
#            @('[TestStub]e',     'ConfigureProgressWaitForTestExternal','TestCompleteSuccess',  'Pending',       'Complete',      $false, 'Test', 'Configure' ),
            @($null,            ,'Ended')
        )
    )
    {
        $nodeKey,$stateName,$eventName,$progressBefore,$progressAfter,$result,$verb,$phase = $value
        Context "Step $i" {
            $moveNextResult = [bool]($stateName -ne 'Ended')
            It ".MoveNext() returns $moveNextResult" {
                $h.e.MoveNext() | Should be $moveNextResult
            }
            It "enumerator at node $nodeKey" {
                $h.e.NodeEnumerator.Key | Should be $nodeKey
            }
            It "state machine in state $stateName" {
                $h.e.StateMachine.CurrentState.StateName | Should be $stateName
            }
            if ( $stateName -ne 'Ended' )
            {
                It 'returns a step object' {
                    $h.Step = Get-CurrentConfigStep -InputObject $h.e
                    $h.Step.Verb | Should be $verb
                    $h.Step.Phase | Should be $phase
                }
                It 'state machine initially has empty trigger queue' {
                    $h.e.StateMachine.TriggerQueue.Count | Should be 0
                }
                It "progress was initially $progressBefore" {
                    $h.e.NodeEnumerator.Value.Progress | Should be $progressBefore
                }
                It 'invoked was initially false' {
                    $h.e.CurrentStep.Invoked | Should be $false
                }
                It 'Invoke' {
                    $h.StepResult = $h.Step | Invoke-ConfigStep
                }
                It 'returns exactly one result object' {
                    $h.StepResult.Count | Should be 1
                    $h.StepResult.GetType() | Should be ConfigStepResult
                }
                It "event $eventName was raised" {
                    $h.e.StateMachine.TriggerQueue.Count | Should be 1
                    $h.e.StateMachine.TriggerQueue.Peek() | Should be $eventName
                }
                It "reports progress $progressAfter" {
                    $h.e.NodeEnumerator.Value.Progress | Should be $progressAfter
                }
                It ".Progress is $progressAfter" {
                    $h.StepResult.Progress | Should be $progressAfter
                }
                It 'invoked was set to true' {
                    $h.e.CurrentStep.Invoked | Should be $true
                }
                It 'populates .Message' {
                    $h.StepResult.Message | Should match $verb
                    $h.StepResult.Message | Should match ($nodeKey | ConvertTo-RegexEscapedString)
                    $h.StepResult.Message | Should match 'Complete'
                    $h.StepResult.Message | Should match $phase
                }
                It "result is $result" {
                    $h.StepResult.Result | Should be $result
                }
                It 'populates .Step' {
                    $h.StepResult.Step -eq $h.Step | Should be $true
                }
                It 'populates .Verb' {
                    $h.StepResult.Verb | Should be $verb
                }
                It 'populates .Phase' {
                    $h.StepResult.Phase | Should be $phase
                }
                It 'populates .ResourceName' {
                    $h.StepResult.ResourceName | Should be $nodeKey
                }
            }
        }
        $i ++
    }
}

$tests = [ordered]@{
    'Skip All Steps' = @{
        ConfigDocument = {
            Get-DscResource StubResource5 | Import-DscResource
            StubResource5 'a' @{ Mode = 'Normal' }
            StubResource5 'b' @{ Mode = 'Normal' }
        }
        Values = @(
            # NodeKey           | StateName                    | Invoke? | Node Progress
            @('[StubResource5]a','PretestWaitForTestExternal',  $false,   'Skipped'),
            @('[StubResource5]b','PretestWaitForTestExternal',  $false,   'Skipped'),
            @($null,            ,'Ended' )
        )
    }
    'Skip a Configure Set Step before Progress' = @{
        ConfigDocument = {
            Get-DscResource StubResource5 | Import-DscResource
            StubResource5 'a' @{ Mode = 'Normal' }
            StubResource5 'b' @{ Mode = 'Normal' }
        }
        Values = @(
            @('[StubResource5]a','PretestWaitForTestExternal',    $true,    'Pending'),
            @('[StubResource5]b','PretestWaitForTestExternal',    $true,    'Pending'),
            @('[StubResource5]a','ConfigureWaitForSetExternal',   $false,   'Skipped'),
            @('[StubResource5]b','ConfigureWaitForSetExternal',   $true,    'Pending'),
            @('[StubResource5]b','ConfigureWaitForTestExternal',  $true,    'Complete'),
            @($null,            ,'Ended' )
        )
    }
    'Skip a Configure Set Step after Progress' = @{
        ConfigDocument = {
            Get-DscResource StubResource5 | Import-DscResource
            StubResource5 'a' @{ Mode = 'Normal' ; DependsOn = '[StubResource5]b' }
            StubResource5 'b' @{ Mode = 'Normal' }
            StubResource5 'c' @{ Mode = 'Normal' }
        }
        Values = @(
            @('[StubResource5]a','PretestWaitForTestExternal',            $true,    'Pending'),
            @('[StubResource5]b','PretestWaitForTestExternal',            $true,    'Pending'),
            @('[StubResource5]c','PretestWaitForTestExternal',            $true,    'Pending'),
            @('[StubResource5]b','ConfigureWaitForSetExternal',           $true,    'Pending'),
            @('[StubResource5]b','ConfigureWaitForTestExternal',          $true,    'Complete'),
            @('[StubResource5]c','ConfigureProgressWaitForSetExternal',   $false,   'Skipped'),
            @('[StubResource5]a','ConfigureWaitForSetExternal',           $true,    'Pending'),
            @('[StubResource5]a','ConfigureWaitForTestExternal',          $true,    'Complete'),
            @($null,            ,'Ended' )
        )
    }
    'Skip a Configure Test Step before Progress' = @{
        ConfigDocument = {
            Get-DscResource StubResource5 | Import-DscResource
            StubResource5 'a' @{ Mode = 'Normal' }
            StubResource5 'b' @{ Mode = 'Normal' }
        }
        Values = @(
            @('[StubResource5]a','PretestWaitForTestExternal',    $true,    'Pending'),
            @('[StubResource5]b','PretestWaitForTestExternal',    $true,    'Pending'),
            @('[StubResource5]a','ConfigureWaitForSetExternal',   $true,    'Pending'),
            @('[StubResource5]a','ConfigureWaitForTestExternal',  $false,   'Skipped'),
            @('[StubResource5]b','ConfigureWaitForSetExternal',   $true,    'Pending'),
            @('[StubResource5]b','ConfigureWaitForTestExternal',  $true,    'Complete'),
            @($null,            ,'Ended' )
        )
    }
    'Skip a Configure Test Step after Progress' = @{
        ConfigDocument = {
            Get-DscResource StubResource5 | Import-DscResource
            StubResource5 'a' @{ Mode = 'Normal' ; DependsOn = '[StubResource5]b' }
            StubResource5 'b' @{ Mode = 'Normal' }
            StubResource5 'c' @{ Mode = 'Normal' }
        }
        Values = @(
            @('[StubResource5]a','PretestWaitForTestExternal',            $true,    'Pending'),
            @('[StubResource5]b','PretestWaitForTestExternal',            $true,    'Pending'),
            @('[StubResource5]c','PretestWaitForTestExternal',            $true,    'Pending'),
            @('[StubResource5]b','ConfigureWaitForSetExternal',           $true,    'Pending'),
            @('[StubResource5]b','ConfigureWaitForTestExternal',          $true,    'Complete'),
            @('[StubResource5]c','ConfigureProgressWaitForSetExternal',   $true,    'Pending'),
            @('[StubResource5]c','ConfigureProgressWaitForTestExternal',  $false,   'Skipped'),
            @('[StubResource5]a','ConfigureWaitForSetExternal',           $true,    'Pending'),
            @('[StubResource5]a','ConfigureWaitForTestExternal',          $true,    'Complete'),
            @($null,            ,'Ended' )
        )
    }
}

foreach ( $testName in $tests.Keys )
{
    Describe "ConfigInstructionEnumerator.MoveNext() with step invokations ($testName)" {
        $h = @{}
        It 'create test document' {
            $h.doc = New-RawConfigDocument Name $tests.$testName.ConfigDocument |
                ConvertTo-ConfigDocument
        }
        It 'New-' {
            $h.e = $h.doc | New-ConfigInstructionEnumerator
        }
        $i = 0
        foreach ( $value in $tests.$testName.Values
        )
        {
            $nodeKey,$stateName,$invoke,$progress = $value
            Context "Step $i" {
                $moveNextResult = [bool]($stateName -ne 'Ended')
                It ".MoveNext() returns $moveNextResult" {
                    $h.e.MoveNext() | Should be $moveNextResult
                }
                It "enumerator at node $nodeKey" {
                    $h.e.NodeEnumerator.Key | Should be $nodeKey
                }
                It "state machine in state $stateName" {
                    $h.e.StateMachine.CurrentState.StateName | Should be $stateName
                }
                if ( $invoke )
                {
                    It "invoke step" {
                        $h.e.Current.Invoke()
                    }
                }
                if ( $progress )
                {
                    It "node progress set to $progress" {
                        $h.e.NodeEnumerator.Current.Value.Progress = $progress
                    }
                }
            }
            $i++
        }
    }
}

Describe 'ConfigInstructionsEnumerator.Reset()' {
    $h = @{}
    It 'create test document' {
        $h.doc = New-RawConfigDocument Name {
            Get-DscResource StubResource5 | Import-DscResource
            StubResource5 'a' @{ Mode = 'Normal' }
            StubResource5 'b' @{ Mode = 'Normal' }
        } |
            ConvertTo-ConfigDocument
    }
    It 'New-' {
        $h.e = $h.doc | New-ConfigInstructionEnumerator
    }
    $results = [System.Collections.Queue]::new()
    Context 'Invoke all steps and collect data before Reset' {
        foreach ( $step in $h.e )
        {
            It $step.Message {
                $r = $step.Invoke()
                $results.Enqueue($r)
            }
        }
    }
    It '.Reset()' {
        $h.e.Reset()
    }
    Context 'Invoke all steps again and compare to data from before Reset' {
        foreach ( $step in $h.e )
        {
            It $step.Message {
                $h.AfterResetResult = $step.Invoke()
                $h.BeforeResetResult = $results.Dequeue()
            }
            It '  Step message matches' {
                $h.AfterResetResult.Step.Message |
                    Should be $h.BeforeResetResult.Step.Message
            }
            It '  Result message matches' {
                $h.AfterResetResult.Message |
                    Should be $h.BeforeResetResult.Message
            }
        }
    }
}
}
