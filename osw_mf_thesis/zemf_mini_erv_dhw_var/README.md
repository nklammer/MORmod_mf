# DESCRIPTION
The case is the full model with ASHP domestic hot water systems. The day shift variable `d_sh` changes from unit-to-unit, so variance is introduced. The heating and cooling is handled by air source minisplit heat pumps and the DOAS is a ERV.

# NOTES

# CLUSTER VARIABLES
The variable chosen for clustering is the idealized cooling load (sensible and latent) from the ZoneHVAC:IdealLoadsAirSystem objects, `Zone Ideal Loads Zone Total Cooling Energy`.