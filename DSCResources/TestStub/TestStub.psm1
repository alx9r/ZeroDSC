$WasSet = @{}

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Key
    )
    process
    {
        return @{
            Key = $Key
        }
    }
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Key,

        [ValidateSet("already set","incorrigible","normal","reset")]
        [System.String]
        $Mode = 'normal',

        [ValidateSet("always")]
        [System.String]
        $ThrowOnGet,

        [ValidateSet("always","always and apply")]
        [System.String]
        $ThrowOnSet,

        [ValidateSet("always","after set")]
        [System.String]
        $ThrowOnTest
    )
    process
    {
        if ( 'always' -ne $ThrowOnSet )
        {
            $WasSet.$Key = $true
        }

        if ( 'always','always and apply' -contains $ThrowOnSet )
        {
            throw "TestStub forced exception because ThrowOnSet=$ThrowOnSet"
        }
        if ( 'reset' -eq $Mode )
        {
            $WasSet.Remove($Key)
            return
        }

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
        [System.String]
        $Key,

        [ValidateSet("already set","incorrigible","normal","reset")]
        [System.String]
        $Mode = 'normal',

        [ValidateSet("always")]
        [System.String]
        $ThrowOnGet,

        [ValidateSet("always","always and apply")]
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
        if( $WasSet.$Key -and 'after set' -eq $ThrowOnTest )
        {
            throw "TestStub forced exception because ThrowOnTest=$ThrowOnTest"
        }
        switch ( $Mode )
        {
            'incorrigible' { return $false }
            'already set' { return $true }
            'normal' { return [bool]$WasSet.$Key }
        }
        return $false
    }
}


Export-ModuleMember -Function *-TargetResource

