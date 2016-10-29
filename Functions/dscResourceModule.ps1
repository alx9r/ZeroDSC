function Import-DscResource
{
    param
    (
        [Parameter(ValueFromPipeline = $true,
                   Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]
        $DscResource
    )
    process
    {
        New-Alias $DscResource.ResourceType New-ResourceConfigInfo -Scope 1

        return $DscResource
    }
}

function Remove-DscResource
{
    param
    (
        [Parameter(ValueFromPipeline = $true,
                   Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]
        $DscResource
    )
    process
    {
        Remove-Item "alias:\$($DscResource.ResourceType)"
    }
}
