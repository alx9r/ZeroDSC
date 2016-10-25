Import-Module ZeroDSC -Force

$expectedBuiltin = @(
    'File'
    'Archive'
    'Environment'
    'Group'
    'GroupSet'
    'Log'
    'Package'
    'ProcessSet'
    'Registry'
    'Script'
    'Service'
    'ServiceSet'
    'User'
    'WaitForAll'
    'WaitForAny'
    'WaitForSome'
    'WindowsFeature'
    'WindowsFeatureSet'
    'WindowsOptionalFeature'
    'WindowsOptionalFeatureSet'
    'WindowsProcess'
)
$expectedNotLoadable = @(
    # Composite Resources
    'GroupSet'
    'ProcessSet'
    'ServiceSet'
    'WindowsFeatureSet'
    'WindowsOptionalFeatureSet'

    # Binary Resources
    'File'
    'Log'
)

$records = @{}
Describe 'Test Environment' {
    It 'retrieve the DscResources in the PSDesiredStateConfiguration module' {
        $records.DscResources = Get-DscResource -Module PSDesiredStateConfiguration
    }
    Context 'sort through those resources' {
        foreach ( $resourceName in ( $records.DscResources | % Name ) )
        {
            $records.$resourceName = @{}
            $record = $records.$resourceName
            It "resource $resourceName is available" {
                $record.DscResource = $records.DscResources | ? { $_.Name -eq $resourceName }
                $record.DscResource | Should not beNullOrEmpty
            }
        }
    }
    Context 'make sure expected resources are available' {
        foreach ( $resourceName in $expectedBuiltin )
        {
            It "expected resource $resourceName found" {
                $records.Keys -contains $resourceName |
                    Should be $true
            }
        }
    }
}

Describe 'loading of builtin resources for invokation' {
    foreach ( $resourceName in ( $records.DscResources | % Name ) )
    {
        $resource = $records.$resourceName.DscResource

        Context "resource $resourceName" {        
            if
            ( 
                $resourceName -notin $expectedBuiltin -or
                $resourceName -notin $expectedNotLoadable 
            )
            {
                It 'successfully creates an invoker object' {
                    $resource | New-ResourceInvoker
                }        
            }
            else
            {
                It 'could not identify resource type when creating invoker object' {
                    { $resource | New-ResourceInvoker } |
                        Should throw 'Could not identify resource type'
                }
            }
        }
    }
}