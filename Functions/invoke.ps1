function Invoke-ProcessConfiguration 
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        [array]
        $ConfigObjects
    )
    process
    {
        $ConfigObjects | Assert-ValidConfigObject
        $instructions = $ConfigObjects | ConvertTo-Instructions

        while ( $invokedSomething )
        {
            $invokedSomething = $false
            foreach ( $instruction in $instructions )
            {
                if ( $instruction.Result -ne $null )
                {
                    # this instruction has already been processed
                    next
                }
                if ( -not (Test-InstructionPrerequisites) )
                {
                    # the prerequisites have not been met
                    next
                }

                $splat = @{
                    Mode = @{
                        $true = 'Test'
                        $false = 'Set'
                    }.$($instructions.TestOnly)
                    Set  = { $instructions.Params | >> | & $instructions.SetCommandName }
                    Test = { $instructions.Params | >> | & $instructions.TestCommandName }
                }
                $instruction.Result = Invoke-ProcessIdempotent @splat
                $invokedSomething = $true
            }
        }
    }
}
