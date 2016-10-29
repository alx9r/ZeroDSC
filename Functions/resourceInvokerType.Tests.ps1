Import-Module ZeroDSC -Force

$records = @{}
$stubResourceNames = @(
    'StubResource1AFriendlyName'
    'StubResource2A'
)

Describe 'Test Environment' {
    It 'add the test stubs to PSModulePath' {
        . "$($PSCommandPath | Split-Path -Parent)\..\Add-StubsToModulePath.ps1"
    }
    It 'retrieve the DscResources' {
        $records.DscResources = Get-DscResource
    }
    foreach ( $resourceName in $stubResourceNames )
    {
        $records.$resourceName = @{}
        $record = $records.$resourceName
        It "resource $resourceName is available" {
            $record.DscResource = $records.DscResources | ? { $_.Name -eq $resourceName }
            $record.DscResource | Should not beNullOrEmpty
        }
    }
}

Describe New-ResourceInvoker {
    It 'creates a mof invoker for a mof-based resoruce' {
        $r = $records.StubResource1AFriendlyName.DscResource | New-ResourceInvoker
        $r.GetType().Name | Should be 'MofResourceInvoker'
    }
    It 'creates a class invoker for a class-based resource' {
        $r = $records.StubResource2A.DscResource | New-ResourceInvoker
        $r.GetType().Name | Should be 'ClassResourceInvoker'
    }
}


