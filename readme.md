# ZeroDSC

ZeroDSC is a lightweight native PowerShell implementation of a DSC configuration engine.

ZeroDSC directly invokes existing DSC resources without any dependence on the LCM.  ZeroDSC directly interprets configurations using a DSL similar to traditional LCM-invoked configurations, but ZeroDSC does not use MOFs or other intermediate files for configurations.

## Uses

* testing of DSC resources
* bootstrapping Windows PowerShell DSC configuration
* configuring resources in user contexts

## Comparison

| description                                                   | ZeroDSC            | LCM-invoked DSC    |
| :---                                                          |  :---:             |   :---:            |
| works with class-based resources                              | :white_check_mark: | :white_check_mark: |
| works with MOF-based resources                                | :white_check_mark: | :white_check_mark: |
| works with binary resources                                   | (some)             | :white_check_mark: |
| invokes resources without requiring privileged user           | :white_check_mark: |                    |
| invokes resources as current user without certificates        | :white_check_mark: |                    |
| encrypts and saves credentials for future use                 |                    | :white_check_mark: |
| continually applies configurations                            |                    | :white_check_mark: |
| can debug entire configuration process in PowerShell debugger | :white_check_mark: |                    |