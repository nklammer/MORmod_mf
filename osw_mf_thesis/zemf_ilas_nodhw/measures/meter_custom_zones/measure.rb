require 'openstudio'

# start the measure
class MeterCustomByZones < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return 'Zone by zone meters'
  end

  # human readable description
  def description
    return 'This measure creates a Custom Meter to combine output variables and meters for each zone in the ZEDG MF building pipeline. This is helpful to submeter apartments and common areas. To find the meter and variable names, look in the .rdd and .mtd files in the `run` directory. The measure optionally outputs the custom meter for viewing in data viewers like DView and DesignBuilder Results Viewer.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Currently this measure only works for "hvac_system_type" : "Minisplit Heat Pumps with ERVs". This measure creates a Meter:Custom object based on all electric end uses attributable to a zone. It optionally adds an Output:Meter for the custom meter to save the values to the .eio and .mtr files. Common errors include (1) using space names instead of thermal zone names as key variables, (2) not specifying the Zone variable, e.g. Lights Electric Energy vs. Zone Lights Electric Energy, (3) combining different fuel types on the same meter, (4) Requesting a variable or meter that is not there, e.g., if a zone has no electric equipment, you cannot request a Zone Electric Equipment Electric Energy variable, (5) EnergyPlus does not allow creating a MeterCustom object for meter contents that already exists i.e. "Electricity:Zone:ELEVATOR_1_4", and (6) calling OS methods on objects like Array or Hash.'
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
    fuel_type.setDefaultValue('Generic')
    args << fuel_type

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
    reporting_frequency = runner.getStringArgumentValue('reporting_frequency', user_arguments)

    meters = model.getOutputMeters
    # reporting initial condition of model
    runner.registerInitialCondition("The model started with #{meters.size} meter objects.")

    # initialize hash of vars
    zone_mtd = {}
    # make string constructors of request variables
    # maybe no units needed

    # may need to get exact name of standards heating and cooling coils...we'll see later
    zone_mtd = {}

    zone_mtd[:elec] = {}
    # no key name needed for 'Overall Meter Types' like 'Electricity:Zone'
    zone_mtd[:elec][:var] = "Electricity:Zone:ZONE_KEY"
    # break ---------------------------------------
    zone_mtd[:ashp_clg] = {}
    zone_mtd[:ashp_clg][:key] = "CLG_COIL_NAME"
    zone_mtd[:ashp_clg][:var] = "Cooling Coil Electric Energy"

    zone_mtd[:ashp_htg] = {}
    zone_mtd[:ashp_htg][:key] = "HTG_COIL_NAME"
    zone_mtd[:ashp_htg][:var] = "Heating Coil Electric Energy"

    zone_mtd[:ashp_dfst] = {}
    zone_mtd[:ashp_dfst][:key] = "HTG_COIL_NAME"
    zone_mtd[:ashp_dfst][:var] = "Heating Coil Defrost Electric Energy"

    zone_mtd[:ashp_crank] = {}
    zone_mtd[:ashp_crank][:key] = "HTG_COIL_NAME"
    zone_mtd[:ashp_crank][:var] = "Heating Coil Crankcase Heater Electric Energy"

    zone_mtd[:ashp_fan] = {}
    zone_mtd[:ashp_fan][:key] = "ZONE_KEY CENTRAL AIR SOURCE HP SUPPLY FAN"
    zone_mtd[:ashp_fan][:var] = "Fan Electric Energy"

    zone_mtd[:ashp_supmtl] = {}
    zone_mtd[:ashp_supmtl][:key] = "ZONE_KEY CENTRAL AIR SOURCE HP SUPPLEMENTAL HTG COIL"
    zone_mtd[:ashp_supmtl][:var] = "Heating Coil Electric Energy"

    zone_mtd[:ashp_unit] = {}
    zone_mtd[:ashp_unit][:key] = "ZONE_KEY CENTRAL AIR SOURCE HP UNITARY SYSTEM"
    zone_mtd[:ashp_unit][:var] = "Unitary System Heating Ancillary Electric Energy"

    zone_mtd[:erv_supply] = {}
    zone_mtd[:erv_supply][:key] = "ZONE_KEY ERV SUPPLY FAN"
    zone_mtd[:erv_supply][:var] = "Fan Electric Energy"

    zone_mtd[:erv_exhaust] = {}
    zone_mtd[:erv_exhaust][:key] = "ZONE_KEY ERV EXHAUST FAN"
    zone_mtd[:erv_exhaust][:var] = "Fan Electric Energy"

    zone_mtd[:erv_hx] = {}
    zone_mtd[:erv_hx][:key] = "ZONE_KEY ERV HX"
    zone_mtd[:erv_hx][:var] = "Heat Exchanger Electric Energy"
    # break -------------------------------------
    zone_mtd[:wh_fan] = {}
    zone_mtd[:wh_fan][:key] = "RES WH_BUILDING UNIT XXX FAN"
    zone_mtd[:wh_fan][:var] = "Fan Electric Energy"

    zone_mtd[:wh_coil_crank] = {}
    zone_mtd[:wh_coil_crank][:key] = "RES WH_BUILDING UNIT XXX COIL"
    zone_mtd[:wh_coil_crank][:var] = "Cooling Coil Crankcase Heater Electric Energy"

    zone_mtd[:wh_coil_heat] = {}
    zone_mtd[:wh_coil_heat][:key] = "RES WH_BUILDING UNIT XXX COIL"
    zone_mtd[:wh_coil_heat][:var] = "Cooling Coil Water Heating Electric Energy"

    zone_mtd[:wh_tank_heater] = {}
    zone_mtd[:wh_tank_heater][:key] = "RES WH_BUILDING UNIT XXX TANK"
    zone_mtd[:wh_tank_heater][:var] = "Water Heater Electric Energy"

    zone_mtd[:wh_tank_off] = {}
    zone_mtd[:wh_tank_off][:key] = "RES WH_BUILDING UNIT XXX TANK"
    zone_mtd[:wh_tank_off][:var] = "Water Heater Off Cycle Parasitic Electric Energy"

    zone_mtd[:wh_tank_on] = {}
    zone_mtd[:wh_tank_on][:key] = "RES WH_BUILDING UNIT XXX TANK"
    zone_mtd[:wh_tank_on][:var] = "Water Heater On Cycle Parasitic Electric Energy"

    zone_mtd[:wh_hpwh_off] = {}
    zone_mtd[:wh_hpwh_off][:key] = "RES WH_BUILDING UNIT XXX HPWH"
    zone_mtd[:wh_hpwh_off][:var] = "Water Heater Off Cycle Ancillary Electric Energy"

    zone_mtd[:wh_gas] = {}
    zone_mtd[:wh_gas][:key] = "res wh|Building Unit XXX"
    zone_mtd[:wh_gas][:var] = "WaterSystems:Gas"
  
    zones = model.getThermalZones.sort
    # reset zone count
    zone_count = 0

    coils_clg = []
    coils_clg += model.getCoilCoolingDXSingleSpeeds
    coils_clg += model.getCoilCoolingDXMultiSpeeds
    coils_clg += model.getCoilCoolingDXTwoSpeeds
    coils_clg += model.getCoilCoolingDXVariableSpeeds
    # -----------
    coils_htg = []
    coils_htg += model.getCoilHeatingDXSingleSpeeds
    coils_htg += model.getCoilHeatingDXMultiSpeeds
    coils_htg += model.getCoilHeatingDXVariableSpeeds

    coil_clg_names = coils_clg.map { |coil| coil.name.get.to_s }
    coil_htg_names = coils_htg.map { |coil| coil.name.get.to_s }
    runner.registerInfo("There are #{coil_clg_names.size} distinct cooling coils in the model of types 'DXSingleSpeed', 'DXMultiSpeed', 'DXTwoSpeed', and 'DXVariableSpeed'.\n")
    runner.registerInfo("There are #{coil_htg_names.size} distinct heating coils in the model of types 'DXSingleSpeed', 'DXMultiSpeed', and 'DXVariableSpeed'.\n")

    # all zones
    zones.each do |zone|
      zone_count += 1
      # instantiate custom meter
      meter_custom_name = "Mtr#{zone_count} - #{zone.name} Electricity"
      runner.registerInfo("Creating custom meter called '#{meter_custom_name}'.")
      meter_custom = OpenStudio::Model::MeterCustom.new(model)
      # set its unique name
      meter_custom.setName(meter_custom_name)
      # set fuel type
      meter_custom.setFuelType(fuel_type)
      # The first member meter will be 'Electricity:Zone:ZONE_KEY' meter.
      # This meter needs a Variable Name only with no Key Name
      var_name = (zone_mtd[:elec][:var]).gsub(/ZONE_KEY/, "#{zone.name}") # Electricity:Zone:ZONE_KEY
      meter_custom.addKeyVarGroup("", var_name) # blank for Key Name
      # also meter_custom.setOutputVariableorMeterName(0, "Electricity:Zone:#{zone.name}")
      runner.registerInfo("#{var_name} was added under #{meter_custom_name}.") # Electricity:Zone:0_BDRM_1_2

      # add the following meters only for conditioned zones
      if not zone.airLoopHVAC.empty? # line is TRUE for conditioned zones
        runner.registerInfo("In addition to space loads, zone '#{zone.name}' is conditioned with an AirLoopHVAC '#{zone.airLoopHVAC.get.name}'.")

        if true # "the zone is conditioned by ashp and ervs"
          # an array of keys that go to Output Variable names relevant to ASHP and ERV
          # these Outputs take a Key Name that is the zone name
          var_keys = [:ashp_fan, :ashp_supmtl, :ashp_unit, :erv_supply, :erv_exhaust, :erv_hx]
           # select a subset of the hash for only relevant keys
          sub_hash = zone_mtd.select { |k,v| var_keys.include?(k) }
          sub_hash.each do |k,v|
            key_name = v[:key].gsub(/ZONE_KEY/, "#{zone.name}") # needs to be matched against the existing object's full name
            var_name = v[:var] # should be okay
            meter_custom.addKeyVarGroup(key_name, var_name)
            runner.registerInfo("#{key_name}:#{var_name} was added under #{meter_custom_name}.")
          end

          coil_keys = [:ashp_clg, :ashp_htg, :ashp_dfst, :ashp_crank]
          sub_hash = zone_mtd.select { |k,v| coil_keys.include?(k) }
          sub_hash.each do |k,v|
            key_name = v[:key]
            new_key_name = coil_clg_names.grep(Regexp.new(zone.name.to_s))[0]
            key_name = key_name.gsub(/CLG_COIL_NAME/, new_key_name) # convert to str from one element array # somehow this is not working
            key_name = key_name.gsub(/HTG_COIL_NAME/, coil_htg_names.grep(Regexp.new(zone.name.to_s))[0]) # alt 2 heating coil # could it be this line is resetting the var 'key_name'
            var_name = v[:var] # good
            meter_custom.addKeyVarGroup(key_name, var_name)
            runner.registerInfo("#{key_name}:#{var_name} was added under #{meter_custom_name}.")
          end

          # add the following meters only for thermal zones initialized with 'Building Unit' 
          zone.spaces.each do |space|
            # validate looped space with dhw
            next if space.spaceType.empty?
            next if space.waterUseEquipment.empty?
            next if space.buildingUnit.empty?
            # Regexp module #match method
            unit_num = /\d{3}/.match(space.buildingUnit.get.name.to_s) # boost opt #get then #name
            runner.registerInfo("Zone '#{zone.name}' has an associated DHW system and a building unit number of '#{unit_num}'.")

            # ONLY HPWH
            if model.getWaterHeaterStratifieds.size > model.getWaterHeaterMixeds.size
              # this array of keys is only relevant to WaterHeater:HeatPump:WrappedCondenser
              k_ary = [:wh_coil_crank, :wh_coil_heat, :wh_hpwh_off, :wh_tank_heater, :wh_tank_off, :wh_tank_on, :wh_fan]
              sub_hash = zone_mtd.select {|k,v| k_ary.include?(k)}
              sub_hash.each do |k,v|
                key_name = v[:key].gsub(/XXX/, "#{unit_num}")
                var_name = v[:var]
                meter_custom.addKeyVarGroup(key_name, var_name)
                runner.registerInfo("#{key_name}:#{var_name} was added under #{meter_custom_name}.")
              end # ends key-var loop
            elsif model.getWaterHeaterMixeds.size > 0 # some other condition
              key_name = (zone_mtd[:wh_gas][:key]).gsub(/XXX/, "#{unit_num}") # "res wh|Building Unit 303"
              var_name = (zone_mtd[:wh_gas][:var]) # "WaterSystems:Gas"
              meter_gas_name = key_name + ":" + var_name # "res wh|Building Unit 303:WaterSystems:Gas"
              output_meter_gas = OpenStudio::Model::OutputMeter.new(model)
              output_meter_gas.setName(meter_gas_name)
              output_meter_gas.setReportingFrequency(reporting_frequency)
              output_meter_gas.setMeterFileOnly(false)
              runner.registerInfo("Added the gas output meter object: #{meter_gas_name}.")
            else
              runner.registerFinalCondition("The water heaters did not meet any of the select criteria.")
              return false
            end
          end # ends spaces loop

        else # "the zone is conditioned by other type"
          return false # TODO change this for other HVAC types
        end

      end # ends 'if' conditioned zone loop

      # still inside zone loop
      output_meter = OpenStudio::Model::OutputMeter.new(model)
      output_meter.setName(meter_custom_name)
      output_meter.setReportingFrequency(reporting_frequency)
      output_meter.setMeterFileOnly(false)
      runner.registerInfo("Added a custom meter object #{meter_custom_name} for a conditioned zone with #{meter_custom.numKeyVarGroups} key-variable groups.")
      runner.registerInfo("#{meter_custom_name} reporting at frequency '#{reporting_frequency}'.\n")

    end # ends zone loop
    
    # outside zone loop
    #---------add 'Pump Electric Energy'-------------
    output_meter = OpenStudio::Model::OutputMeter.new(model)
    meter_name = "Pumps:Electricity"
    output_meter.setName(meter_name)
    output_meter.setReportingFrequency(reporting_frequency)
    output_meter.setMeterFileOnly(false)

    #---------add 'Exterior Lights Electric Energy'-------------
    output_meter = OpenStudio::Model::OutputMeter.new(model)
    meter_name = "ExteriorLights:Electricity"
    output_meter.setName(meter_name)
    output_meter.setReportingFrequency(reporting_frequency)
    output_meter.setMeterFileOnly(false)

    #---------add 'Interior Lights Electric Energy'-------------
    output_meter = OpenStudio::Model::OutputMeter.new(model)
    meter_name = "InteriorLights:Electricity"
    output_meter.setName(meter_name)
    output_meter.setReportingFrequency(reporting_frequency)
    output_meter.setMeterFileOnly(false)
    
    #---------add 'Fans:Electricity'-------------
    output_meter = OpenStudio::Model::OutputMeter.new(model)
    meter_name = "Fans:Electricity"
    output_meter.setName(meter_name)
    output_meter.setReportingFrequency(reporting_frequency)
    output_meter.setMeterFileOnly(false)    
    

    # reporting final condition
    runner.registerFinalCondition("Added #{zone_count} meter objects.")
    meters = model.getOutputMeters
    runner.registerFinalCondition("The model ended with #{meters.size} meter objects.")

    return true
  end # ends run method
end # ends the class def

# register the measure to be used by the application
MeterCustomByZones.new.registerWithApplication
