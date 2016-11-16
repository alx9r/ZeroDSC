# ZeroDSC

ZeroDSC is a lightweight native PowerShell implementation of a DSC configuration engine.

ZeroDSC directly invokes existing PowerShell DSC resources without any dependence on the LCM.  ZeroDSC uses a declarative configuration document format that looks similar to traditional LCM-invoked configurations.  Configuration documents and resources are interpreted and invoked in a single PowerShell session.  No intermediate files, encryption certificates, or additional processes, modules, or packages are required for ZeroDSC to work.  This makes ZeroDSC suitable for bootstrapping more elaborate configuration management strategies.

The operation of the ZeroDSC configuration engine is deliberately transparent and interactive.  Fine-grained observation and troubleshooting of the ZeroDSC configuration progress is possible with minimal effort.  ZeroDSC supports end-to-end debugger access and streamlined invocation from Pester.   

## Uses

* development and testing of DSC resources
* automation involving the configuration of resources involving dependencies
* configuring prerequisites for automated testing
* bootstrapping Windows PowerShell DSC setup
* configuring resources in user contexts

## Comparison

| description                                                      | ZeroDSC            | LCM-invoked DSC    |
| :---                                                             |  :---:             |   :---:            |
| works with class-based resources                                 | :white_check_mark: | :white_check_mark: |
| works with MOF-based resources                                   | :white_check_mark: | :white_check_mark: |
| works with binary resources (1)                                  |                    | :white_check_mark: |
| works with ZeroDSC configuration documents                       | :white_check_mark: |                    |
| works with traditional PowerShell configuration documents        |                    | :white_check_mark: |
| invokes resources without requiring privileged user              | :white_check_mark: |                    |
| invokes resources as current user without certificates           | :white_check_mark: |                    |
| handles reboots                                                  |                    | :white_check_mark: |
| encrypts and saves credentials for future use                    |                    | :white_check_mark: |
| credentials can be provided interactively                        | :white_check_mark: |                    |
| continually applies configurations                               |                    | :white_check_mark: |
| fine-grained control of when and how configurations are applied  | :white_check_mark: |                    |
| entire configuration process accessible in single debugger       | :white_check_mark: |                    |
| user can interact with live configuration objects in console     | :white_check_mark: |                    |
| configuration steps are implemented as `IEnumerable<ConfigStep>` | :white_check_mark: |                    | 
| seamless fine-grained invocation of configurations from Pester   | :white_check_mark: |                    |
| streamlined integration with continuous integration systems (2)  | :white_check_mark: |                    |

(1) ZeroDSC could be extended to support binary resources with minimal effort if needed.

(2) When ZeroDSC configurations are invoked using Pester, configuration results can be output in the NUnitXml format or any other format supported by Pester.

## Prerequisites

* WMF 5.0 or higher   

## Roadmap

:heavy_check_mark: Invoker for class-based resources

:heavy_check_mark: Invoker for MOF-based resources

:heavy_check_mark: importing resources from DSL

:heavy_check_mark: creating configurations from DSL

:heavy_check_mark: binding configurations to resources

:heavy_check_mark: multi-pass configuration algorithm

:heavy_check_mark: configuration instructions implements `IEnumerable<ConfigStep>`

:white_large_square: clean up public API

:white_large_square: log engine activity to the verbose stream

:white_large_square: bootstrap RemoteFile resource

:white_large_square: bootstrap Archive resource

:white_large_square: adapt built-in resources to execute in user context

:white_large_square: parameters for configuration documents

:white_large_square: invokation of bootstrap resources over PowerShell remoting

:white_large_square: invokation of other DSC resources over PowerShell remoting

:white_large_square: install of ZeroDSC and DSC resources over PowerShell remoting 