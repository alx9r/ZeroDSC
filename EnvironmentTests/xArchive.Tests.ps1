if ( Get-DscResource xArchive -ErrorAction SilentlyContinue )
{
    . "$($PSCommandPath | Split-Path -Parent)\xArchiveTests.ps1"
}