function Test-ConfigStep
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipeline = $true,
                   Position = 1)]
        [ConfigStep]
        $Step
    )
    begin
    {
        # initialize the flag
        $allComplete = $true
    }
    process
    {
        # don't invoke any more steps once one has failed
        if ( -not $allComplete )
        {
            return
        }

        # don't invoke any steps that are not tests
        if ( $Step.Verb -ne 'Test' )
        {
            return
        }

        # don't invoke any steps that are not pretests
        if ( $Step.Phase -ne 'Pretest' )
        {
            return
        }

        # invoke this step
        $result = Invoke-ConfigStep $Step

        # update the flag
        if ( $result.Progress -ne 'Complete' )
        {
            $allComplete = $false
        }
    }
    end
    {
        # return the value of the flag
        return $allComplete
    }
}
