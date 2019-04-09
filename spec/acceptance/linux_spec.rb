# run a test task
require 'spec_helper_acceptance'

describe 'test::role task', unless: os[:family] == 'windows' do
  include Beaker::TaskHelper::Inventory
  include BoltSpec::Run

  windows = os[:family] == 'windows'

  describe 'test tool serverspec' do
    it 'runs a passing test successfully', unless: windows do
      task_result = task_run('test::role', '', '', '', 'test_tool' => 'serverspec', 'test_file' => 'example_pass.rb')
      expect(task_result[0]['status']).to eq('success')
    end
    it 'installs serverspec gem', unless: windows do
      expect(shell('ls /tmp/puppet_test/serverspec/gems/serverspec*/serverspec.gemspec').exit_code).to eq(0)
    end
  end
end
