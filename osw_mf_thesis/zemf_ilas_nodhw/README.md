# DESCRIPTION
The case is the full model without *any* domestic hot water systems. The absence of *any* dhw system has the benefit that air and plant loops can be removed in the EnableIdealAirLoads measure without invalidating the IDF run.

# NOTES
I do not recommend using the OpenStudio app (packaged with OS-3.0.1) for Ideal Air Loads. Previously, I have used the app to enable Ideal Loads and turn on the Output Variable described below.

# CLUSTER VARIABLES
The variable chosen for clustering is the idealized cooling load (sensible and latent) from the ZoneHVAC:IdealLoadsAirSystem objects, `Zone Ideal Loads Zone Total Cooling Energy`.