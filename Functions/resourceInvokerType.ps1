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
