# THREE CASES
There are four cases for comparison.

* `zemf_ilas_dhw_novar` is the full model with Ideal Load Air System objects to represent idealized HVAC loads. The variable `d_sh` does not change from unit to unit in the `ResidentialHotWaterFixtures` measure `d_sh += 0`. This means that there is no temporal variance in internal loads between like units.
* `zemf_ilas_nodhw` is the full model with Ideal Load Air System objects to represent idealized HVAC loads. There is no DHW system modeled here.
* `zemf_mini_erv_dhw_novar` is the full model with a minisplit ASHP and DOAS ERV system. The variable `d_sh` does not change from unit to unit in the `ResidentialHotWaterFixtures` measure `d_sh += 0`. This means that there is no temporal variance in internal loads between like units.
* `zemf_mini_erv_dhw_var` is the full model with a minisplit ASHP and DOAS ERV system. The variable `d_sh` shifts by 7 for the next unit `d_sh += 7`, introducing temporal variance in internal loads between like units.

# CLUSTER VARIABLES
The variable chosen for clustering is the idealized cooling load (sensible and latent) from the ZoneHVAC:IdealLoadsAirSystem objects, `Zone Ideal Loads Zone Total Cooling Energy`.