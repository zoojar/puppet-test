# This plan should be run from a Puppet server or a linux host with:
# 1. capability for pcp transport to target nodes ('puppetlabs-bolt_shim' module required)
# 2. dev tools (make gcc / build-essential) present for gem staging
# Example usage:
#  IMPORTANT: Tests should be stored with roles at site-modules/roles/files/tests (or site-modules/role/files/tests),
#  for example: 
#    `<control-repo>/site-modules/roles/files/tests/<test_tool>/<role>.rb`
#  This plan will fail if this path is not accessible!
#  If running via Bolt; roles must be on bolt's configured modulepath - run this from your control-repo:
#
# git clone $control_repo && cd $control_repo
# r10k puppetfile install
# bolt plan run acid::test --modulepath modules:site-modules --run-as root --params   '{"target":"pcp://ci-agent.local","test_params":{"test_tool":"serverspec"}}'
#
#
# NB. If the 'test_file' param is omitted then roles will be auto-detected using the target's 'role' fact

plan acid::test(
  TargetSpec           $target,
  Optional[TargetSpec] $controller    = get_targets('localhost')[0],
  Optional[Hash]       $ctrl_params   = {},
  Optional[Hash]       $test_params   = {}
) {

  # check that we have core modules available for bolt gem
  ['service', 'facts', 'puppet_agent'].each |$mod| {
    unless module_directory($mod) { fail_plan("Core module missing [${mod}]") }
  }

  # find the tests, where are the tests? role or roles?
  if    module_directory('role' ) { $_role_dir = 'role'  }
  elsif module_directory('roles') { $_role_dir = 'roles' }
  else  { fail_plan([
      'Aborting Plan: No role or roles module found on the module path.',
      'This task picks up a test for a given role.',
      'Store your tests at: ',
      '<control-repo>/site-modules/role/files/tests/<test_tool>/<role>.rb',
    ].join(' '))
  }

  # verify that a test tool is specified (serverspec/inspec/minitest)
  unless $test_params[test_tool] {
    fail_plan([
      'Aborting Plan: No test_tool specified in options hash.',
      'Please specify one, Bolt example:',
      '--params \'{\"test_params\":{\"test_tool\":\"serverspec\"}\'',
    ].join(' '))
  }

  # If unspecififed, detect opt dir based on kernel
  $target_kernel = $test_params[kernel] ? {
    undef   => run_task('facter_task', $target, 'Getting target OS kernel using facter_task', fact => 'kernel').first.value[kernel],
    default => $test_params[kernel],
  }

  $test_params_defaults[opt_dir] = $target_kernel ? { 'Windows' => 'c:/programdata/puppetlabs', default => '/opt/puppetlabs' }

  $ctrl_kernel = $ctrl_params[kernel] ? {
    undef   => run_task('facter_task', $controller, 'Getting controller OS kernel using facter_task', fact => 'kernel').first.value[kernel],
    default => $ctrl_params[kernel],
  }
  
  $ctrl_params_defaults[opt_dir] = $ctrl_kernel ? { 'Windows' => 'c:/programdata/puppetlabs', default => '/opt/puppetlabs' }

  $test_params_defaults = {
    tool_installed        => true,
    test_tool             => 'serverspec',
    _catch_errors         => true,
  }

  $ctrl_params_defaults = {
    target              => 'localhost',
    compress_tool       => false,
    install_gem         => true,
    gem_version         => latest,
    gem_install_options => [ '--no-ri', '--no-rdoc' ]
  }

  # merge defaults with params
  $_ctrl_params    = $ctrl_params_defaults + $ctrl_params
  $_test_params    = $test_params_defaults + $test_params
  $_test_tool      = $_test_params[test_tool]
  unless $test_params[lib_dir] { $_test_params[lib_dir] = "${opt_dir}/acid_lib/${_test_params[test_tool]}" }
  unless $ctrl_params[lib_dir] { $_ctrl_params[lib_dir] = "${opt_dir}/acid_lib/${_test_params[test_tool]}" }

  # Stage the gems to tmp dir on the controller
  $_ctrl_gem_dir = "${_ctrl_params[lib_dir]}/${$_test_tool}"
  unless $_ctrl_params[install_gem] == false {
    apply($controller, _catch_errors => true) {
      file { $_ctrl_params[lib_dir] : ensure => directory }
      package { $_test_tool:
        ensure          => $_ctrl_params[gem_version],
        provider        => puppet_gem,
        install_options => $_ctrl_params[gem_install_options] << { '--install_dir' => $_ctrl_params[lib_dir] },
      }
    }
  }

  if $target_kernel == 'Linux' and $_ctrl_params[compress_tool] {
    # Compress if target is linux, native file compression in windows...bleghhh
    run_command("tar -zcf ${_ctrl_params[lib_dir]}/${_test_tool}.tar.gz ${_ctrl_params[lib_dir]}",
        $controller, '_catch_errors' => true, '_run_as' => 'root')
    # make lib dir on target
    run_command("mkdir -p ${_test_params[lib_dir]}", $target, '_catch_errors' => true, '_run_as' => 'root')
    # upload gems from controller to tmp dir on target
    upload_file("${_ctrl_params[lib_dir]}/${_test_tool}.tar.gz", "${_test_params[lib_dir]}/../${_test_tool}.tar.gz",
        $target, '_catch_errors' => true, '_run_as' => 'root')
    # Extract
    run_command("tar -zxf ${_test_params[lib_dir]}/../${_test_tool}.tar.gz -C ${_test_params[lib_dir]}",
        $target, '_catch_errors' => true, '_run_as' => 'root')
  } else {
    # upload tool
    upload_file($_ctrl_params[lib_dir],
                $_test_params[lib_dir],
                $target,
                "Uploading gems from '${_ctrl_params[lib_dir]}' to target '${target}' in tmpdir '${_test_params[lib_dir]}'",
                '_catch_errors' => true,
                '_run_as' => 'root')
  }

  # execute tests
  $result = run_task("acid::test", $target, "Executing tests with the following params: ${_test_params}", $_test_params)

  if $result.ok {
    return $result
  } else {
    fail_plan('Plan failed', 'error', $result.first.value)
  }
}
