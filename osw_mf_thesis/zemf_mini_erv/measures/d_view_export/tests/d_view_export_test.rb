require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'

require_relative '../measure.rb'

require 'fileutils'

class DViewExport_Test < MiniTest::Unit::TestCase

  def is_openstudio_2?
    begin
      workflow = OpenStudio::WorkflowJSON.new
    rescue
      return false
    end
    return true
  end

  def model_in_path_default
    return "#{File.dirname(__FILE__)}/test_model.osm"
  end

  def epw_path_default
    # make sure we have a weather data location
    epw = nil
    epw = OpenStudio::Path.new("#{File.dirname(__FILE__)}/USA_TX_Houston-Bush.Intercontinental.AP.722430_TMY3.epw")
    assert(File.exist?(epw.to_s))
    return epw.to_s
  end

  def run_dir(test_name)
    # always generate test output in specially named 'output' directory so result files are not made part of the measure
    "#{File.dirname(__FILE__)}/output/#{test_name}"
  end

  def model_out_path(test_name)
    "#{run_dir(test_name)}/TestOutput.osm"
  end

  def workspace_path(test_name)
    if is_openstudio_2?
      return "#{run_dir(test_name)}/run/in.idf"
    else
      return "#{run_dir(test_name)}/ModelToIdf/in.idf"
    end
  end

  def sql_path(test_name)
    if is_openstudio_2?
      return "#{run_dir(test_name)}/run/eplusout.sql"
    else
      return "#{run_dir(test_name)}/ModelToIdf/EnergyPlusPreProcess-0/EnergyPlus-0/eplusout.sql"
    end
  end

  def report_path(test_name)
    "#{run_dir(test_name)}/output.dview"
  end

  # method for running the test simulation using OpenStudio 1.x API
  def setup_test_1(test_name, epw_path)

    co = OpenStudio::Runmanager::ConfigOptions.new(true)
    co.findTools(false, true, false, true)

    if !File.exist?(sql_path(test_name))
      puts "Running EnergyPlus"

      wf = OpenStudio::Runmanager::Workflow.new("modeltoidf->energypluspreprocess->energyplus")
      wf.add(co.getTools())
      job = wf.create(OpenStudio::Path.new(run_dir(test_name)), OpenStudio::Path.new(model_out_path(test_name)), OpenStudio::Path.new(epw_path))

      rm = OpenStudio::Runmanager::RunManager.new
      rm.enqueue(job, true)
      rm.waitForFinished
    end
  end

  # method for running the test simulation using OpenStudio 2.x API
  def setup_test_2(test_name, epw_path)

    if !File.exist?(sql_path(test_name))
      osw_path = File.join(run_dir(test_name), 'in.osw')
      osw_path = File.absolute_path(osw_path)

      workflow = OpenStudio::WorkflowJSON.new
      workflow.setSeedFile(File.absolute_path(model_out_path(test_name)))
      workflow.setWeatherFile(File.absolute_path(epw_path))
      workflow.saveAs(osw_path)

      cli_path = OpenStudio.getOpenStudioCLI
      cmd = "\"#{cli_path}\" run -w \"#{osw_path}\""
      puts cmd
      system(cmd)
    end
  end

  # create test files if they do not exist when the test first runs
  def setup_test(test_name, idf_output_requests, model_in_path = model_in_path_default, epw_path = epw_path_default)

    if !File.exist?(run_dir(test_name))
      FileUtils.mkdir_p(run_dir(test_name))
    end
    assert(File.exist?(run_dir(test_name)))

    if File.exist?(report_path(test_name))
      FileUtils.rm(report_path(test_name))
    end

    assert(File.exist?(model_in_path))

    if File.exist?(model_out_path(test_name))
      FileUtils.rm(model_out_path(test_name))
    end

    # convert output requests to OSM for testing, OS App and PAT will add these to the E+ Idf
    workspace = OpenStudio::Workspace.new("Draft".to_StrictnessLevel, "EnergyPlus".to_IddFileType)
    workspace.addObjects(idf_output_requests)
    rt = OpenStudio::EnergyPlus::ReverseTranslator.new
    request_model = rt.translateWorkspace(workspace)

    translator = OpenStudio::OSVersion::VersionTranslator.new
    model = translator.loadModel(model_in_path)
    assert((not model.empty?))
    model = model.get
    model.addObjects(request_model.objects)
    model.save(model_out_path(test_name), true)

    if is_openstudio_2?
      setup_test_2(test_name, epw_path)
    else
      setup_test_1(test_name, epw_path)
    end
  end

  def test_model_meter

    test_name = "test_model_meter"
    model_in_path = "#{File.dirname(__FILE__)}/test_model.osm"

    # create an instance of the measure
    measure = DViewExport.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new("#{File.dirname(__FILE__)}/#{test_name}.osm"))

    # Get arguments and test that they are what we are expecting
    arguments = measure.arguments()
    argument_map = OpenStudio::Measure::OSArgumentMap.new

    # get the energyplus output requests, this will be done automatically by OS App and PAT
    idf_output_requests = measure.energyPlusOutputRequests(runner, argument_map)
    assert(idf_output_requests.size == 0)

    # mimic the process of running this measure in OS App or PAT
    epw_path = epw_path_default
    setup_test(test_name, idf_output_requests,model_in_path)

    assert(File.exist?(model_out_path(test_name)))
    assert(File.exist?(sql_path(test_name)))
    assert(File.exist?(epw_path))

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_out_path(test_name)))
    runner.setLastEnergyPlusWorkspacePath(OpenStudio::Path.new(workspace_path(test_name)))
    runner.setLastEpwFilePath(epw_path)
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sql_path(test_name)))

    # delete the output if it exists
    if File.exist?(report_path(test_name))
      FileUtils.rm(report_path(test_name))
    end
    assert(!File.exist?(report_path(test_name)))

    # temporarily change directory to the run directory and run the measure
    start_dir = Dir.pwd
    begin
      Dir.chdir(run_dir(test_name))

      # run the measure
      measure.run(runner, argument_map)
      result = runner.result
      show_output(result)
      assert_equal('Success', result.value.valueName)

    ensure
      Dir.chdir(start_dir)
    end

    # make sure the report file exists
    assert(File.exist?(report_path(test_name)))

  end

  def test_model_variable
  
    test_name = "test_model_2"
    model_in_path = "#{File.dirname(__FILE__)}/test_model_2.osm"

    # create an instance of the measure
    measure = DViewExport.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new("#{File.dirname(__FILE__)}/#{test_name}.osm"))

    # Get arguments and test that they are what we are expecting
    arguments = measure.arguments()
    argument_map = OpenStudio::Measure::OSArgumentMap.new
    
    # get the energyplus output requests, this will be done automatically by OS App and PAT
    idf_output_requests = measure.energyPlusOutputRequests(runner, argument_map)
    assert(idf_output_requests.size == 0)

    # mimic the process of running this measure in OS App or PAT
    epw_path = epw_path_default
    setup_test(test_name, idf_output_requests,model_in_path)

    assert(File.exist?(model_out_path(test_name)))
    assert(File.exist?(sql_path(test_name)))
    assert(File.exist?(epw_path))

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_out_path(test_name)))
    runner.setLastEnergyPlusWorkspacePath(OpenStudio::Path.new(workspace_path(test_name)))
    runner.setLastEpwFilePath(epw_path)
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sql_path(test_name)))

    # delete the output if it exists
    if File.exist?(report_path(test_name))
      FileUtils.rm(report_path(test_name))
    end
    assert(!File.exist?(report_path(test_name)))

    # temporarily change directory to the run directory and run the measure
    start_dir = Dir.pwd
    begin
      Dir.chdir(run_dir(test_name))

      # run the measure
      measure.run(runner, argument_map)
      result = runner.result
      show_output(result)
      assert_equal('Success', result.value.valueName)

    ensure
      Dir.chdir(start_dir)
    end

    # make sure the report file exists
    assert(File.exist?(report_path(test_name)))

  end  
  
  def test_model_hvac_timesteps

    test_name = "test_model_hvac_timesteps"
    model_in_path = "#{File.dirname(__FILE__)}/test_model_2.osm"

    # create an instance of the measure
    measure = DViewExport.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new("#{File.dirname(__FILE__)}/#{test_name}.osm"))

    # Get arguments and test that they are what we are expecting
    arguments = measure.arguments()
    argument_map = OpenStudio::Measure::OSArgumentMap.new

    # get the energyplus output requests, this will be done automatically by OS App and PAT
    idf_output_requests = measure.energyPlusOutputRequests(runner, argument_map)
    # manually add output request for this test
    idf_output_requests << OpenStudio::IdfObject.load("Output:Variable,*,Air System Mixed Air Mass Flow Rate,Detailed;").get
    assert(idf_output_requests.size == 1)

    # mimic the process of running this measure in OS App or PAT
    epw_path = epw_path_default
    setup_test(test_name, idf_output_requests,model_in_path)

    assert(File.exist?(model_out_path(test_name)))
    assert(File.exist?(sql_path(test_name)))
    assert(File.exist?(epw_path))

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_out_path(test_name)))
    runner.setLastEnergyPlusWorkspacePath(OpenStudio::Path.new(workspace_path(test_name)))
    runner.setLastEpwFilePath(epw_path)
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sql_path(test_name)))

    # delete the output if it exists
    if File.exist?(report_path(test_name))
      FileUtils.rm(report_path(test_name))
    end
    assert(!File.exist?(report_path(test_name)))

    # temporarily change directory to the run directory and run the measure
    start_dir = Dir.pwd
    begin
      Dir.chdir(run_dir(test_name))

      # run the measure
      measure.run(runner, argument_map)
      result = runner.result
      show_output(result)
      assert_equal('Success', result.value.valueName)

    ensure
      Dir.chdir(start_dir)
    end

    # make sure the report file exists
    assert(File.exist?(report_path(test_name)))

  end  
  
  def test_find_components_on_loops

    test_name = "chlr_flow_mode_and_min_loop_flow"
    model_in_path = "#{File.dirname(__FILE__)}/chlr_flow_mode_and_min_loop_flow.osm"

    # create an instance of the measure
    measure = DViewExport.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new("#{File.dirname(__FILE__)}/#{test_name}.osm"))

    # Get arguments and test that they are what we are expecting
    arguments = measure.arguments()
    argument_map = OpenStudio::Measure::OSArgumentMap.new

    # get the energyplus output requests, this will be done automatically by OS App and PAT
    idf_output_requests = measure.energyPlusOutputRequests(runner, argument_map)
    # manually add output request for this test
    idf_output_requests << OpenStudio::IdfObject.load("Output:Variable,*,Air System Mixed Air Mass Flow Rate,Detailed;").get
    assert(idf_output_requests.size == 1)

    # mimic the process of running this measure in OS App or PAT
    epw_path = epw_path_default
    setup_test(test_name, idf_output_requests,model_in_path)

    assert(File.exist?(model_out_path(test_name)))
    assert(File.exist?(sql_path(test_name)))
    assert(File.exist?(epw_path))

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_out_path(test_name)))
    runner.setLastEnergyPlusWorkspacePath(OpenStudio::Path.new(workspace_path(test_name)))
    runner.setLastEpwFilePath(epw_path)
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sql_path(test_name)))

    # delete the output if it exists
    if File.exist?(report_path(test_name))
      FileUtils.rm(report_path(test_name))
    end
    assert(!File.exist?(report_path(test_name)))

    # temporarily change directory to the run directory and run the measure
    start_dir = Dir.pwd
    begin
      Dir.chdir(run_dir(test_name))

      # run the measure
      measure.run(runner, argument_map)
      result = runner.result
      show_output(result)
      assert_equal('Success', result.value.valueName)

    ensure
      Dir.chdir(start_dir)
    end

    # make sure the report file exists
    assert(File.exist?(report_path(test_name)))
  
  end
  
end
