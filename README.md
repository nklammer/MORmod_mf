# THESIS
Freezing thesis work in version Feb 18, 2021

# GEMS
In Git Bash for Windows
`$ unset GEM_PATH`

# EMS
Trying to fix EMS error on other branch `dev-report-ideal`.
`** Severe  ** <root>[EnergyManagementSystem:ProgramCallingManager][res wh_Building Unit 001 ProgramManager][programs][0] - Missing required property 'program_name'.`
Matt D commit causes returns fail. https://github.com/NREL/OpenStudio-measures/commit/82086aaa083165d59a704f9696b14a674b8bf27a.

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

# THESIS
Freezing thesis work in version Feb 18, 2021

# GEMS
In Git Bash for Windows
`$ unset GEM_PATH`

# BUILD
Stable. 3/14/21

# DOCUMENTATION
Always run OpenStudio with Git Bash command `openstudio --verbose run -w path/to/workflow.osw --debug -- measures_only[optional]`. Include the `run.log` file and `eplusout.rdd` file in the commits.


