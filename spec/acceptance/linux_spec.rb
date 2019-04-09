# run a test task
require 'spec_helper_acceptance'

describe 'test::role task', unless: os[:family] == 'windows' do
  include Beaker::TaskHelper::Inventory
  include BoltSpec::Run

  windows = os[:family] == 'windows'

  describe 'test tool serverspec, with test_file supplied' do
    it 'runs a passing test successfully and returns output', unless: windows do
      task_result = task_run('test::role', '', '', '', 'test_tool' => 'serverspec', 'test_file' => 'example_pass.rb')
      expect(task_result[0]['status']).to eq('success')
      expect(task_result[0]['result']['_output']).to match(%r{\d+\sexamples,\s0\sfailures})
    end
    it 'installs serverspec gem', unless: windows do
      expect(shell('ls /tmp/puppet_test/serverspec/gems/serverspec*/serverspec.gemspec').exit_code).to eq(0)
    end
  end

  describe 'test tool serverspec, with no test_file supplied' do
    it 'fails to run and returns helpful output', unless: windows do
      task_result = task_run('test::role', '', '', '', 'test_tool' => 'serverspec')
      expect(task_result[0]['status']).to eq('failure')
      expect(task_result[0]['result']['_output']).to match(%r{\d+\sexamples,\s0\sfailures})
    end
  end
  
end
