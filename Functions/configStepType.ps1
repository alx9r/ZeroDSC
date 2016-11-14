enum ConfigPhase
{
    Undefined
    Pretest
    Configure
}

enum ConfigStepResultCode
{
    Undefined
    Success
    Failure
    Unknown
}

enum ConfigStepType
{
    Get
    Set
    Test
}

class ConfigStepResult
{
    $Raw
    [string] $Message
    [ConfigStepResultCode] $Code
    [ConfigStepType] $Type
}

class ConfigStep
{
    [string] $Message
    [ConfigPhase] $Phase
    [Scriptblock] $Action

    [ConfigStepResult] Invoke ()
    {
        return $this.Action.InvokeReturnAsIs()
    }
}

function New-ConfigStepResult
{
    [CmdletBinding()]
    [OutputType([ConfigStepResult])]
    param
    (
        [string]
        $Message,

        [ConfigStepType]
        $Type,

        $Raw
    )
    process
    {
        switch ( $Raw )
        {
            $true   { $code = [ConfigStepResultCode]::Success }
            $false  { $code = [ConfigStepResultCode]::Failure }
            default { $code = [ConfigStepResultCode]::Unknown }
        }
        New-Object ConfigStepResult -Property @{
            Raw = $Raw
            Code = $code
            Message = $Message
        }
    }
}