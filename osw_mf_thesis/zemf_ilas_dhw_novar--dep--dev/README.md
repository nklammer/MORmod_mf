# GAS WATER HEATERS AS A STAND-IN
After extensive testing, my knowledge of the OpenStudio SDK is not enough to solve the problem of using Ideal Air Loads in models with HPWHs. Instead I have opted for a gas heater tank to complete my comparison table for my thesis.

# DEPRECATION
I haven't been able to get the IdealLoadsAirSystem measure to work with the workflow case that has realistic heat pump water heaters. The HP water heaters have both air and plant loops that cannot be removed. Effectively I do not have a way of screening out loops for HVAC while still leaving in HP water heaters.

# NOTES
I have used a shortcut in this case subfolder. I have opened the `in.osm` resulting from the `workflow.osw` in the OpenStudio app (packaged with OS-3.0.1). I have used the app to enable Ideal Loads and turn on the Output Variable described below.

# CLUSTER VARIABLES
The variable chosen for clustering is the idealized cooling load (sensible and latent) from the ZoneHVAC:IdealLoadsAirSystem objects, `Zone Ideal Loads Zone Total Cooling Energy`.