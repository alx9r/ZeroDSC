Import-Module ZeroDsc -Force -Args ExportAll

$records = @{}
$stubResourceNames = @(
    'StubResource1AFriendlyName','StubResource1BFriendlyName',
    'StubResource2A','StubResource2B','StubResource2C',
    'StubResource3A','StubResource3B'
)
$stubClassResourceNames = @(
    'StubResource2A','StubResource2B','StubResource2C',
    'StubResource3A','StubResource3B'
)
$stubMofResourceNames = @(
    'StubResource1AFriendlyName','StubResource1BFriendlyName'
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

Describe New-ClassResourceObject {
    foreach ( $resourceName in $stubClassResourceNames )
    {
        $record = $records.$resourceName
        It "returns correct resource object for $resourceName" {
            $r = $record.DscResource | New-ClassResourceObject
            $r.Count | Should be 1
            $r.GetType().Name | Should be $resourceName
        }
    }
}

Describe Test-ClassResourceType {
    foreach ( $resourceName in $stubClassResourceNames )
    {
        $record = $records.$resourceName
        It "$resourceName is a Class resource type" {
            $r = $record.DscResource | Test-ClassResourceType
            $r.Count | Should be 1
            $r | Should beOfType bool
            $r | Should be $true
        }
    }
    foreach ( $resourceName in $stubMofResourceNames )
    {
        $record = $records.$resourceName
        It "$resourceName is not a Class resource type" {
            $r = $record.DscResource | Test-ClassResourceType
            $r.Count | Should be 1
            $r | Should beOfType bool
            $r | Should be $false
        }
    }
}

Describe Invoke-ClassResourceCommand {
    $o = $records.StubResource2A.DscResource | New-ClassResourceObject
    $p = @{
        StringParam1 = 's1'
        BoolParam = $true
    }
    It 'import the module' {
        # this task is normally handled by the ResourceInvoker constructor
        $records.StubResource2A.DscResource.Path |
            Import-Module
    }
    Context 'stub' {
        It 'returns value' {
            $r = Invoke-ClassResourceCommand Get -Params $p -ResourceObject $o
            $r | Should beOfType $o.GetType()
            $r | Should be $o
            $r.StringParam1 | Should be 's1'
            $r.BoolParam | Should be $true
        }
    }
}
