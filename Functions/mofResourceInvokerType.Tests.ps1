Import-Module ZeroDsc -Force

InModuleScope ZeroDsc {

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
    Context 'mock' {
        $rsrc = Get-DscResource StubResource1A
        $c = $rsrc | Get-MofResourceCommands
        $p = @{
            StringParam1 = 's1'
            BoolParam = $true
        }
        It 'import the module' {
            # this task is normally handled by the ResourceInvoker constructor
            $rsrc.Path | Import-Module
        }
        Mock 'Test-TargetResource' -Verifiable { 'return value' }
        It 'correctly returns value' {
            $r = Invoke-MofResourceCommand test -Params $p -CommandInfo $c
            $r | Should be 'return value'
        }
        It 'correctly invokes Test-TargetResource' {
            Assert-MockCalled 'Test-TargetResource' -Times 1 {
                $StringParam1 -eq 's1' -and
                $BoolParam -eq $true
            }
        }
    }
    Context 'stub' {
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
        It 'returns value' {
            $r = Invoke-MofResourceCommand get -Params $p -CommandInfo $c
            $r.StringParam1 | Should be 's1'
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
}
