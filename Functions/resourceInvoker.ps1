class ResourceInvoker { 
    [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]$ResourceInfo
}
class MofResourceInvoker : ResourceInvoker {
    [System.Management.Automation.FunctionInfo]$SetCommand
    [System.Management.Automation.FunctionInfo]$GetCommand
    [System.Management.Automation.FunctionInfo]$TestCommand

    [object]Get([hashtable]$Params) { return [psobject]}
    Set([hashtable]$Params) {}
    [bool]Test([hashtable]$Params) { return $false }
}
class ClassResourceInvoker : ResourceInvoker {
    [object]Get([hashtable]$Params) { return [psobject]}
    Set([hashtable]$Params) {}
    [bool]Test([hashtable]$Params) { return $false }
}

function New-ResourceInvoker
{
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]
        $DscResource
    )
    process
    {
        if ( $DscResource | Test-MofResourceType )
        {
            return [MofResourceInvoker]::new()
        }
        if ( $DscResource | Test-ClassResourceType )
        {
            return [ClassResourceInvoker]::new()
        }

        throw New-Object System.ArgumentException(
            'Could not identify resource type.','ResourceName'
        )
    }
}
function Test-MofResourceType
{
    [CmdletBInding()]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]
        $DscResource
    )
    process
    {
        $resourceModule = Get-Module $DscResource.Path -ListAvailable
        $commands = $resourceModule.ExportedCommands.Keys
        if ( $commands -contains 'Set-TargetResource' -and
             $commands -contains 'Get-TargetResource' -and
             $commands -contains 'Test-TargetResource' )
        {
            return $true
        }
        return $false
    }
}
function Test-ClassResourceType
{
    [CmdletBInding()]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]
        $DscResource
    )
    process
    {
        foreach ( $module in @(
                $DscResource.Module
                $DscResource.Module.NestedModules
            )
        )
        {
            $module | Import-Module
            try
            {
                $object = iex @"
                    using module $($module.Path)
                    [$($DscResource.ResourceType)]::new()
"@
            }
            catch [System.Management.Automation.RuntimeException]
            {
                if ( $_.Exception -notmatch 'Unable to find type' )
                {
                    throw
                }
            }

            # did we find an object?
            if ( -not $object )
            {
                continue
            }

            # check for the three requisite methods
            $getMethod = Get-Member -InputObject $object -MemberType Method -Name Get
            $setMethod = Get-Member -InputObject $object -MemberType Method -Name Set
            $testMethod = Get-Member -InputObject $object -MemberType Method -Name Test
            if ( -not $getMethod -or -not $setMethod -or -not $testMethod )
            {
                continue
            }

            # check for the DscResource() attribute
            if ( -not (
                    $object.GetType().CustomAttributes | 
                        ? { $_.AttributeType -eq ([System.Management.Automation.DscResourceAttribute]) } 
                )
            )
            {
                continue
            }

            return $true
        }
        return $false
    }
}
