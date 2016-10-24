Import-Module ZeroDSC -Force

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
    $records.DscResourcesHashtable = @{}
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
    It 'creates a class invoker for a class-based resource' {
        $r = Get-DscResource StubResource2A | New-ResourceInvoker
        $r.GetType().Name | Should be 'ClassResourceInvoker'
    }
    It 'creates a mof invoker for a mof-based resoruce' {
        $r = Get-DscResource StubResource1A | New-ResourceInvoker
        $r.GetType().Name | Should be 'MofResourceInvoker'
    }
}
Describe Test-MofResourceType {
    foreach ( $resourceName in $stubMofResourceNames )
    {
        $record = $records.$resourceName
        It "$resourceName is a MOF resource type" {
            $r = $record.DscResource |
                Test-MofResourceType
            $r | Should be $true
        }
    }
    foreach ( $resourceName in $stubClassResourceNames )
    {
        $record = $records.$resourceName
        It "$resourceName is not a MOF resource type" {
            $r = $record.DscResource |
                Test-MofResourceType
            $r | Should be $false
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