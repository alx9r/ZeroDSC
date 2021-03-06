[bool] $WasSet = $false

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("already set","incorrigible","normal")]
        [System.String]
        $Mode
    )
    process
    {
        return @{
            Mode = $Mode
        }
    }
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("already set","incorrigible","normal")]
        [System.String]
        $Mode
    )
    process
    {
        $WasSet = $true
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("already set","incorrigible","normal")]
        [System.String]
        $Mode
    )
    process
    {
        switch ( $Mode )
        {
            'incorrigible' { return $false }
            'already set' { return $true }
            'normal' { return $WasSet }
        }
        return $false
    }
}

Export-ModuleMember -Function *-TargetResource

