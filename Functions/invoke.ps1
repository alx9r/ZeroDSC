function Invoke-ProcessConfiguration 
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        [ValidateScript({$_ | Test-ValidConfigObject})]
        [array]
        $ConfigObjects
    )
    process
    {
        $instructions = $ConfigObjects | ConvertTo-Instructions

        while ( $invokedSomething )
        {
            $invokedSomething = $false
            foreach ( $instructionName in $instructions.Keys )
            {
                $instruction = $instructions.$instructionName
                if ( $instruction.Result -ne $null )
                {
                    # this instruction has already been processed
                    next
                }
                if ( -not (Test-Prerequisites $instructionName $instructions) )
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
