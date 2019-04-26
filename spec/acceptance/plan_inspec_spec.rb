require 'spec_helper_acceptance'

# inspec requires build-essential / dev tools for gem install
# so the plan is used for inspec - we build locally and copy to node.

describe 'plan test::role with inspec' do
  it 'fails if no test_file specified' do
    plan_result = test_run_plan('test::role',
                                'test_params' => { 'test_tool' => 'inspec' },
                                'ctrl_params' => { 'tmp_dir' => '/tmp' })
    expect(plan_result['status']).to eq('failure')
  end
  it 'returns helpful error message if no test_file specified' do
    plan_result = test_run_plan('test::role',
                                'test_params' => { 'test_tool' => 'inspec' },
                                'ctrl_params' => { 'tmp_dir' => '/tmp' })
    expect(plan_result).to match(%r{unable\sto\sdetect\sthis\snode.*\srole\susing\sfacter})
  end
  it 'runs and passes a passing test' do
    plan_result = test_run_plan('test::role',
                                'test_params' => { 'test_tool' => 'inspec', 'test_file' => 'example_pass.rb' },
                                'ctrl_params' => { 'tmp_dir' => '/tmp' })
    expect(plan_result['status']).to eq('success')
  end
end
