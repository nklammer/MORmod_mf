# DESCRIPTION
The case is the full model with ASHP domestic hot water systems. The day shift variable `d_sh` does not change from unit to unit, so no variance is introduced. The heating and cooling is handled by air source minisplit heat pumps and DOAS is ERV.

# NOTES

# CLUSTER VARIABLES
The variable chosen for clustering is the idealized cooling load (sensible and latent) from the ZoneHVAC:IdealLoadsAirSystem objects, `Zone Ideal Loads Zone Total Cooling Energy`.