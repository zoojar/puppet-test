# run a test task
require 'spec_helper_acceptance'

describe 'task_run test, test_tool=minitest' do
  include BoltSpec::Run
  it 'fails to run when no arguments are passed' do
    task_result = task_run('test::role', 'test_tool' => 'minitest')
    expect(task_result[0]['status']).to eq('failure')
  end
  it 'returns helpful error message when no arguments are passed' do
    task_result = task_run('test::role', 'test_tool' => 'minitest')
    expect(task_result[0]['result']['_output']).to match(%r{unable\sto\sdetect\sthis\snode.*\srole\susing\sfacter})
  end
  it 'runs a passing test successfully (test_tool=minitest, test_file=example_pass.rb)' do
    task_result = task_run('test::role', 'test_tool' => 'minitest', 'test_file' => 'example_pass.rb')
    expect(task_result[0]['status']).to eq('success')
  end
  it 'returns output (test_tool=minitest, test_file=example_pass.rb)' do
    task_result = task_run('test::role', 'test_tool' => 'minitest', 'test_file' => 'example_pass.rb')
    expect(task_result[0]['result']['_output']).to match(%r{2\sruns,\s2\sassertions,\s0\sfailures,\s0\serrors,\s0\sskips})
  end
  it 'does not return the status from the test when params: return_status=false' do
    task_result = task_run('test::role', 'test_tool' => 'minitest', 'test_file' => 'example_fail.rb', 'return_status' => false)
    expect(task_result[0]['status']).to eq('success')
  end
  it 'returns status from test success when params: return_status=true' do
    task_result = task_run('test::role', 'test_tool' => 'minitest', 'test_file' => 'example_pass.rb', 'return_status' => true)
    expect(task_result[0]['status']).to eq('success')
  end
  it 'returns status from test failure when params: return_status=true' do
    task_result = task_run('test::role', 'test_tool' => 'minitest', 'test_file' => 'example_fail.rb', 'return_status' => true)
    expect(task_result[0]['status']).to eq('failure')
  end
end
