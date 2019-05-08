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

  $test_params_defaults = {
    tool_installed => true,
    test_tool      => 'serverspec',
    _catch_errors  => true,
    opt_dir        => run_task('facter_task', $target, 'Getting target OS kernel', fact => 'kernel').first.value[kernel] ? { 
      'Windows' => 'c:/programdata/puppetlabs', 
      default   => '/opt/puppetlabs',
    },
  }

  $ctrl_params_defaults = {
    target              => 'localhost',
    compress_tool       => false,
    install_gem         => true,
    gem_version         => latest,
    gem_install_options => [ '--no-ri', '--no-rdoc' ],
    opt_dir             => run_task('facter_task', $controller, 'Getting controller OS kernel', fact => 'kernel').first.value[kernel] ? {
      'Windows' => 'c:/programdata/puppetlabs', 
      default   => '/opt/puppetlabs',
    },
  }

  # merge defaults
  $_test_tool = $test_params['test_tool'] ? {
    undef   => 'serverspec',
    default => $test_params['test_tool'],
  }

  $_ctrl_params = $ctrl_params_defaults + { lib_dir => "${ctrl_params_defaults[opt_dir]}/acid_lib/${_test_tool}" } + $ctrl_params
  $_test_params = $test_params_defaults + { lib_dir => "${test_params_defaults[opt_dir]}/acid_lib/${_test_tool}" } + $test_params

  # Stage the gems to tmp dir on the controller
  unless $_ctrl_params[install_gem] == false {
    run_command("mkdir -p ${_ctrl_params[lib_dir]}", $controller, '_catch_errors' => true, '_run_as' => 'root')
    run_command([
        "${_ctrl_params[opt_dir]}/puppet/bin/gem install ${_test_params[test_tool]}",
        "--install_dir=${_ctrl_params[lib_dir]}",
        *$_ctrl_params[gem_install_options],
      ].join(' '),
      $controller, '_catch_errors' => true, '_run_as' => 'root')
  }

  if $_ctrl_params[compress_tool] {
    # Compress if target is linux, native file compression in windows...bleghhh
    run_command("tar -zcf ${_ctrl_params[lib_dir]}/${_test_params[test_tool]}.tar.gz ${_ctrl_params[lib_dir]}",
        $controller, '_catch_errors' => true, '_run_as' => 'root')
    # make lib dir on target
    run_command("mkdir -p ${_test_params[lib_dir]}", $target, '_catch_errors' => true, '_run_as' => 'root')
    # upload gems from controller to tmp dir on target
    upload_file("${_ctrl_params[lib_dir]}/${_test_params[test_tool]}.tar.gz", "${_test_params[lib_dir]}/../${_test_params[test_tool]}.tar.gz",
        $target, '_catch_errors' => true, '_run_as' => 'root')
    # Extract
    run_command("tar -zxf ${_test_params[lib_dir]}/../${_test_params[test_tool]}.tar.gz -C ${_test_params[lib_dir]}",
        $target, '_catch_errors' => true, '_run_as' => 'root')
  } else {
    # upload tool
    upload_file($_ctrl_params[lib_dir],
                $_test_params[lib_dir],
                $target,
                "Uploading gems from '${_ctrl_params[lib_dir]}' to target '${target}' at '${_test_params[lib_dir]}'",
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
