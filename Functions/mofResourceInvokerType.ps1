class MofResourceInvoker : ResourceInvoker
{
    hidden [System.Collections.Generic.Dictionary`2[System.String,System.Management.Automation.CommandInfo]]
    $CommandInfo

    MofResourceInvoker(
        [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]
        $ResourceInfo
    ) : base ( $ResourceInfo )
    {
        $this.CommandInfo = $ResourceInfo | Get-MofResourceCommands
    }

    hidden [object] _Invoke ( [string] $Mode, [hashtable] $Params )
    {
        $splat = @{
            Mode = $Mode
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

        if ( $DscResource | Test-DscResourceModuleLoaded )
        {
            $moduleInfo = $DscResource | Get-DscResourceModule
        }
        else
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

        throw "Could not find commands for DSC resource $($DscResource.Name)."
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

        $result = & "$moduleName\$commandName" @prunedParams

        if ( $null -eq $result )
        {
            return $null
        }
        return $result
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
