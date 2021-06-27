# GAS WATER HEATERS AS A STAND-IN
After extensive testing, my knowledge of the OpenStudio SDK is not enough to solve the problem of using Ideal Air Loads in models with HPWHs. Instead I have opted for a gas heater tank to complete my comparison table for my thesis. This way, the latent and sensible gains of DHW use are reflected in my sizing calculations.


# NOTES
I do not recommend using the OpenStudio visual application to do ideal air loads.

# CLUSTER VARIABLES
The variable chosen for clustering is the idealized cooling load (sensible and latent) from the ZoneHVAC:IdealLoadsAirSystem objects, `Zone Ideal Loads Zone Total Cooling Energy`.