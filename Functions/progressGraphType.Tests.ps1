Import-Module ZeroDsc -Force

Describe 'Test Environment' {
    It 'add the test stubs to PSModulePath' {
        . "$($PSCommandPath | Split-Path -Parent)\..\Add-StubsToModulePath.ps1"
    }
}

Describe ConvertTo-ProgressGraph {
    $h = @{}
    It 'create test document' {
        $h.ConfigDocument = New-ConfigDocument Name {
            Get-DscResource StubResource5 | Import-DscResource
            StubResource5 'a' @{ Mode = 'Normal' }
            StubResource5 'b' @{ Mode = 'Normal' }
        } |
            ConvertTo-ConfigDocument
    }
    It 'convert' {
        $h.ProgressGraph = $h.ConfigDocument | ConvertTo-ProgressGraph
    }
    It 'returns exactly one ProgressGraph object' {
        $h.ProgressGraph.Count | Should be 1
        $h.ProgressGraph.GetType() | Should be 'ProgressGraph'
    }
    It 'populates Resources' {
        $h.ProgressGraph.Resources.'[StubResource5]a'.Resource.Config.ConfigName | Should be 'a'
        $h.ProgressGraph.Resources.'[StubResource5]b'.Resource.Config.ConfigName | Should be 'b'
    }
    It 'populates ResourceEnumerator' {
        $h.ProgressGraph.ResourceEnumerator.MoveNext()
        $h.ProgressGraph.ResourceEnumerator.Current.Key | Should be '[StubResource5]a'
    }
}

Describe 'Get-NextConfigStep (1)' {
    $h = @{}
    It 'create test document' {
        $h.ConfigDocument = New-ConfigDocument Name {
            Get-DscResource StubResource5 | Import-DscResource
            StubResource5 'a' @{ Mode = 'Normal' }
            StubResource5 'b' @{ Mode = 'Normal' }
        } |
            ConvertTo-ConfigDocument
    }
    It 'convert' {
        $h.ProgressGraph = $h.ConfigDocument | ConvertTo-ProgressGraph
    }
    It 'Get-NextConfigStep returns exactly one ConfigStep object' {
        $r = $h.ProgressGraph | Get-NextConfigStep
        $r.Count | Should be 1
        $r.GetType() | Should be 'ConfigStep'
    }
    It 'reset' {
        $h.ProgressGraph = $h.ConfigDocument | ConvertTo-ProgressGraph
    }
    Context 'pretest' {
        It 'get Step 1' {
            $h.Step1 = $h.ProgressGraph | Get-NextConfigStep
            $h.Step1.Message | Should match '\[StubResource5\]a'
            $h.Step1.Message | Should match 'Test'
            $h.Step1.Phase | Should be 'Pretest'
        }
        It 'invoke Step 1' {
            $h.Step1.Invoke()
        }
        It 'get Step 2' {
            $h.Step2 = $h.ProgressGraph | Get-NextConfigStep
            $h.Step2.Message | Should match '\[StubResource5\]b'
            $h.Step2.Message | Should match 'Test'
            $h.Step2.Phase | Should be 'Pretest'
        }
        It 'invoke Step 2' {
            $h.Step1.Invoke()
        }
    }
    Context 'Configure' {
        It 'get Step 3' {
            $h.Step3 = $h.ProgressGraph | Get-NextConfigStep
            $h.Step3.Message | Should match '\[StubResource5\]a'
            $h.Step3.Message | Should match 'Set'
            $h.Step3.Phase | Should match 'Configure'
        }
        It 'invoke Step 3' {
            $h.Step3.Invoke()
        }
        It 'get Step 4' {
            $h.Step4 = $h.ProgressGraph | Get-NextConfigStep
            $h.Step4.Message | Should match '\[StubResource5\]a'
            $h.Step4.Message | Should match 'Test'
            $h.Step4.Phase | Should match 'Configure'
        }
        It 'invoke Step 4' {
            $h.Step4.Invoke()
        }
        It 'get Step 5' {
            $h.Step5 = $h.ProgressGraph | Get-NextConfigStep
            $h.Step5.Message | Should match '\[StubResource5\]b'
            $h.Step5.Message | Should match 'Set'
            $h.Step5.Phase | Should match 'Configure'
        }
        It 'invoke Step 5' {
            $h.Step5.Invoke()
        }
        It 'get Step 6' {
            $h.Step6 = $h.ProgressGraph | Get-NextConfigStep
            $h.Step6.Message | Should match '\[StubResource5\]b'
            $h.Step6.Message | Should match 'Test'
            $h.Step6.Phase | Should match 'Configure'
        }
        It 'invoke Step 6' {
            $h.Step6.Invoke()
        }
    }
}