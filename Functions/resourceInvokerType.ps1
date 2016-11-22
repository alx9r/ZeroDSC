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

    [object] Invoke ( [string] $Mode, [hashtable] $Params )
    {
        return $this | Invoke-ResourceCommand $Mode $Params
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

function Invoke-ResourceCommand
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 1)]
        [ValidateSet('Get','Set','Test')]
        $Mode,

        [Parameter(Position = 2)]
        [hashtable]
        $Params,

        [Parameter(ValueFromPipeline = $true)]
        [ResourceInvoker]
        $InputObject
    )
    process
    {
        $InputObject._Invoke($Mode,$Params)
    }
}