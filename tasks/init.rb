#!/opt/puppetlabs/puppet/bin/ruby
# This task picks up a test for a given role
# Store your tests at: <control-repo>/site-modules/roles/files/tests/<test_tool>/<role>.rb
# Roles & Profiles: some use "role", others use "roles"
# Task metadata allows for both naming conventions; "role" and "roles"
# Example usage with bolt (running from the control-repo dir):
#   bolt task run test::roles -n webserver-01.local --modulepath . \
#     --params '{ "test_tool": "inspec" , "test_file": "web_server.rb" }'
#   It does the following things:
#     1. Installs the inspec gems on webserver-01.local in test_tool_install_dir (default: /tmp/puppet_test/gems)
#     2. Copies the files from <control-repo>/site-modules/roles/files/tests/inspec/web_server.rb
#     3. Executes inspec runner with the web_server.rb spec and returns the report as stdout

require 'json'
require 'open3'
require 'puppet'
require 'facter'
require 'stringio'

params                          = JSON.parse(STDIN.read)
gem_bin                         = case Facter.value(:kernel)
                                  when 'Windows'
                                    File.join('c:', 'programdata', 'puppetlabs', 'puppet', 'bin', 'gem')
                                  else
                                    File.join('/', 'opt', 'puppetlabs', 'puppet', 'bin', 'gem')
                                  end
params['task_name']             = params['_task'].to_s.split('::').last if params['task_name'].nil?
params['gem_bin']               = gem_bin if params['gem_bin'].nil?
params['test_tool']             = 'serverspec' if params['test_tool'].nil?
params['test_tool_version']     = '> 0' if params['test_tool_version'].nil?
params['test_tool_install_dir'] = File.join(params['_installdir'], 'puppet_test', params['test_tool']) if params['test_tool_install_dir'].nil?
params['test_file']             = '' if params['test_file'].nil?
params['role']                  = '' if params['role'].nil?
params['test_files_dir']        = File.join('role', 'files', 'spec') if params['test_files_dir'].nil?
params['report_format']         = 'documentation' if params['report_format'].nil?
params['tool_installed']        = false if params['tool_installed'].nil?
params['suppress_exit_code']    = false if params['suppress_exit_code'].nil?

def build_test_file_path(test_files_dir, test_file, role)
  # Returns a file path based on the role or test_file specified,
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
  abs_test_file = File.join(test_files_dir, test_file)
  unless File.file?(abs_test_file)
    raise ["test_file does not exist at: #{abs_test_file}!",
           'Make sure test files exist in your control repo,',
           '(at site-modules/role/files/spec/)'].join(' ')
  end
  abs_test_file
end

def install_gem(gem_bin, gem, version, install_dir)
  require 'shellwords'
  require 'open3'
  require 'fileutils'
  # If HOME is not already set, set it.
  if ENV['HOME'].nil?
    require 'etc'
    ENV['HOME'] = Etc.getpwuid.dir
  end

  cmd = [
    gem_bin, 'install', gem,
    '-i', install_dir,
    '--no-ri', '--no-rdoc'
  ]
  cmd << '-v' << version unless version.empty?
  cmd = cmd.shelljoin
  FileUtils.mkdir_p install_dir unless File.directory?(install_dir)
  stdout, stderr, exitcode = Open3.capture3(cmd)
  raise "Gem install failed: #{stdout} #{stderr}" unless exitcode.success?
end

begin
  $task_exit_code = 1

  # determine absolute path of test file to be executed
  abs_test_file = build_test_file_path(File.join(params['_installdir'], params['test_files_dir']),
                                      params['test_file'],
                                      params['role']) 


  # install gems for test tooling
  unless params['tool_installed']
    install_gem(params['gem_bin'],
                params['test_tool'],
                params['test_tool_version'],
                params['test_tool_install_dir'])
  end

  # load gems into path
  lib_dir = "#{params['test_tool_install_dir']}/**/lib"
  $LOAD_PATH.unshift(*Dir.glob(File.expand_path(lib_dir, __FILE__)))

  # require helper for specific test tool
  require_relative File.join(params['_installdir'], 'test', 'tasks', "#{params['test_tool']}_helper.rb")

  # execute test
  test_exit_code = run_test(params['test_tool'], abs_test_file, params['report_format'])

  # by default we fail the task if the test fails, unless we suppress the exit code returned by the test
  if params['suppress_exit_code']
    puts 'WARN: Unable to suppress exit codes when running minitest - it plays with them at_exit' if params['test_tool'] == 'minitest'
    task_exit_code = 0
  else
    task_exit_code = test_exit_code
  end
rescue => e
  puts({ status: 'failure', error: e, backtrace: e.backtrace }.to_json)
  task_exit_code = 1
ensure
  exit task_exit_code
end
