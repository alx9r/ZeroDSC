function Test-Prerequisites
{
    [CmdletBinding()]
    param
    (
        [ValidateScript({$_ | Test-ValidConfigPath})]
        [string]
        $InstructionName,

        [hashtable]
        $Instructions
    )
    process {}
}

function Test-ValidPrereqParams
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