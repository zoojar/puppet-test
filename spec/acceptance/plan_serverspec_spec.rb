require 'spec_helper_acceptance'

describe 'plan test::role with serverspec' do
  test_run_command('mkdir -p /tmp/puppet_test/serverspec ; gem install serverspec -i /tmp/puppet_test/serverspec --no-ri --no-rdoc', 'localhost')
  it 'fails if no test_file specified' do
    plan_result = test_run_plan('test::role',
                                'test_params' => { 'test_tool' => 'serverspec' },
                                'ctrl_params' => { 'tmp_dir' => '/tmp' })
    expect(plan_result['status']).to eq('failure')
  end
  it 'returns helpful error message if no test_file specified' do
    plan_result = test_run_plan('test::role',
                                'test_params' => { 'test_tool' => 'serverspec' },
                                'ctrl_params' => { 'tmp_dir' => '/tmp' })
    expect(plan_result['value'][0]['result']['error']).to match(%r{unable\sto\sdetect\sthis\snode.*\srole\susing\sfacter})
  end
  it 'runs and passes a passing test' do
    plan_result = test_run_plan('test::role',
                                'test_params' => { 'test_tool' => 'serverspec', 'test_file' => 'example_pass.rb' },
                                'ctrl_params' => { 'tmp_dir' => '/tmp' })
    expect(plan_result).to eq('success')
  end
end
