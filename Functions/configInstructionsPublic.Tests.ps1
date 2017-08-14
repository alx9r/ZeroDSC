Import-Module ZeroDsc #-Force
Import-Module PSDesiredStateConfiguration

Describe 'Test Environment' {
    It 'add the test stubs to PSModulePath' {
        . "$($PSCommandPath | Split-Path -Parent)\..\Add-StubsToModulePath.ps1"
    }
}

Describe 'ConfigInstructions Public API - foreach' {
    $h = @{}
    It 'create test document' {
        $h.Instructions = ConfigInstructions Name {
            Get-DscResource StubResource5 | Import-DscResource
            StubResource5 'a' @{ Mode = 'Normal' ; DependsOn = '[StubResource5]b' }
            StubResource5 'b' @{ Mode = 'Normal' }
        }
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
            It "progress is not failure" {
                $h.r.Progress | Should not be 'Failed'
            }
            $i++
        }
        $i | Should be 6
    }
}

Describe 'ConfigInstructions Public API - Pipeline' {
    $h = @{}
    $document = {
        Get-DscResource TestStub ZeroDsc | Import-DscResource

        TestStub a @{ Key = 'a'}
        TestStub b @{ Key = 'b'; Mode = 'incorrigible' }
        TestStub c @{ Key = 'c'; DependsOn = '[TestStub]b' }
    }
    It 'create instructions' {
        $h.Instructions = ConfigInstructions Name $document
        $h.Instructions.GetType() | Should be 'ConfigInstructions'
    }
    It 'enumerate directly from ConfigInstructions' {
        $r = ConfigInstructions Name $document |
            % { $_ }
        $r.Count | Should be 3
        $r[0].GetType() | Should be 'ConfigStep'
    }
    It 'invoke only Pretest' {
        $r = $h.Instructions |
            ? { $_.Phase -eq 'Pretest' } |
            Invoke-ConfigStep
        $r[0].Phase | Should be 'Pretest'
        $r[0].GetType() | Should be 'ConfigStepResult'
        $r.Count | Should be 3
    }
    It 'invoke all steps, show only failures' {
        $r = $h.Instructions |
            Invoke-ConfigStep |
            ? { $_.Progress -eq 'failed' }
        $r.Count | Should be 1
        $r.Phase | Should be 'Configure'
        $r.Verb | Should be 'Test'
        $r.ResourceName | Should be '[TestStub]b'
    }
}

Describe 'ConfigInstructions Public API - Resource Exceptions and Stack Trace' {
    $h = @{}
    $document = {
        Get-DscResource TestStub | Import-DscResource

        TestStub a @{
            Key = 'a'
            ThrowOnTest = 'always'
        }
    }
    It 'create instructions' {
        $h.Instructions = ConfigInstructions Name $document
    }
    It 'throws exception' {
        $e = $h.Instructions.GetEnumerator()
        $e.MoveNext()
        try
        {
            $e.Current | Invoke-ConfigStep
        }
        catch
        {
            $threw = $true
            $h.Exception = $_
        }
        $threw | Should be $true
    }
    It 'exception originates in resource' {
        $h.Exception.Exception.Message | Should match 'TestStub forced exception'
    }
    It 'stack trace includes originating line' {
        $h.Exception.ScriptStackTrace | Should match 'TestStub.psm1'
        $h.Exception.ScriptStackTrace | Should match 'at Test-TargetResource'
    }
}
