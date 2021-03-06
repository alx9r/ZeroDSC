function Get-TargetResource
{
    [OutputType([System.String])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $StringParam1
    )

    return $PSBoundParameters
}


function Set-TargetResource
{
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $StringParam1,

        [System.String]
        $StringParam2,

        [System.Boolean]
        $BoolParam
    )
}


function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $StringParam1,

        [System.String]
        $StringParam2,

        [System.Boolean]
        $BoolParam
    )
    return $BoolParam
}


Export-ModuleMember -Function *-TargetResource
