# run a test task
require 'spec_helper_acceptance'

describe 'test_tool=minitest' do
  it 'fails to run when no arguments are passed' do
    task_result = test_run_task('test::role', 'test_tool' => 'minitest')
    expect(task_result[0]['status']).to eq('failure')
  end

  it 'returns an error message when no arguments are passed' do
    task_params = { 'test_tool' => 'minitest' }
    task_result = test_run_task('test::role', task_params)
    expect(task_result[0]['result']['error']).to match(%r{unable\sto\sdetect\sthis\snode.*\srole\susing\sfacter})
  end

  it 'runs a passing test successfully (test_tool=minitest, test_file=example_pass.rb)' do
    task_params = { 'test_tool' => 'minitest', 'test_file' => 'example_pass.rb' }
    task_result = test_run_task('test::role', task_params)
    expect(task_result[0]['status']).to eq('success')
  end

  it 'returns at test report' do
    task_params = { 'test_tool' => 'minitest', 'test_file' => 'example_pass.rb' }
    task_result = test_run_task('test::role', task_params)
    expect(task_result[0]['result']['_output']).to match(%r{2\sruns,\s2\sassertions,\s0\sfailures,\s0\serrors,\s0\sskips})
  end

  it 'fails a failing test' do
    task_params = { 'test_tool' => 'minitest', 'test_file' => 'example_fail.rb' }
    task_result = test_run_task('test::role', task_params)
    expect(task_result[0]['status']).to eq('failure')
  end
end
