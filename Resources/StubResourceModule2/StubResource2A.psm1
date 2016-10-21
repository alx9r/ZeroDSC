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

    [void] Set() {}
    [bool] Test() { return $true }

    [StubResource2A] Get() { return $this }
}