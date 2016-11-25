<table>
  <tr>
    <td><img src="https://upload.wikimedia.org/wikipedia/commons/thumb/f/f4/France_road_sign_A14.svg/273px-France_road_sign_A14.svg.png" alt="Warning"/></td>
    <td><b>A mild note of caution:</b> The core features of ZeroDSC are implemented and working.  Please experiment with ZeroDSC and provide feedback by opening issues and pull requests <a href="https://github.com/alx9r/ZeroDSC">here</a>.  Please also note that it is still early days for this project and many of the features are still experimental and unpolished.  Expect breaking changes to ZeroDSC before it stabilizes including changes to the configuration document format, live configuration objects, and the behaviour of the configuration algorithm.
    </td>
  </tr>
</table>

# ZeroDSC

ZeroDSC is a lightweight native PowerShell implementation of a [desired state configuration (DSC)](https://msdn.microsoft.com/en-us/powershell/dsc/overview) configuration engine.

ZeroDSC directly invokes existing PowerShell DSC resources without any dependence on the [local configuration manager (LCM)](https://msdn.microsoft.com/en-us/powershell/dsc/metaconfig).  ZeroDSC uses a declarative configuration document format that looks similar to traditional LCM-invoked configurations.  Configuration documents and resources are interpreted and invoked in a single PowerShell session.  No intermediate files, encryption certificates, or additional processes, modules, or packages are required for ZeroDSC to work.  This makes ZeroDSC suitable for bootstrapping more elaborate configuration management strategies.

The operation of the ZeroDSC configuration engine is deliberately transparent and interactive.  Fine-grained observation and troubleshooting of the ZeroDSC configuration progress is possible with minimal effort.  ZeroDSC supports end-to-end debugger access and streamlined invocation from Pester.   

## New to ZeroDSC?

If you are new to ZeroDSC and would like to learn more, I recommend reviewing the [getting started][] documentation.

[getting started]: Docs\getting-started

## Uses

* development and testing of DSC resources
* automation involving the configuration of resources involving dependencies
* configuring prerequisites for automated testing
* bootstrapping LCM-invoked DSC setup
* configuring resources in user contexts

## Comparison

ZeroDSC is intended as a complement to, not a replacement for, the LCM.  The table below is meant to highlight their differences.

:white_check_mark: = already implemented

:white_large_square: = on the ZeroDSC roadmap

|                                                                  | ZeroDSC            | LCM-invoked DSC    |
| :---                                                             |  :---:             |   :---:            |
| **Resources**                                                    |                    |                    |
| works with class-based resources                                 | :white_check_mark: | :white_check_mark: |
| works with MOF-based resources                                   | :white_check_mark: | :white_check_mark: |
| works with binary resources<sup>[a](#binaryresources)</sup>      |                    | :white_check_mark: |
| **Configuration Documents**                                      |                    |                    |
| works with ZeroDSC configuration documents                       | :white_check_mark: |                    |
| works with traditional PowerShell configuration documents        |                    | :white_check_mark: |
| allows configuration documents with cyclic dependencies          | :white_check_mark: | <sup>[c](#CyclicDependency)</sup>    |
| **Privileges, Credentials, Remoting**                            |                    |                    |
| invoke resources without requiring privileged user               | :white_check_mark: |                    |
| invoke resources as current user without certificates            | :white_check_mark: |                    |
| provide credentials interactively and immediately invoke resources as that user | :white_large_square: |                    |
| install resources over PowerShell remoting                       | :white_large_square: |                   |
| invoke resources over PowerShell remoting                        | :white_large_square: |                   |
| encrypt and save credentials for future use                      |                    | :white_check_mark: |
| retains credentials after reboot                                 |                    | :white_check_mark: |
| **Control and Transparency**                                     |                    |                    |
| continually applies configurations                               |                    | :white_check_mark: |
| automatically continues configuration after reboots              |                    | :white_check_mark: |
| fine-grained control of when and how configurations are applied  | :white_check_mark: |                    |
| step through entire configuration process from single debugger   | :white_check_mark: |                    |
| interact with live configuration objects in console              | :white_check_mark: |                    |
| emits intuitive live configuration objects                       | :white_check_mark: |                    | 
| **Testing and Integration**                                      |                    |                    |
| seamless fine-grained invocation of configurations from Pester   | :white_check_mark: |                    |
| streamlined integration with continuous integration systems<sup>[b](#CI)</sup>  | :white_check_mark: |                    |

(<a name="binaryresources">a</a>) *ZeroDSC could be extended to support binary resources with minimal effort if needed.*

(<a name="CI">b</a>) *When ZeroDSC configurations are invoked using Pester, configuration results can be output in the NUnitXml format or any other format supported by Pester.*

(<a name="CyclicDependency">c</a>) *The [connect issue "Solve the 'Circular DependsOn Exists' Error"](https://connect.microsoft.com/PowerShell/feedback/details/1045031) seems to indicate that cyclic DependsOn references are not allowed when using the LCM.  ZeroDSC uses a multi-pass configuration algorithm that does not have this limitation.*

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

:heavy_check_mark:  clean up public API

:white_large_square: log engine activity to the verbose stream

:white_large_square: bootstrap RemoteFile resource

:white_large_square: bootstrap Archive resource

:white_large_square: adapt built-in resources to execute in user context

:white_large_square: parameters for configuration documents

:white_large_square: invokation of bootstrap resources over PowerShell remoting

:white_large_square: invokation of other DSC resources over PowerShell remoting

:white_large_square: install of ZeroDSC and DSC resources over PowerShell remoting 

### Note

<a name="myfootnote1">1</a>: The warning symbol is the work of Roulex_45 and is used under license by way of  https://en.wikipedia.org/wiki/File:France_road_sign_A14.svg.