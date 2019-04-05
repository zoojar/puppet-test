#!/opt/puppetlabs/puppet/bin/ruby
# This task picks up a test for a given role.
# Store your tests at: <control-repo>/site/roles/files/tests/<test_tool>/<role>.rb
# Roles & Profiles: some use "role", others use "roles".
# Task metadata allows for both naming conventions; "role" and "roles".
# Example usage with bolt (running from the control-repo dir):
#   bolt task run test::roles -n webserver-01.local --modulepath . --run-as root --params '{ "test_tool": "inspec" , "test_file": "web_server.rb" }'
#   It does the following things:
#     1. Installs the inspec gems on webserver-01.local in test_tool_dir (default: /tmp/puppet_test/gems)
#     2. Copies the files from <control-repo>/site/roles/files/tests/inspec/web_server.rb
#     3. Executes inspec runner with the web_server.rb spec and returns the report as stdout

require 'json'
require 'open3'
require 'puppet'
require 'facter'

os_tmp = case Facter.value(:kernel)
         when 'Darwin' then '/Users/Shared/tmp'
         when 'Linux' then '/tmp'
         when 'Windows' then 'c:/tmp'
         end

params            = JSON.parse(STDIN.read)
task_name         = params['_task'].split('::').last
workspace         = params['_installdir']
test_tool         = params['test_tool']         ||= 'serverspec'
tool_installed    = params['tool_installed']    ||= false
test_tool_version = params['test_tool_version'] ||= '> 0'
test_tool_dir     = params['test_tool_dir']     ||= File.join(os_tmp, 'puppet_test', test_tool)
test_file         = params['test_file']
role              = params['role']
test_files_dir    = params['test_files_dir']    ||= File.join(task_name,'files', 'tests')
gem_bin           = params['gem_bin']           ||= File.join('/opt', 'puppetlabs', 'puppet', 'bin', 'gem')
report_format     = params['report_format']     ||= 'documentation'

def build_test_file_path(test_files_dir, test_tool, test_file, role)
  # returns a file path based on the test_tool used and role or test_file specified
  # if no role or test_file is specifed then we try to determine the target node's role 
  test_file = "#{role}.rb" unless role.nil?
  if test_file.empty? then
    facter_role = Facter.value(':role')
    unless (facter_role.strip).empty? then
      test_file = "#{facter_role}.rb"
    else 
      raise [
        "\n# Unable to detect this node's role using facter.",
        "# You could try speficying a test_file as a parameter to this task.",
        "# eg. test_file=web_server.rb" 
      ].join("\n")
    end
  end
  File.join(test_files_dir, test_tool, test_file)
end

def run(test_tool, test_file, report_format)
  require test_tool
  case test_tool
  when 'inspec'
    runner = Inspec::Runner.new('reporter' => [report_format])
    runner.add_target(test_file)
    runner.run
  when 'serverspec'
    RSpec::Core::Runner.run([test_file, '-c', '-f', report_format])
  when 'minitest'
    load test_file
  end
end

begin
  unless tool_installed then
    # install gems for test tooling
    require_relative File.join(workspace, 'test', 'tasks', 'install_gem.rb')
    install_gem(gem_bin, test_tool, test_tool_version, test_tool_dir)
  end
  # determine absolute path of test file to be executed
  test_file = build_test_file_path(File.join(workspace, test_files_dir), test_tool, test_file, role)
  # load gems
  $LOAD_PATH.unshift *Dir.glob(File.expand_path("#{test_tool_dir}/**/lib", __FILE__))
  # execute testing
  run(test_tool, test_file, report_format)
rescue Puppet::Error => e
  # handle failure and exit
  puts({ status: 'failure', error: e.message }.to_json)
  exit 1
end
