function Test-ValidResourceParams
{
    [CmdletBinding(DefaultParameterSetName = 'Params')]
    param
    (
        [Parameter(ParameterSetName = 'InputObject',
                   ValueFromPipeline=$true)]
        $InputObject,

        [Parameter(ParameterSetName = 'Params')]
        $DependsOn,

        [Parameter(ParameterSetName = 'Params')]
        $TestOnly
    )
    process
    {
        $cp = &(gcp)
        if ( $PSCmdlet.ParameterSetName -eq 'InputObject' )
        {
            $DependsOn = $InputObject.DependsOn
        }
        
        if ( -not ($DependsOn | Test-ValidConfigPath ) )
        {
            return $false
        }

        return $true
    }
}