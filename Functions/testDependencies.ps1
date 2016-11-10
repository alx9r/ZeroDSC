function Test-DependenciesMet
{
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        [string]
        $ConfigPath,

        [Parameter(position = 1)]
        [System.Collections.Generic.Dictionary[string,ProgressNode]]
        $Resources
    )
    process
    {
        $parents = $Resources.$ConfigPath.Resource.Config.Params.DependsOn

        foreach ( $parent in $parents )
        {
            if ( $Resources.$parent.Progress -ne [Progress]::Complete )
            {
                return $false
            }
        }

        return $true
    }
}
