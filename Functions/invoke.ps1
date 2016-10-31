function Invoke-ProcessConfiguration 
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        [ConfigInfo]
        $ConfigInfo,

        [ValidateSet('TestOnly')]
        [string]
        $Mode
    )
    process
    {
    }
}

function Invoke-ResourceConfiguration
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [System.Collections.Generic.Dictionary`2[System.String,Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]]
        $DscResources,

        [ResourceConfigInfo]
        $ResourceConfig,

        [ValidateSet('Get','Set','Test')]
        [string]
        $Mode
    )
    process
    {
        # find the correct resource
        $resource = $DscResources[$ResourceConfig.ResourceName]

        # create the invoker object
        $invoker = $resource | New-ResourceInvoker

        # invoke the configuration
        $invoker.$Mode($ResourceConfig.Params)
    }
}