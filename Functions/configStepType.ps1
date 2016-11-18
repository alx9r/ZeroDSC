enum ConfigPhase
{
    Undefined
    Pretest
    Configure
}

enum ConfigStepVerb
{
    Get
    Set
    Test
}

class ConfigStepResult
{
    $Result
    [string] $Message
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
    [bool] $Invoked

    [ConfigStepResult] Invoke ()
    {
        return $this | Invoke-ConfigStep
    }
}
