class ResourceInvoker 
{ 
    [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]
    $ResourceInfo

    ResourceInvoker(
        [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]
        $ResourceInfo
    )
    {
        $this.ResourceInfo = $ResourceInfo
        Import-Module $this.ResourceInfo.Path
    }
}

class MofResourceInvoker : ResourceInvoker 
{
    [System.Collections.Generic.Dictionary`2[System.String,System.Management.Automation.CommandInfo]]
    $CommandInfo

    MofResourceInvoker(
        [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]
        $ResourceInfo
    ) : base ( $ResourceInfo )
    {
        $this.CommandInfo = $ResourceInfo | Get-MofResourceCommands
    }

    [object] Get( [hashtable] $Params ) 
    { 
        $splat = @{
            Mode = 'Get'
            Params = $Params
            CommandInfo = $this.CommandInfo
        }
        return Invoke-MofResourceCommand @splat
    }

    Set( [hashtable] $Params ) 
    {
        $splat = @{
            Mode = 'Set'
            Params = $Params
            CommandInfo = $this.CommandInfo
        }
        Invoke-MofResourceCommand @splat
    }

    [bool] Test( [hashtable] $Params )
    { 
        $splat = @{
            Mode = 'Test'
            Params = $Params
            CommandInfo = $this.CommandInfo
        }
        return Invoke-MofResourceCommand @splat
    }
}

class ClassResourceInvoker : ResourceInvoker 
{
    $ResourceObject

    ClassResourceInvoker(
        [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]
        $ResourceInfo
    ) : base ( $ResourceInfo )
    {
        $this.ResourceObject = $this.ResourceInfo |
            New-ClassResourceObject
    }

    [object] Get( [hashtable] $Params )
    {
        $splat = @{
            Mode = 'Get'
            Params = $Params
            ResourceObject = $this.ResourceObject
        }
        return Invoke-ClassResourceCommand @splat
    }

    Set( [hashtable] $Params )
    {
        $splat = @{
            Mode = 'Set'
            Params = $Params
            ResourceObject = $this.ResourceObject
        }
        Invoke-ClassResourceCommand @splat
    }

    [bool] Test( [hashtable] $Params )
    {
        $splat = @{
            Mode = 'Test'
            Params = $Params
            ResourceObject = $this.ResourceObject
        }
        return Invoke-ClassResourceCommand @splat
    }
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
            return [MofResourceInvoker]::new( $DscResource )
        }
        if ( $DscResource | Test-ClassResourceType )
        {
            return [ClassResourceInvoker]::new( $DscResource )
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
        try
        {
            $DscResource | Get-MofResourceCommands | Out-Null
            return $true
        }
        catch
        {
            return $false
        }
    }
}

function Get-MofResourceCommands
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
        # see also ToolFoundations\EnvironmentTests\psModuleInfo.Tests.ps1

        $moduleInfo = Get-Module |
            ? { $_.Path -eq $DscResource.Path }

        if ( -not $moduleInfo )
        {
            $moduleInfo = Import-Module $DscResource.Path -PassThru
            $moduleInfo | Remove-Module
        }

        $commands = $moduleInfo.ExportedCommands.Keys
        if ( $commands -contains 'Set-TargetResource' -and
             $commands -contains 'Get-TargetResource' -and
             $commands -contains 'Test-TargetResource' )
        {
            return $moduleInfo.ExportedCommands
        }

        throw "Could not find commands for DSC resource $($DscResource.ResourceType)."
    }    
}

function Invoke-MofResourceCommand
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 1)]
        [ValidateSet('Get','Set','Test')]
        $Mode,

        [hashtable]
        $Params,

        [System.Collections.Generic.Dictionary`2[System.String,System.Management.Automation.CommandInfo]]
        $CommandInfo
    )
    process
    {
        $commandName = "$Mode-TargetResource"
        $moduleName = $CommandInfo.$commandName.ModuleName
        
        $prunedParams = Invoke-PruneParams -Params $Params -CommandInfo $CommandInfo.$commandName

        return & "$moduleName\$commandName" @prunedParams
    }
}

function Invoke-PruneParams 
{
    param
    (
        [hashtable]
        $Params,
        
        [System.Management.Automation.CommandInfo]
        $CommandInfo
    )
    process
    {
        $p = $Params.Clone()

        foreach ( $key in $Params.Keys )
        {
            if ( $key -notin $CommandInfo.Parameters.Keys )
            {
                $p.Remove($key)
            }
        }
        return $p
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
        try
        {
            $DscResource | 
                New-ClassResourceObject |
                Out-Null
            return $true
        }
        catch
        {
            return $false
        }
    }
}

function New-ClassResourceObject
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

            return $object
        }

        throw "Could not create class resource object for DSC Resource $($DscResource.ResourceType)"
    }
}

function Invoke-ClassResourceCommand
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 1)]
        [ValidateSet('Get','Set','Test')]
        $Mode,

        [hashtable]
        $Params,

        $ResourceObject
    )
    process
    {
        $propertyNames = $ResourceObject | Get-Member -MemberType Property | % Name
        foreach ( $key in $Params.Keys )
        {
            if ( $key -notin $propertyNames )
            {
                continue
            }
            $ResourceObject.$key = $Params.$key
        }

        $ResourceObject.$Mode()
    }
}
