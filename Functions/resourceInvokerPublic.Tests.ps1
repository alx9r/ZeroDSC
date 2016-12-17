Import-Module ZeroDsc -Force
Import-Module PSDesiredStateConfiguration

Describe 'Test Environment' {
    It 'add the test stubs to PSModulePath' {
        . "$($PSCommandPath | Split-Path -Parent)\..\Add-StubsToModulePath.ps1"
    }
}

Describe 'Resource Invoker Public API' {
    $tests = @{
        'Class Resource' = 'StubResource5'
        'MOF Resource' = 'StubResource6'
        'Class Resource invokes other functions' = 'StubResource7'
    }
    foreach ( $testName in $tests.Keys )
    {
        $resourceName = $tests.$testName
        Context $testName {
            $h = @{}
            It 'New-ResourceInvoker' {
                $h.DSCResourceInfo = Get-DscResource $resourceName
                $h.Invoker = $h.DSCResourceInfo | New-ResourceInvoker
            }
            It 'Invoke-ResourceCommand' {
                $r = $h.Invoker | Invoke-ResourceCommand Test @{ Mode = 'normal' }
                $r | Should beOfType ([bool])
                $r | Should be $false
            }
            It '.Invoke()' {
                $r = $h.Invoker.Invoke('Test', @{ Mode = 'normal' } )
                $r | Should beOfType ([bool])
                $r | Should be $false
            }
        }
    }
}
