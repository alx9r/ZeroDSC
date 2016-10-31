# ZeroDSC

ZeroDSC is a lightweight native PowerShell implementation of a DSC configuration engine.

ZeroDSC directly invokes existing PowerShell DSC resources without any dependence on the LCM.  ZeroDSC uses a declarative configuration document format that looks similar to traditional LCM-invoked configurations.  Configuration documents and resources are interpreted and invoked directly by ZeroDSC in a single PowerShell session.  No intermediate files, encryption certificates, or additional processes, modules, or packages are required for ZeroDSC to work.  This makes ZeroDSC suitable for bootstrapping more elaborate configuration management strategies.

## Uses

* testing of DSC resources
* configuring prerequisites for automated testing
* bootstrapping Windows PowerShell DSC setup
* configuring resources in user contexts

## Comparison

| description                                                   | ZeroDSC            | LCM-invoked DSC    |
| :---                                                          |  :---:             |   :---:            |
| works with class-based resources                              | :white_check_mark: | :white_check_mark: |
| works with MOF-based resources                                | :white_check_mark: | :white_check_mark: |
| works with binary resources                                   | (some)             | :white_check_mark: |
| works with ZeroDSC configurations                             | :white_check_mark: |                    |
| works with traditional PowerShell configurations              |                    | :white_check_mark: |
| invokes resources without requiring privileged user           | :white_check_mark: |                    |
| invokes resources as current user without certificates        | :white_check_mark: |                    |
| encrypts and saves credentials for future use                 |                    | :white_check_mark: |
| continually applies configurations                            |                    | :white_check_mark: |
| can debug entire configuration process in PowerShell debugger | :white_check_mark: |                    |