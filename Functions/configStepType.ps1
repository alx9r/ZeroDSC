enum ConfigPhase
{
    Pretest
    Configure
}

class ConfigStepResult
{
}

class ConfigStep
{
    [string] $Message
    [ConfigPhase] $Phase
    [Scriptblock] $Invoker

    [ConfigStepResult] Invoke ()
    {
        return $this.Invoker.Invoke()
    }
}

