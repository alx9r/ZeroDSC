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
    Complete
}

enum ConfigStepVerb
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
    [ConfigStep] $Step
}

class ConfigStep
{
    [string] $Message
    [ConfigPhase] $Phase
    [ConfigStepVerb] $Verb
    [Scriptblock] $Action
    [psvariable[]] $ActionArgs
    [StateMachine] $StateMachine

    [ConfigStepResult] Invoke ()
    {
        return $this | Invoke-ConfigStep
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

        [ConfigStep]
        $Step,

        $Raw
    )
    process
    {
        switch ( $Raw )
        {
            $true   { $code = [ConfigStepResultCode]::Success }
            $false  { $code = [ConfigStepResultCode]::Failure }
            $null   { $code = [ConfigStepResultCode]::Complete }
            default { $code = [ConfigStepResultCode]::Undefined }
        }
        New-Object ConfigStepResult -Property @{
            Raw = $Raw
            Code = $code
            Message = $Message
            Step = $Step
        }
    }
}