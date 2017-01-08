Import-Module ZeroDsc -Force
Import-Module PSDesiredStateConfiguration

Describe 'Test Environment' {
    It 'add the test stubs to PSModulePath' {
        . "$($PSCommandPath | Split-Path -Parent)\..\Add-StubsToModulePath.ps1"
    }
    It 'reset the test stub' {
        $instructions = ConfigInstructions ConfigName {
            Get-DscResource TestStub ZeroDsc | Import-DscResource

            TestStub a @{ Key = 'a'; Mode = 'reset' }
            TestStub b @{ Key = 'b'; Mode = 'reset' }
        }
        $instructions | Invoke-ConfigStep
    }
}

Describe 'Test-ConfigStep Public API - Pipeline' {
    $h = @{}
    $document = {
        Get-DscResource TestStub ZeroDsc | Import-DscResource

        TestStub a @{ Key = 'a'}
        TestStub b @{ Key = 'b'}
    }
    It 'create instructions' {
        $h.Instructions = ConfigInstructions Name $document
        $h.Instructions.Count | Should be 1
        $h.Instructions.GetType() | Should be 'ConfigInstructions'
    }
    It 'returns false' {
        $r = $h.Instructions | Test-ConfigStep
        $r | Should be $false
    }
    It 'apply configuration' {
        $h.Instructions | Invoke-ConfigStep
    }
    It 'returns true' {
        $r = $h.Instructions | Test-ConfigStep
        $r | Should be $true
    }
}
