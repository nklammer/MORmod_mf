# DESCRIPTION
The case is the full model without *any* domestic hot water systems. The absence of *any* dhw system has the benefit that air and plant loops can be removed in the EnableIdealAirLoads measure without invalidating the IDF run.

# NOTES
I do not recommend using the OpenStudio app (packaged with OS-3.0.1) for Ideal Air Loads. Previously, I have used the app to enable Ideal Loads and turn on the Output Variable described below.

# CLUSTER VARIABLES
The variable chosen for clustering is the idealized cooling load (sensible and latent) from the ZoneHVAC:IdealLoadsAirSystem objects, `Zone Ideal Loads Zone Total Cooling Energy`.

### Ideal Air Loads
The simplest piece of zone equipment is the ZoneHVAC:IdealLoadsAirSystem component. ZoneHVAC:IdealLoadsAirSystem is used in situations where the user wishes to study the performance of a building without modeling a full HVAC system. In such a case, the Ideal Loads Air System is usually the sole conditioning component: the user does not need to specify air loops, water loops, etc. All that is needed for the ideal system are zone controls, zone equipment configurations, and the ideal loads system component.

This component can be operated with infinite or finite heating and cooling capacity. For either mode – infinite or limited capacity – the user can also specify on/off schedules for heating and cooling and outdoor air controls. There are also optional controls for dehumidification, humidification, economizer, and heat recovery. This component may be used in combination with other HVAC equipment serving the same zone.

This component can be thought of as an ideal unit that mixes air at the zone exhaust condition with the specified amount of outdoor air and then adds or removes heat and moisture at 100% efficiency in order to produce a supply air stream at the specified conditions. The energy required to condition the supply air is metered and reported as DistrictHeating and DistrictCooling.

Notes: The ideal loads system uses the zone return node or an optional zone exhaust node to extract air from the zone. Every zone served by an HVAC component must have a return air node, even though this node may not be connected to anything.