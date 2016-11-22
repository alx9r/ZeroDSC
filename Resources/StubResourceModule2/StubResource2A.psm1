[DscResource()]
class StubResource2A
{
    [DscProperty(Key)]
    [string]
    $StringParam1

    [DscProperty()]
    [string]
    $StringParam2

    [DscProperty()]
    [bool]
    $BoolParam

    [StubResource2A] Get()
    {
        return $this
    }

    [void] Set() {}

    [bool] Test()
    {
        return $this.BoolParam
    }


}
