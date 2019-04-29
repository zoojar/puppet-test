# run a test task
require 'spec_helper_acceptance'

describe 'test_tool=serverspec' do
  it 'without params, fails to run' do
    task_params = { 'test_tool' => 'serverspec' }
    task_result = test_run_task('test::role', task_params)
    expect(task_result[0]['status']).to eq('failure')
  end

  it 'fails and returns helpful error message when no params are specified' do
    task_params = { 'test_tool' => 'serverspec' }
    task_result = test_run_task('test::role', task_params)
    expect(task_result[0]).to match(%r{unable\sto\sdetect\sthis\snode.*\srole\susing\sfacter!})
  end

  it 'runs a passing test successfully' do
    task_params = { 'test_tool' => 'serverspec', 'test_file' => 'example_pass.rb' }
    task_result = test_run_task('test::role', task_params)
    expect(task_result[0]['status']).to eq('success')
  end

  it 'returns output' do
    task_params = { 'test_tool' => 'serverspec', 'test_file' => 'example_pass.rb' }
    task_result = test_run_task('test::role', task_params)
    expect(task_result[0]['result']['_output']).to match(%r{\d+\sexamples,\s0\sfailures})
  end

  it 'fails a failing test' do
    task_params = { 'test_tool' => 'serverspec', 'test_file' => 'example_fail.rb' }
    task_result = test_run_task('test::role', task_params)
    expect(task_result[0]['status']).to eq('failure')
  end
end
