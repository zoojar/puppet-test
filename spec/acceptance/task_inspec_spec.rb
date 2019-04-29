# run a test task
require 'spec_helper_acceptance'

describe 'test_tool=inspec' do
  # inspec requires build-essential / dev tools for gem install
  it 'fails to run if no test file specified' do
    task_result = test_run_task('test::role', 'test_tool' => 'inspec')
    expect(task_result[0]['status']).to eq('failure')
  end

  it 'returns helpful error message if no test file specified' do
    task_result = test_run_task('test::role', 'test_tool' => 'inspec')
    expect(task_result[0]['result']['error']).to match(%r{unable\sto\sdetect\sthis\snode.*\srole\susing\sfacter})
  end

  it 'fails to run if no build tools are present and returns helpful error message' do
    task_result = test_run_task('test::role', 'test_tool' => 'inspec', 'test_file' => 'example_pass.rb')
    expect(task_result[0]['status']).to eq('failure')
    expect(task_result[0]['result']['error']).to match(%r{Failed\sto\sbuild\sgem})
  end
end
