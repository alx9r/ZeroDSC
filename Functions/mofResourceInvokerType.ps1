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
