require 'openstudio'
require 'csv'
require_relative "constants"

# start the measure
class MeterCustom < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return 'Zone by zone meters'
  end

  # human readable description
  def description
    return 'This measure creates a Custom Meter to combine output variables and meters for each zone in the ZEDG MF building type. This is helpful to submeter apartments and common areas. To find the meter and variable names, look in the .rdd and .mtd files in the `run` directory. The measure optionally outputs the custom meter.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This measure creates a Meter:Custom object based on ... optionally adds an Output:Meter for the custom meter to save the values to the .eio and .mtr files. Common errors include (1) using space names instead of thermal zone names as key variables, (2) not specifying the Zone variable, e.g. Lights Electric Energy vs. Zone Lights Electric Energy, (3) combining different fuel types on the same meter, and (4) Requesting a variable or meter that is not there, e.g., if a zone has no electric equipment, you cannot request a Zone Electric Equipment Electric Energy variable.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make choice argument for fuel type
    choices = OpenStudio::StringVector.new
    choices << 'Electricity'
    choices << 'NaturalGas'
    choices << 'PropaneGas'
    choices << 'FuelOil#1'
    choices << 'FuelOil21'
    choices << 'Coal'
    choices << 'Diesel'
    choices << 'Water'
    choices << 'Generic'
    choices << 'OtherFuel1'
    choices << 'OtherFuel2'
    fuel_type = OpenStudio::Measure::OSArgument::makeChoiceArgument('fuel_type', choices, true)
    fuel_type.setDisplayName('Fuel Type:')
    fuel_type.setDefaultValue('Electricity')
    args << fuel_type

    add_output_meter = OpenStudio::Measure::OSArgument.makeBoolArgument('add_output_meter',true)
    add_output_meter.setDisplayName('Include associated Output:Meter object?')
    add_output_meter.setDefaultValue(true)
    args << add_output_meter

    reporting_frequency_chs = OpenStudio::StringVector.new
    reporting_frequency_chs << 'detailed'
    reporting_frequency_chs << 'timestep'
    reporting_frequency_chs << 'hourly'
    reporting_frequency_chs << 'daily'
    reporting_frequency_chs << 'monthly'
    reporting_frequency = OpenStudio::Measure::OSArgument::makeChoiceArgument('reporting_frequency', reporting_frequency_chs, true)
    reporting_frequency.setDisplayName('Select reporting frequency for Output:Meter object:')
    reporting_frequency.setDefaultValue('timestep')
    args << reporting_frequency

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking 
    unless runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    fuel_type = runner.getStringArgumentValue('fuel_type', user_arguments)
    add_output_meter = runner.getBoolArgumentValue('add_output_meter', user_arguments)
    reporting_frequency = runner.getStringArgumentValue('reporting_frequency', user_arguments)

    # initialize hash of vars
    zone_vars = {}
    # make string constructors of request variables
    # maybe no units needed

    # may need to get exact name of standards heating and cooling coils...we'll see later
    zone_vars = {}

    zone_vars[:elec] = {}
    zone_vars[:elec][:key] = "ZONE_KEY"
    zone_vars[:elec][:var] = "Electricity:Zone"
    # break ---------------------------------------
    zone_vars[:ashp_clg] = {}
    zone_vars[:ashp_clg][:key] = "ZONE_KEY CENTRAL AIR SOURCE HP COOLING COIL"
    zone_vars[:ashp_clg][:var] = "Cooling Coil Total Electric Energy"

    zone_vars[:ashp_htg] = {}
    zone_vars[:ashp_htg][:key] = "ZONE_KEY CENTRAL AIR SOURCE HP HEATING COIL"
    zone_vars[:ashp_htg][:var] = "Heating Coil Electric Energy"

    zone_vars[:ashp_dfst] = {}
    zone_vars[:ashp_dfst][:key] = "ZONE_KEY CENTRAL AIR SOURCE HP HEATING COIL"
    zone_vars[:ashp_dfst][:var] = "Heating Coil Defrost Electric Energy"

    zone_vars[:ashp_crank] = {}
    zone_vars[:ashp_crank][:key] = "ZONE_KEY CENTRAL AIR SOURCE HP HEATING COIL"
    zone_vars[:ashp_crank][:var] = "Heating Coil Crankcase Heater Electric Energy"

    zone_vars[:ashp_fan] = {}
    zone_vars[:ashp_fan][:key] = "ZONE_KEY CENTRAL AIR SOURCE HP SUPPLY FAN"
    zone_vars[:ashp_fan][:var] = "Fan Electric Energy"

    zone_vars[:ashp_supmtl] = {}
    zone_vars[:ashp_supmtl][:key] = "ZONE_KEY CENTRAL AIR SOURCE HP SUPPLEMENTAL HTG COIL"
    zone_vars[:ashp_supmtl][:var] = "Heating Coil Electric Energy"

    zone_vars[:ashp_unit] = {}
    zone_vars[:ashp_unit][:key] = "ZONE_KEY CENTRAL AIR SOURCE HP UNITARY SYSTEM"
    zone_vars[:ashp_unit][:var] = "Unitary System Heating Ancillary Electric Energy"

    zone_vars[:erv_supply] = {}
    zone_vars[:erv_supply][:key] = "ZONE_KEY ERV SUPPLY FAN"
    zone_vars[:erv_supply][:var] = "Fan Electric Energy"

    zone_vars[:erv_exhuast] = {}
    zone_vars[:erv_exhuast][:key] = "ZONE_KEY ERV EXHAUST FAN"
    zone_vars[:erv_exhuast][:var] = "Fan Electric Energy"

    zone_vars[:erv_hx] = {}
    zone_vars[:erv_hx][:key] = "ZONE_KEY ERV HX"
    zone_vars[:erv_hx][:var] = "Heat Exchanger Electric Energy"
    # break -------------------------------------
    zone_vars[:wh_fan] = {}
    zone_vars[:wh_fan][:key] = "RES WH_BUILDING UNIT XXX FAN"
    zone_vars[:wh_fan][:var] = "Fan Electric Energy"

    zone_vars[:wh_coil_crank] = {}
    zone_vars[:wh_coil_crank][:key] = "RES WH_BUILDING UNIT XXX COIL"
    zone_vars[:wh_coil_crank][:var] = "Cooling Coil Crankcase Heater Electric Energy"

    zone_vars[:wh_coil_heat] = {}
    zone_vars[:wh_coil_heat][:key] = "RES WH_BUILDING UNIT XXX COIL"
    zone_vars[:wh_coil_heat][:var] = "Cooling Coil Water Heating Electric Energy"

    zone_vars[:wh_tank_heater] = {}
    zone_vars[:wh_tank_heater][:key] = "RES WH_BUILDING UNIT XXX TANK"
    zone_vars[:wh_tank_heater][:var] = "Water Heater Electric Energy"

    zone_vars[:wh_tank_off] = {}
    zone_vars[:wh_tank_off][:key] = "RES WH_BUILDING UNIT XXX TANK"
    zone_vars[:wh_tank_off][:var] = "Water Heater Off Cycle Parasitic Electric Energy"

    zone_vars[:wh_tank_on] = {}
    zone_vars[:wh_tank_on][:key] = "RES WH_BUILDING UNIT XXX TANK"
    zone_vars[:wh_tank_on][:var] = "Water Heater On Cycle Parasitic Electric Energy"

    zone_vars[:wh_hpwh_off] = {}
    zone_vars[:wh_hpwh_off][:key] = "RES WH_BUILDING UNIT XXX HPWH"
    zone_vars[:wh_hpwh_off][:var] = "Water Heater Off Cycle Ancillary Electric Energy"
  
    zones = model.getThermalZones.sort
    # reset zone count
    zone_count = 0

    # how to correlate the zone name with the dhw object name?
    # optional objects must be called with #get after checking #empty?
    # all zones
    zones.each do |zone|
      # validate zone w/o dhw
      zone_count += 1
      # instantiate custom meter
      meter_custom_name = "Meter #{zone_count} - #{zone.name} Electricity"
      runner.registerInfo("Creating custom meter called '#{meter_custom_name}'.")
      meter_custom = OpenStudio::Model::MeterCustom.new(model)
      meter_custom.setName(meter_custom_name)
      meter_custom.setFuelType(fuel_type)
      # zone electric meter
      key_name = (zone_vars[:elec][:key]).gsub(/ZONE_KEY/, "#{zone.name}")
      var_name = zone_vars[:elec][:var]
      meter_custom.addKeyVarGroup(key_name, var_name)

      # only condiitoned zones
      next if zone.airLoopHVAC.empty?
      runner.registerInfo("Zone '#{zone.name}' has an associated AirLoopHVAC '#{zone.airLoopHVAC.get.name}'.")
      # array of relevant hash symbols; method Hash.select
      # okay but array is much easier to iterate over than hash
      # just remember to include two dummy variables for block instead of one
      k_ary = [:ashp_clg, :ashp_crank, :ashp_dfst, :ashp_fan, :ashp_htg, :ashp_supmtl, :ashp_unit, :erv_supply, :erv_exhuast, :erv_hx]
      sub_hash = zone_vars.select {|k,v| k_ary.include?(k)}
      sub_hash.each do |k,v|
        key_name = v[:key].gsub(/ZONE_KEY/, "#{zone.name}")
        var_name = v[:var]
        meter_custom.addKeyVarGroup(key_name, var_name)
      end

      # only zones with DHW
      zone.spaces.each do |space|
        # validate looped space with dhw
        next if space.spaceType.empty?
        next if space.waterUseEquipment.empty?
        next if space.buildingUnit.empty?
        # greedy regex matching of the three digit building unit number
        # Regexp module #match method
        unit_num = /\d{3}/.match(space.buildingUnit.get.name.to_s)
        runner.registerInfo("Zone '#{zone.name}' has an associated DHW system and a building unit number of '#{unit_num}'.")
        # method #name undefined for  #<OpenStudio::Model::OptionalBuildingUnit:0x000001bbd33d44c0>.
        # Use #get on boost optional objects then #name
        # 'Building Unit 001'
        #runner.registerInfo("The object HotWaterEquipment in zone #{zone.name} is called '#{space.waterUseEquipment.first.name}'.")
        #runner.registerInfo("The methods I can call on 'space.waterUseEquipment' are #{space.waterUseEquipment.methods}")
        k_ary = [:wh_coil_crank, :wh_coil_heat, :wh_fan, :wh_hpwh_off, :wh_tank_heater, :wh_tank_off, :wh_tank_on]
        sub_hash = zone_vars.select {|k,v| k_ary.include?(k)}
        sub_hash.each do |k,v|
          key_name = v[:key].gsub(/XXX/, "#{unit_num}")
          var_name = v[:var]
          meter_custom.addKeyVarGroup(key_name, var_name)
        end

      end
      # still inside zone loop
      # don't forget to add output meter at end
      if add_output_meter
        output_meter = OpenStudio::Model::OutputMeter.new(model)
        output_meter.setName(meter_custom_name)
        output_meter.setReportingFrequency(reporting_frequency)
        runner.registerInfo("Added a custom meter object #{meter_custom_name} with #{meter_custom.numKeyVarGroups} key-variable groups.")
        runner.registerInfo("#{meter_custom_name} reporting at frequency '#{reporting_frequency}'.")
      end
    end
    # outside zone loop
    runner.registerInfo("The output variables for the model object are #{model.getOutputVariables}")

    # reporting final condition
    runner.registerFinalCondition("Added #{zone_count} custom meter objects.")

    return true
  end
end

# register the measure to be used by the application
MeterCustom.new.registerWithApplication