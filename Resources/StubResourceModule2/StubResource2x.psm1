[DscResource()]
class StubResource2B
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

    [StubResource2B] Get() { return $this }
}

[DscResource()]
class StubResource2C
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

    [StubResource2C] Get() { return $this }
}
