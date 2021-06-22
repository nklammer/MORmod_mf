# DEPRECATION
This case subfolder is deprecated. The case is the full model without *any* domestic hot water systems.

# NOTES
I have used a shortcut in this case subfolder. I have opened the `in.osm` resulting from the `workflow.osw` in the OpenStudio app (packaged with OS-3.0.1). I have used the app to enable Ideal Loads and turn on the Output Variable described below.

# CLUSTER VARIABLES
The variable chosen for clustering is the idealized cooling load (sensible and latent) from the ZoneHVAC:IdealLoadsAirSystem objects, `Zone Ideal Loads Zone Total Cooling Energy`.