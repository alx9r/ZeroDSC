@(
    'resourceInvokerType.ps1'
    'classResourceInvokerType.ps1'
    'mofResourceInvokerType.ps1'
    'resourceConfigInfoType.ps1'
    'configInfoType.ps1'
) |
% { . "$($PSCommandPath | Split-Path -Parent)\$_" }