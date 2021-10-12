# CASES
There are four cases for comparison.

* `zemf_ilas_dhw_novar` is the full model with Ideal Load Air System objects to represent idealized HVAC loads. The variable `d_sh` does not change from unit to unit in the `ResidentialHotWaterFixtures` measure `d_sh += 0`. This means that there is no temporal variance in internal loads between like units.
* `zemf_ilas_nodhw` is the full model with Ideal Load Air System objects to represent idealized HVAC loads. There is no DHW system modeled here.
* `zemf_mini_erv_dhw_novar` is the full model with a minisplit ASHP and DOAS ERV system. The variable `d_sh` does not change from unit to unit in the `ResidentialHotWaterFixtures` measure `d_sh += 0`. This means that there is no temporal variance in internal loads between like units.
* `zemf_mini_erv_dhw_var` is the full model with a minisplit ASHP and DOAS ERV system. The variable `d_sh` shifts by 7 for the next unit `d_sh += 7`, introducing temporal variance in internal loads between like units.

# CLUSTER VARIABLES
The variable chosen for clustering is the idealized cooling load (sensible and latent) from the ZoneHVAC:IdealLoadsAirSystem objects, `Zone Ideal Loads Zone Total Cooling Energy`.

## What's in the `seed_multifamily.osm` file?
The file `seed_multifamily.osm` is a stub file that contains only the basic metadata required for the OpenStudio workflow utility to affect changes to the model object as it articulates and generates model features. This inlcludes:

* OpenStudio Version Number
  * for checking compatibility
* The placeholder OS:Site object that situates the model in a real Earth location.
* The YearDescription that says what day of the week the year starts on
  * the actual calendar year number does not matter
* Placeholder climate zone information
* The OS:Building name
* The system sizing safety factors for heating and cooling equipment sizing
* The shadow calculation method
* The heat balance algorithm method
* The run period (full year, one week, one month, etc.)
* Stubs of space types
  * `commercial` from 90.1-2013 "Retail" from "Retail"
  * `elevator` from 90.1-2013 "ElevatorCore" from "SmallHotel"
  * `stair` from 90.1-2013 "Stair" from "SmallHotel"
  * `coffee` from 90.1-2013 "Dining" from "QuickServiceRestaurant"
  * `mail` from 90.1-2013 "Storage" from "SmallHotel"
  * `community` from 90.1-2013 "Meeting" from "SmallHotel"
  * `retail` from 90.1-2013 "Core_Retail" from "Retail"
  * `garbage` from 90.1-2013 "Storage" from "smallHotel"
  * `gym` from 90.1-2013 "Exercise" from "SmallHotel"
  * `office` from 90.1-2013 "Office" from "MidriseApartment"
  * `lobby` from 90.1-2013 "Entry" from "Retail"
  * `bathroom` from 90.1-2013 "PublicRestroom" from "SmallHotel"
  * `corridor` from 90.1-2013 "Corridor" from "MidriseApartment"
  
## versions of zero_energy_multifamily
* original
* "forked" is the original measure.rb but integrates two addt'l actions. 1) The required `openstudio-standards` module is leveraged to make the method call `standard.model_add_hvac_system(model, 'Ideal Air Loads', nil, nil, nil, zones)` that uses the latest methods to make a valid Ideal Loads Air System in the model. 2) if arg `add_output_var` is set `true` then a new output variable is created for the  `ideal_loads_air_system_variables` array. The array contains the strings `"Zone Ideal Loads Zone Total Cooling Energy"` and `"Zone Ideal Loads Zone Total Heating Energy"`.
* "ILAS" is the "forked" version but with troubleshooting reporting to the `runner`.
* "ILAS better" is...Ideal Loads Air System
