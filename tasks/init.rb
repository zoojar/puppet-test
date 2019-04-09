#!/opt/puppetlabs/puppet/bin/ruby
# This task picks up a test for a given role
# Store your tests at: <control-repo>/site/roles/files/tests/<test_tool>/<role>.rb
# Roles & Profiles: some use "role", others use "roles"
# Task metadata allows for both naming conventions; "role" and "roles"
# Example usage with bolt (running from the control-repo dir):
#   bolt task run test::roles -n webserver-01.local --modulepath . \
#     --params '{ "test_tool": "inspec" , "test_file": "web_server.rb" }'
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

params = JSON.parse(STDIN.read)
params['task_name']         = params['_task'].to_s.split('::').last if params['task_name'].nil?
params['test_tool']         = 'serverspec' if params['test_tool'].nil?
params['test_tool_version'] = '> 0' if params['test_tool_version'].nil?
params['test_tool_dir']     = File.join(os_tmp, 'puppet_test', params['test_tool']) if params['test_tool_dir'].nil?
params['test_file']         = '' if params['test_file'].nil?
params['role']              = '' if params['role'].nil?
params['test_files_dir']    = File.join(params['task_name'], 'files', 'tests') if params['test_files_dir'].nil?
params['gem_bin']           = File.join('/opt', 'puppetlabs', 'puppet', 'bin', 'gem') if params['gem_bin'].nil?
params['report_format']     = 'documentation' if params['report_format'].nil?
params['tool_installed']    = false if params['tool_installed'].nil?
params['return_status']     = false if params['return_status'].nil?

def build_test_file_path(test_files_dir, test_tool, test_file, role)
  # Returns a file path based on the test_tool used and role or test_file specified,
  # if no role or test_file is specifed then we try to determine the target node's role.
  test_file = "#{role}.rb" unless role.to_s.empty?
  if test_file.to_s.empty?
    facter_role = Facter.value(:role).to_s
    if facter_role.strip.empty?
      raise ['Tried, but unable to detect this node\'s role using facter.',
             'Did you mean to provide a test_file parameter to this task?',
             'eg: test_file=web_server.rb'].join(' ')
    else
      test_file = "#{facter_role}.rb"
    end
  end
  abs_test_file = File.join(test_files_dir, test_tool, test_file)
  if File.file?(abs_test_file) then
    return abs_test_file
  else
    raise ["test_file does not exist at: #{abs_test_file}!",
           'Make sure test files exist in your control repo,',
           '(at site/roles/files/tests/)'].join(' ')
  end
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
  unless params['tool_installed']
    # install gems for test tooling
    require_relative File.join(params['_installdir'], 'test', 'tasks', 'install_gem.rb')
    install_gem(params['gem_bin'],
                params['test_tool'],
                params['test_tool_version'],
                params['test_tool_dir'])
  end
  # determine absolute path of test file to be executed
  abs_test_file = build_test_file_path(File.join(params['_installdir'], 
                                                 params['test_files_dir']),
                                                 params['test_tool'],
                                                 params['test_file'],
                                                 params['role'])
  # load gems
  $LOAD_PATH.unshift(*Dir.glob(File.expand_path("#{params['test_tool_dir']}/**/lib", __FILE__)))
  # execute testing
  result = run(params['test_tool'], abs_test_file, params['report_format'])
  if params['return_status']
    exit result
  else
    exit 0
  end
rescue => e
  puts({ status: 'failure', error: e.message }.to_json)
  exit 1
end
