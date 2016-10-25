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
            $record.MofResourceCommands = $record.DscResource |
                Get-MofResourceCommands
            $r = $record.MofResourceCommands
            $r.Count | Should be 3
            $r.'Get-TargetResource' | Should beOfType ([System.Management.Automation.FunctionInfo])
            $r.'Set-TargetResource' | Should beOfType ([System.Management.Automation.FunctionInfo])
            $r.'Test-TargetResource' | Should beOfType ([System.Management.Automation.FunctionInfo])
        }
        foreach ( $mode in 'Get','Set','Test' )
        {
            It "$mode-TargetResource includes parameters" {
                $r = $record.MofResourceCommands."$mode-TargetResource".Parameters
                $r | Should not beNullOrEmpty
            }
        }
    }
}

Describe Invoke-MofResourceCommand {
    $c = $records.StubResource1AFriendlyName.DscResource | Get-MofResourceCommands
    $p = @{
        StringParam1 = 's1'
        BoolParam = $true
    }
    It 'import the module' {
        # this task is normally handled by the ResourceInvoker constructor
        $records.StubResource1AFriendlyName.DscResource.Path |
            Import-Module
    }
    Context 'mock' {
        Mock 'StubResource1A\Test-TargetResource' -Verifiable { 'return value' }
        It 'correctly returns value' {
            $r = Invoke-MofResourceCommand test -Params $p -CommandInfo $c
            $r | Should be 'return value'
        }
        It 'correctly invokes Test-TargetResource' {
            Assert-MockCalled 'StubResource1A\Test-TargetResource' -Times 1 {
                $StringParam1 -eq 's1' -and
                $BoolParam -eq $true
            }
        }
    }
    Context 'stub' {
        It 'returns value' {
            $r = Invoke-MofResourceCommand get -Params $p -CommandInfo $c
            $r | Should be 's1'
        }
    }
}

Describe Invoke-PruneParams {
    $c = $records.StubResource1AFriendlyName.DscResource | 
        Get-MofResourceCommands |
        % { $_.'Get-TargetResource' }
    $p = @{
        StringParam1 = 's1'
        BoolParam = $true
    }
    It 'correctly removes parameter' {
        $r = Invoke-PruneParams -CommandInfo $c -Params $p
        $r.Count | Should be 1
        $r.StringParam1 | Should be 's1'
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
