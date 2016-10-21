[DscResource()]
class StubResource3A
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

    [StubResource3A] Get() { return $this }
}

[DscResource()]
class StubResource3B
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

    [StubResource3B] Get() { return $this }
}

class c {}