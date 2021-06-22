# THREE CASES
There are three cases for comparison.

* `zemf_ilas_dhw_novar` is the full model with Ideal Load Air System objects to represent idealized HVAC loads. The variable `d_sh` does not change from unit to unit. This means that there is no temporal variance in internal loads between like units.
* `zemf_mini_erv_novar` is the full model with a minisplit ASHP and DOAS ERV system. The variable `d_sh` does not change from unit to unit. This means that there is no temporal variance in internal loads between like units.
* `zemf_mini_erv_var` is the full model with a minisplit ASHP and DOAS ERV system. The variable `d_sh` shifts by 7 for the next unit, introducing temporal variance in internal loads between like units.

# CLUSTER VARIABLES
The variable chosen for clustering is the idealized cooling load (sensible and latent) from the ZoneHVAC:IdealLoadsAirSystem objects, `Zone Ideal Loads Zone Total Cooling Energy`.