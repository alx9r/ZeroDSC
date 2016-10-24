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
Describe Get-MofResourceCommands {
    foreach ( $resourceName in $stubMofResourceNames )
    {
        $record = $records.$resourceName
        It "returns correct commands for $resourceName" {
            $r = $record.DscResource |
                Get-MofResourceCommands
            $r.Count | Should be 3
            $r.'Get-TargetResource' | Should beOfType ([System.Management.Automation.FunctionInfo])
            $r.'Set-TargetResource' | Should beOfType ([System.Management.Automation.FunctionInfo])
            $r.'Test-TargetResource' | Should beOfType ([System.Management.Automation.FunctionInfo])
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