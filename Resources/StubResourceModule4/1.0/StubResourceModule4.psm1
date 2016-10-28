[DscResource()]
class StubResource4A
{
    [System.Version]
    $Version = '1.0'
    
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

    [StubResource4A] Get() { return $this }
}
