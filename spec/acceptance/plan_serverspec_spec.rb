require 'spec_helper_acceptance'

describe 'plan test::role with serverspec' do
  it 'fails if no test_file specified' do
    plan_result = test_run_plan('test::role',
                                'test_params' => { 'test_tool' => 'serverspec' },
                                'ctrl_params' => { 'tmp_dir' => '/tmp' })
    expect(plan_result).to eq('failure')
  end
  it 'returns helpful error message if no test_file specified' do
    plan_result = test_run_plan('test::role',
                                'test_params' => { 'test_tool' => 'serverspec' },
                                'ctrl_params' => { 'tmp_dir' => '/tmp' })
    expect(plan_result).to match(%r{unable\sto\sdetect\sthis\snode.*\srole\susing\sfacter})
  end
  it 'installs (stages) the serverspec gem on the controller' do
    test_run_plan('test::role',
                  'test_params' => { 'test_tool' => 'serverspec', 'test_file' => 'example_pass.rb' },
                  'ctrl_params' => { 'tmp_dir' => '/tmp' })
    cmd_result = test_run_command('ls /tmp/puppet_test/serverspec/', 'localhost')
    expect(cmd_result[0]).to eq('success')
  end
  it 'runs and passes a passing test' do
    plan_result = test_run_plan('test::role',
                                'test_params' => { 'test_tool' => 'serverspec', 'test_file' => 'example_pass.rb' },
                                'ctrl_params' => { 'tmp_dir' => '/tmp' })
    expect(plan_result).to eq('success')
  end
end
