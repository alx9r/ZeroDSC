[bool] $WasSet = $false

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("already set","incorrigible","normal","reset")]
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
        [ValidateSet("already set","incorrigible","normal","reset")]
        [System.String]
        $Mode,

        [ValidateSet("always")]
        [System.String]
        $ThrowOnGet,

        [ValidateSet("always")]
        [System.String]
        $ThrowOnSet,

        [ValidateSet("always","after set")]
        [System.String]
        $ThrowOnTest
    )
    process
    {
        if ( 'always' -eq $ThrowOnSet )
        {
            throw "TestStub forced exception because ThrowOnSet=$ThrowOnSet"
        }
        if ( 'reset' -eq $Mode )
        {
            Set-Variable 'WasSet' $false -Scope 1
            return
        }

        Set-Variable 'WasSet' $true -Scope 1
        return
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("already set","incorrigible","normal","reset")]
        [System.String]
        $Mode,

        [ValidateSet("always")]
        [System.String]
        $ThrowOnGet,

        [ValidateSet("always")]
        [System.String]
        $ThrowOnSet,

        [ValidateSet("always","after set")]
        [System.String]
        $ThrowOnTest
    )
    process
    {
        if ( 'always' -eq $ThrowOnTest )
        {
            throw "TestStub forced exception because ThrowOnTest=$ThrowOnTest"
        }
        if( $WasSet -and 'after set' -eq $ThrowOnTest )
        {
            throw "TestStub forced exception because ThrowOnTest=$ThrowOnTest"           
        }
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

