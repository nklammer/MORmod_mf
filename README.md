# THESIS
This repository contains resources and documentation for Noah Klammer's 2021 MS thesis at the Univeristy of Colorado "Model Order Reduction for More Modular Buildings: Model-Cluster-Reduce for Modular Multifamily Buildings".

This work was inspired by and heavily borrows from previous work done for the publication of the Zero Energy Design Guide for Multifamily buildings. A [related publication](https://www.nrel.gov/docs/fy20osti/77013.pdf) detailing the technical work is available for free.

# VERSIONS
* OpenStudio 3.0.1
* EnergyPlus 9.3.0
* Git Bash for Windows (a git-enabled shell) 3.2.57
* approximately resstock-2.2.0

# GEMS
This project counts on many local changes to published packages (or in Ruby parlance "gems"). For that reason it is suggested to rely on local resources inside this repository instead of external public gems.

Many of the Measures are clones or derivatives of residential energy modeling code from the NREL `resstock` [repository](https://github.com/NREL/resstock). Learn more about ResStock [project](https://resstock.nrel.gov/) and [Residential Energy Modeling](https://www.nrel.gov/buildings/residential.html).

## openstudio-standards gem
This workflow uses OpenStudio v3.0.1 which has `openstudio-standards-0.2.11` embedded. If one desires to access building performance standards ASHRAE `90.1-2016` or `90.1-2019`, a more recent `openstudio-standards-0.2.XX` will be required available from [rubygems.org](https://rubygems.org/gems/openstudio-standards).

Due to a bug in OpenStudio Command Line Interface, the GEM_PATH path variable needs to be taken out of the environment before running.
In Git Bash shell command for Windows `$ unset GEM_PATH` and check for presence with bash line `$ env | grep GEM`.

## resstock gem

# EMS
## Heat Pump Water Heater
This specific workflow has an implementation of a heat pump water heater that requires some EnergyPlus Energy Management System (EMS) code.
Trying to fix EMS error on other branch `dev-report-ideal`.
`** Severe  ** <root>[EnergyManagementSystem:ProgramCallingManager][res wh_Building Unit 001 ProgramManager][programs][0] - Missing required property 'program_name'.`
Matt D [commit](https://github.com/NREL/OpenStudio-measures/commit/82086aaa083165d59a704f9696b14a674b8bf27a) causes returns fail.

I think the equipment name `"res wh_Building Unit 001"` gets set in `ResidentialHotWaterHeaterHeatPump` or `ResidentialHotWaterFixtures`

Program Version,EnergyPlus, Version 9.3.0-baff08990c, YMD=2021.03.14 22:50,
   ** Severe  ** <root>[EnergyManagementSystem:ProgramCallingManager][res wh_Building Unit 001 ProgramManager][programs][0] - Missing required property 'program_name'.
   ** Severe  ** <root>[EnergyManagementSystem:ProgramCallingManager][res wh_Building Unit 001 ProgramManager][programs][1] - Missing required property 'program_name'.
   **  Fatal  ** Errors occurred on processing input file. Preceding condition(s) cause termination.
   ...Summary of Errors that led to program termination:
   ..... Reference severe error count=2
   ..... Last severe error=<root>[EnergyManagementSystem:ProgramCallingManager][res wh_Building Unit 001 ProgramManager][programs][1] - Missing required property 'program_name'.
   ************* Warning:  Node connection errors not checked - most system input has not been read (see previous warning).
   ************* Fatal error -- final processing.  Program exited before simulations began.  See previous error messages.
   ************* EnergyPlus Warmup Error Summary. During Warmup: 0 Warning; 0 Severe Errors.
   ************* EnergyPlus Sizing Error Summary. During Sizing: 0 Warning; 0 Severe Errors.
   ************* EnergyPlus Terminated--Fatal Error Detected. 0 Warning; 2 Severe Errors; Elapsed Time=00hr 00min  1.32sec


# DOCUMENTATION
Always run OpenStudio with Git Bash command `openstudio --verbose run -w path/to/workflow.osw --debug -- measures_only[optional]`. Include the `run.log` file and `eplusout.rdd` file in the commits.


