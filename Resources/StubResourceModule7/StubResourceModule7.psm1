[DscResource()]
class StubResource7
{
    [DscProperty(Key)]
    [string]
    $StringParam

    [void] Set()
    {
        Invoke-Something
    }
    [bool] Test()
    {
        Invoke-Something
        return $false
    }

    [StubResource7] Get()
    {
        Invoke-Something
        return $this
    }
}

function Invoke-Something {}
