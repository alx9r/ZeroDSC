@(
    'resourceInvokerType.ps1'
    'classResourceInvokerType.ps1'
    'mofResourceInvokerType.ps1'

    'resourceParamsType.ps1'
    'resourceConfigInfoType.ps1'
    'boundResourceType.ps1'
    'configDocumentType.ps1'

    'stateMachineType.ps1'
    'progressNodeType.ps1'
    'configStepType.ps1'
    'configInstructionsType.ps1'
) |
% { . "$($PSCommandPath | Split-Path -Parent)\$_" }