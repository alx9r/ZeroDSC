[DscResource()]
class StubResource5
{
    [bool] $WasSet = $false

    [DscProperty(Key)]
    [ValidateSet('incorrigible','already set','normal')]
    [string]
    $Mode

    [void] Set() { $this.WasSet = $true }
    [bool] Test()
    {
        switch ( $this.Mode )
        {
            'incorrigible' { return $false }
            'already set' { return $true }
            'normal' { return $this.WasSet }
        }
        return $false
    }

    [StubResource5] Get() { return $this }
}
