# run a test task
require 'spec_helper_acceptance'

describe 'linux package task', unless: os[:family] == 'windows' do
  include Beaker::TaskHelper::Inventory
  include BoltSpec::Run

  windows = os[:family] == 'windows'

  describe 'serverspec' do
    it 'executes serverspec', unless: windows do
      # apply_manifest_on(default, "file { 'rsyslog': ensure => absent, }")
      result = task_run('role', '', '', '', 'test_tool' => 'serverspec', 'test_file' => 'web_server.rb')
      expect(result[0]['status']).to eq('success')
    end
  end
end
