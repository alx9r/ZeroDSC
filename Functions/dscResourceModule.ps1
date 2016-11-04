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
        New-Alias $DscResource.Name New-RawResourceConfigInfo -Scope 1 -Force

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
