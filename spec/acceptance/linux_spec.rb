# run a test task
require 'spec_helper_acceptance'

describe 'test::role task', unless: os[:family] == 'windows' do
  include Beaker::TaskHelper::Inventory
  include BoltSpec::Run

  windows = os[:family] == 'windows'

  describe 'serverspec' do
    it 'executes serverspec', unless: windows do
      # apply_manifest_on(default, "file { 'rsyslog': ensure => absent, }")
      result = task_run('test::role', '', '', '', 'test_tool' => 'serverspec', 'test_file' => 'example_pass.rb')
      expect(result[0]).to eq('success')
    end
  end
end
