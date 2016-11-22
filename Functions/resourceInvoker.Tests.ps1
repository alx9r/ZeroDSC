Import-Module ZeroDsc -Force

Describe 'Test Environment' {
    It 'add the test stubs to PSModulePath' {
        . "$($PSCommandPath | Split-Path -Parent)\..\Add-StubsToModulePath.ps1"
    }
}

Describe 'Resource Invoker Public API' {
    $h = @{}
    foreach ( $resourceValues in @(
            @('Class','StubResource5'),
            @('MOF','StubResource6' )
        )
    )
    {
        $type,$resourceName = $resourceValues
        Context "$type resource" {
            It 'New-ResourceInvoker' {
                $h.Invoker = Get-DscResource $resourceName| New-ResourceInvoker
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