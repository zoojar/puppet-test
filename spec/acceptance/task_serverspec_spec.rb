# run a test task
require 'spec_helper_acceptance'

describe 'test::role with serverspec' do
  include Beaker::TaskHelper::Inventory
  include BoltSpec::Run
  describe 'test_tool=serverspec' do
    it 'fails to run' do
      task_result = task_run('test::role', '', '', '', 'test_tool' => 'serverspec')
      expect(task_result[0]['status']).to eq('failure')
    end
    it 'returns helpful error message' do
      task_result = task_run('test::role', '', '', '', 'test_tool' => 'serverspec')
      expect(task_result[0]['result']['_output']).to match(%r{unable\sto\sdetect\sthis\snode.*\srole\susing\sfacter})
    end
  end

  describe 'test_tool=serverspec, test_file=example_pass.rb' do
    it 'installs serverspec gem' do
      task_run('test::role', '', '', '', 'test_tool' => 'serverspec', 'test_file' => 'example_pass.rb')
      expect(shell('ls /tmp/puppet_test/serverspec/gems/serverspec*/serverspec.gemspec').exit_code).to eq(0)
    end
    it 'runs a passing test successfully' do
      task_result = task_run('test::role', '', '', '', 'test_tool' => 'serverspec', 'test_file' => 'example_pass.rb')
      expect(task_result[0]['status']).to eq('success')
    end
    it 'returns output' do
      task_result = task_run('test::role', '', '', '', 'test_tool' => 'serverspec', 'test_file' => 'example_pass.rb')
      expect(task_result[0]['result']['_output']).to match(%r{\d+\sexamples,\s0\sfailures})
    end
  end

  describe 'test_tool=serverspec, test_file=example_pass.rb, return_status=false' do
    it 'does not return the status from the test' do
      task_result = task_run('test::role', '', '', '', 'test_tool' => 'serverspec', 'test_file' => 'example_fail.rb', 'return_status' => false)
      expect(task_result[0]['status']).to eq('success')
    end
  end

  describe 'test_tool=serverspec, test_file=example_pass.rb, return_status=true' do
    it 'returns status from test - success' do
      task_result = task_run('test::role', '', '', '', 'test_tool' => 'serverspec', 'test_file' => 'example_pass.rb', 'return_status' => true)
      expect(task_result[0]['status']).to eq('success')
    end
    it 'returns status from test - failure' do
      task_result = task_run('test::role', '', '', '', 'test_tool' => 'serverspec', 'test_file' => 'example_fail.rb', 'return_status' => true)
      expect(task_result[0]['status']).to eq('failure')
    end
  end
end
