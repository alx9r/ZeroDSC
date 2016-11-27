function Import-DscResource
{
<#
.SYNOPSIS
Import a DSC resource for use in a ZeroDSC configuration document.

Important: This is not the help for the built-in Import-DscResource dynamic keyword.

.DESCRIPTION
Import-DscResource imports a DSC resource.  It is meant for use only inside a ZeroDSC configuration document.  Import-DscResource has one parameter DscResource.  DscResource is type [DscResourceInfo] which the is the type emitted by Get-DscResource.  Import-DscResource creates an alias with the same name as the [DscResourceInfo] object.  That alias can then be used to declare resource configurations.

Import-DscResource also emits DscResources to the pipeline.

.OUTPUTS
The object bound to DscResource.
#>
    [OutputType([Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo])]
    [CmdletBinding()]
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
    [CmdletBinding()]
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
