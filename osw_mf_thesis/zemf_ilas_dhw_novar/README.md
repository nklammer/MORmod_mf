# PROGRAMMING IDEAL LOADS
This case subfolder used the OpenStudio visual application to manually turn conditioned zones into Ideal Loads by checking the boxes in the Thermal Zones tab. Other programmatic ways of changing zones to ideal loads have not worked (see EnableIdealAirLoadsForAllZones and ideal_air_loads_zone_hvac).

When I inspect the in.osm file before and after using the ILAS checkboxes, I see that the field !- "Use Ideal Air Loads" is set to true in the object OS:ThermalZone field. AND all equipment has been removed from the OS object OS:ZoneHVAC:EquipmentList.

# NOTES
I have used a shortcut in this case subfolder. I have opened the `in.osm` resulting from the `workflow.osw` in the OpenStudio app (packaged with OS-3.0.1). I have used the app to enable Ideal Loads and turn on the Output Variable described below.

# CLUSTER VARIABLES
The variable chosen for clustering is the idealized cooling load (sensible and latent) from the ZoneHVAC:IdealLoadsAirSystem objects, `Zone Ideal Loads Zone Total Cooling Energy`.