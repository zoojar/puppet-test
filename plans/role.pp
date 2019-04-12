# This plan should be run from a Puppet server or a linux host with capability for pcp transport to target nodes
# Example usage:
#  IMPORTANT: Tests should be stored with roles at site-modules/roles/files/tests (or site-modules/role/files/tests),
#  for example: 
#    `<control-repo>/site-modules/roles/files/tests/<test_tool>/<role>.rb`
#  This plan will fail if this path is not accessible!
#  If running via Bolt; roles must be on bolt's configured modulepath - run this from your control-repo:
#
#
#    bolt plan run test::role --modulepath . --run-as root --params \
#    '{"target":"webserver.local","test_params":{"test_tool":"serverspec", \
#    "test_file":"webserver.rb"},"ctrl_params":{"tmp_dir":"/Users/Shared/tmp"}}'
#
#
# NB. If the 'test_file' param is omitted then roles will be auto-detected using the target's 'role' fact

plan test::role(
  TargetSpec           $target,
  Optional[TargetSpec] $controller    = get_targets('localhost')[0],
  Optional[Hash]       $ctrl_params   = {},
  Optional[Hash]       $test_params   = {},
) {

  # find the tests, where are the tests? role or roles?
  if    module_directory('role' ) { $_role_dir = 'role'  }
  elsif module_directory('roles') { $_role_dir = 'roles' }
  else  { fail_plan([
      'Aborting Plan: No role or roles module found on the module path.',
      'This task picks up a test for a given role.',
      'Store your tests at: ',
      '<control-repo>/site-modules/roles/files/tests/<test_tool>/<role>.rb',
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

  # We need a static dir to upload gems to,
  ## because bolt tasks delete their tmp dirs after executing.
  ### If unspecififed, detect target's tmp dir based on kernel
  $target_kernel = $test_params[kernel] ? {
    undef   => run_task('test::get_fact', $target, fact => 'kernel').first.value[_output],
    default => $test_params[kernel]
  }

  case $target_kernel {
    /Linux|Darwin/: { $target_tmp_dir = '/tmp' ; $ruby_bin  = '/opt/puppetlabs/bin/puppet/ruby' }
    'Windows':{ $target_tmp_dir = 'c:/temp' ; $ruby_bin  = 'c:/programdata/puppetlabs/puppet/bin/ruby' }
    default: { raise('unsupported os') }
  }
  $target_platform = $test_params[platform] ? {
    undef   => run_task('test::get_fact', $target, fact => 'rubyplatform').first.value[_output],
    default => $test_params[platform]
  }
  notice "Target gem platform detected: ${target_platform}"
  $test_params_defaults = {
    tool_installed        => true,
    test_tool_install_dir => "${target_tmp_dir}/puppet_test/${test_params[test_tool]}",
    _catch_errors         => true,
  }

  $ctrl_params_defaults = {
    target        => 'localhost',
    tmp_dir       => '/tmp',
    compress_tool => false,
  }

  # merge defaults with params
  $_ctrl_params    = $ctrl_params_defaults + $ctrl_params
  $_test_params    = $test_params_defaults + $test_params
  $_test_tool      = $_test_params[test_tool]
  $_target_gem_dir = $_test_params[test_tool_install_dir]

  # Stage the gems to tmp dir on the controller
  $_ctrl_gem_dir = "${_ctrl_params[tmp_dir]}/puppet_test/${$_test_tool}"
  unless $_ctrl_params[install_gem] == false {
    run_task('test::install_gem', $controller, { gem => $_test_tool, install_dir => $_ctrl_gem_dir, platform => $target_platform })
  }
  if $target_kernel == 'Linux' and $_ctrl_params[compress_tool] {
    # Compress if target is linux, native file compression in windows...bleghhh
    run_command("tar -zcf ${_ctrl_gem_dir}/${_test_tool}.tar.gz ${_ctrl_gem_dir}",
        $controller, '_catch_errors' => true, '_run_as' => 'root')
    # upload gems from controller to tmp dir on target
    upload_file("${_ctrl_gem_dir}/${_test_tool}.tar.gz", "${target_tmp_dir}/${_test_tool}.tar.gz",
        $target, '_catch_errors' => true, '_run_as' => 'root')
    # Extract
    run_command("mkdir -p ${_target_gem_dir} && tar -zxf ${target_tmp_dir}/${_test_tool}.tar.gz -C ${_target_gem_dir}",
        $target, '_catch_errors' => true, '_run_as' => 'root')
  } else {
    # upload tool
    upload_file($_ctrl_gem_dir, $_target_gem_dir, $target, '_catch_errors' => true, '_run_as' => 'root')
  }

  # execute tests
  return run_task("test::${_role_dir}", $target, $_test_params)

}
