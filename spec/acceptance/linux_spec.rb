# run a test task
require 'spec_helper_acceptance'

describe 'test::role task', unless: os[:family] == 'windows' do
  include Beaker::TaskHelper::Inventory
  include BoltSpec::Run

  windows = os[:family] == 'windows'

  describe 'test_tool=serverspec, test_file=example_pass.rb' do
    task_result = task_run('test::role', '', '', '', 'test_tool' => 'serverspec', 'test_file' => 'example_pass.rb')
    it 'installs serverspec gem', unless: windows do
      expect(shell('ls /tmp/puppet_test/serverspec/gems/serverspec*/serverspec.gemspec').exit_code).to eq(0)
    end
    it 'runs a passing test successfully', unless: windows do
      expect(task_result[0]['status']).to eq('success')
    end
    it 'returns output', unless: windows do
      expect(task_result[0]['result']['_output']).to match(%r{\d+\sexamples,\s0\sfailures})
    end
  end

  describe 'test_tool=serverspec' do
    task_result = task_run('test::role', '', '', '', 'test_tool' => 'serverspec')
    it 'fails to run', unless: windows do
      expect(task_result[0]['status']).to eq('failure')
    end
    it 'returns helpful output', unless: windows do
      expect(task_result[0]['result']['_output']).to match(%r{\d+\sexamples,\s0\sfailures})
    end
  end
  
end
