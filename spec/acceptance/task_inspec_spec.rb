# run a test task
require 'spec_helper_acceptance'

describe 'test_tool=inspec' do
  # inspec requires build-essential / dev tools for gem install
  # so the plan is used for inspec - we build locally and copy to node.
  it 'fails to run' do
    task_result = test_run_task('test::role', 'test_tool' => 'inspec')
    expect(task_result[0]['status']).to eq('failure')
  end

  it 'returns helpful error message' do
    task_result = test_run_task('test::role', 'test_tool' => 'inspec')
    expect(task_result[0]['result']['_output']).to match(%r{unable\sto\sdetect\sthis\snode.*\srole\susing\sfacter})
  end
end

