# run a test task
require 'spec_helper_acceptance'

describe 'test::role with serverspec' do
  config_data = { 'modulepath' => File.join(Dir.pwd, 'spec', 'fixtures', 'modules') }
  inventory_hash = inventory_hash_from_inventory_file
  target_node_name = ENV['TARGET_HOST']
  bolt_params = { config: config_data, inventory: inventory_hash }

  describe 'test_tool=serverspec' do
    it 'without params, fails to run' do
      task_params = { 'test_tool' => 'serverspec' }
      task_result = run_task('test::role', target_node_name, task_params, bolt_params)
      expect(task_result[0]['status']).to eq('failure')
    end
    it 'without params, fails and returns helpful error message' do
      task_params = { 'test_tool' => 'serverspec' }
      task_result = run_task('test::role', target_node_name, task_params, bolt_params)
      expect(task_result[0]['result']['_output']).to match(%r{unable\sto\sdetect\sthis\snode.*\srole\susing\sfacter})
    end
  end

  describe 'test_tool=serverspec, test_file=example_pass.rb' do
    it 'installs serverspec gem' do
      task_params = { 'test_tool' => 'serverspec', 'test_file' => 'example_pass.rb' }
      run_task('test::role', target_node_name, task_params, bolt_params)
      cmd_result = run_command('ls /tmp/puppet_test/serverspec/gems/serverspec*/serverspec.gemspec', target_node_name, {}, bolt_params)
      expect(cmd_result[0]['status']).to eq('success')
    end
    it 'runs a passing test successfully' do
      task_params = { 'test_tool' => 'serverspec', 'test_file' => 'example_pass.rb' }
      task_result = run_task('test::role', target_node_name, task_params, bolt_params)
      expect(task_result[0]['status']).to eq('success')
    end
    it 'returns output' do
      task_params = { 'test_tool' => 'serverspec', 'test_file' => 'example_pass.rb' }
      task_result = run_task('test::role', target_node_name, task_params, bolt_params)
      expect(task_result[0]['result']['_output']).to match(%r{\d+\sexamples,\s0\sfailures})
    end
  end

  describe 'test_tool=serverspec, test_file=example_pass.rb, return_status=false' do
    it 'does not return the status from the test' do
      task_params = { 'test_tool' => 'serverspec', 'test_file' => 'example_fail.rb', 'return_status' => false }
      task_result = run_task('test::role', target_node_name, task_params, bolt_params)
      expect(task_result[0]['status']).to eq('success')
    end
  end

  describe 'test_tool=serverspec, test_file=example_pass.rb, return_status=true' do
    it 'returns status from test - success' do
      task_params = { 'test_tool' => 'serverspec', 'test_file' => 'example_pass.rb', 'return_status' => true }
      task_result = run_task('test::role', target_node_name, task_params, bolt_params)
      expect(task_result[0]['status']).to eq('success')
    end
    it 'returns status from test - failure' do
      task_params = { 'test_tool' => 'serverspec', 'test_file' => 'example_fail.rb', 'return_status' => true }
      task_result = run_task('test::role', target_node_name, task_params, bolt_params)
      expect(task_result[0]['status']).to eq('failure')
    end
  end
end
