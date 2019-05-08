#!/opt/puppetlabs/puppet/bin/ruby

require 'json'
require 'open3'
require 'puppet'
require 'facter'

params                          = JSON.parse(STDIN.read)
opt_dir                         = case Facter.value(:kernel)
                                  when 'Windows'
                                    File.join('c:', 'programdata', 'puppetlabs')
                                  else
                                    File.join('/', 'opt', 'puppetlabs')
                                  end
params['opt_dir']               = opt_dir if params['opt_dir'].nil?
params['_modulename']           = 'acid' if params['_modulename'].nil?
params['task_name']             = params['_task'].to_s.split('::').last if params['task_name'].nil?
params['gem_bin']               = File.join(params['opt_dir'], 'puppet', 'bin', 'gem') if params['gem_bin'].nil?
params['test_tool']             = 'serverspec' if params['test_tool'].nil?
params['test_tool_version']     = '> 0' if params['test_tool_version'].nil?
params['lib_dir']               = File.join(params['opt_dir'], "#{params['_modulename']}_lib", params['test_tool']) if params['lib_dir'].nil?
params['test_file']             = '' if params['test_file'].nil?
params['role']                  = '' if params['role'].nil?
params['test_files_dir']        = File.join('role', 'files', 'tests', params['test_tool']) if params['test_files_dir'].nil?
params['report_format']         = 'documentation' if params['report_format'].nil?
params['tool_installed']        = false if params['tool_installed'].nil?
params['suppress_exit_code']    = false if params['suppress_exit_code'].nil?

def build_test_file_path(test_files_dir, test_file, role, opt_dir)
  classes_txt_file = File.join(opt_dir, 'puppet', 'cache', 'state', 'classes.txt')
  # Returns a file path based on the role or test_file specified,
  # if no role or test_file is specifed then we try to determine the target node's role.
  test_file = "#{role}.rb" unless role.to_s.empty?
  if test_file.to_s.empty?
    begin
      node_role = File.read(classes_txt_file).scan(%r{role::\K\w+}).first
    rescue
      node_role = ''
    end
    if node_role.strip.empty?
      raise ['Unable to detect this node\'s role - perhaps puppet has not yet run?',
             "(I tried to determine the role using data from: #{classes_txt_file})",
             'Alternativey, you can provide a test_file parameter to this task:',
             'eg. test_file=web_server.rb'].join(' ')
    else
      test_file = "#{node_role}.rb"
    end
  end
  abs_test_file = File.join(test_files_dir, test_file)
  unless File.file?(abs_test_file)
    raise ["test_file does not exist at: #{abs_test_file}!",
           'Make sure test files exist in your control repo,',
           '(at site-modules/role/files/tests/)'].join(' ')
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
  task_exit_code = 1

  # determine absolute path of test file to be executed
  abs_test_file = build_test_file_path(File.join(params['_installdir'],
                                                 params['test_files_dir']),
                                                 params['test_file'],
                                                 params['role'],
                                                 params['opt_dir'])

  # install gems for test tooling
  unless params['tool_installed']
    install_gem(params['gem_bin'],
                params['test_tool'],
                params['test_tool_version'],
                params['lib_dir'])
  end

  # load gems into path
  $LOAD_PATH.unshift(*Dir.glob(File.expand_path("#{params['lib_dir']}/**/lib", __FILE__)))

  # load helper for test tool

  helper =  File.join(params['_installdir'], params['_modulename'], 'files', 'helpers', "#{params['test_tool']}_helper.rb")
  puts "Getting help..."
  require_relative helper

  # execute test
  test_exit_code = run_test(params['test_tool'], abs_test_file, params['report_format'])

  # by default we fail the task if the test fails, unless we suppress the exit code returned by the test
  task_exit_code = params['suppress_exit_code'] ? 0 : test_exit_code

rescue => e
  puts({ status: 'failure', error: e, backtrace: e.backtrace }.to_json)
  task_exit_code = 1
ensure
  exit task_exit_code
end
