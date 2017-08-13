function Import-DscFunction
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true,
                   Mandatory = $true)]
        [System.Management.Automation.FunctionInfo]
        $FunctionInfo
    )
    process
    {
        $scriptblock = (Get-Item function:/$($FunctionInfo.Name)).Scriptblock
        $unboundScriptblock = [scriptblock]::Create($scriptblock)
        Set-Item function:/$($FunctionInfo.Name) $unboundScriptblock -Force | Out-Null
    }
}

function Remove-DscFunction
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true,
                   Mandatory = $true)]
        [System.Management.Automation.FunctionInfo]
        $FunctionInfo
    )
    process
    {
        Remove-Item function:/$($FunctionInfo.Name) | Out-Null
    }
}
