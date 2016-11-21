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
    hidden [ConfigPhase] $_Phase = (Accessor $this {
        get { $this.Step.Phase }
    })
    hidden [ConfigStepVerb] $_Verb = (Accessor $this {
        get { $this.Step.Verb }
    })
    hidden [string] $_ResourceName = (Accessor $this {
        get { $this.Step.ResourceName }
    })
    hidden [string] $_Progress = (Accessor $this {
        get { $this.Step.Node.Progress }
    })
    $Result
    [string] $Message
    hidden [ConfigStep] $Step
}

$splat = @{
    TypeName = 'ConfigStepResult'
    DefaultDisplayPropertySet = ‘Phase’,'Verb','ResourceName','Progress' 
}
Update-TypeData @splat -ErrorAction SilentlyContinue

class ConfigStep
{
    [ConfigPhase] $Phase
    [ConfigStepVerb] $Verb
    [string] $ResourceName
    [string] $Message
    [bool] $Invoked

    hidden [Scriptblock] $Action
    hidden [psvariable[]] $ActionArgs
    hidden [StateMachine] $StateMachine
    hidden [ProgressNode] $Node

    [ConfigStepResult] Invoke ()
    {
        return $this | Invoke-ConfigStep
    }
}
$splat = @{
    TypeName = 'ConfigStep' 
    DefaultDisplayPropertySet = ‘Phase’,'Verb','ResourceName','Message' 
}
Update-TypeData @splat -ErrorAction SilentlyContinue
