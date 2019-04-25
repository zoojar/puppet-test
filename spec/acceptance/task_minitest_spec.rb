# run a test task
require 'spec_helper_acceptance'

describe 'test_tool=minitest' do
  it 'fails to run when no arguments are passed' do
    task_result = task_run('test::role', 'test_tool' => 'minitest')
    expect(task_result[0]['status']).to eq('failure')
  end

  it 'returns helpful error message when no arguments are passed' do
    task_params = { 'test_tool' => 'minitest' }
    task_result = task_run('test::role', target_node_name, task_params, bolt_params)
    expect(task_result[0]['result']['_output']).to match(%r{unable\sto\sdetect\sthis\snode.*\srole\susing\sfacter})
  end

  it 'runs a passing test successfully (test_tool=minitest, test_file=example_pass.rb)' do
    task_params = { 'test_tool' => 'minitest', 'test_file' => 'example_pass.rb' }
    task_result = task_run('test::role', target_node_name, task_params, bolt_params)
    expect(task_result[0]['status']).to eq('success')
  end

  it 'returns output (test_tool=minitest, test_file=example_pass.rb)' do
    task_params = { 'test_tool' => 'minitest', 'test_file' => 'example_pass.rb' }
    task_result = task_run('test::role', target_node_name, task_params, bolt_params)
    expect(task_result[0]['result']['_output']).to match(%r{2\sruns,\s2\sassertions,\s0\sfailures,\s0\serrors,\s0\sskips})
  end

  it 'fails a failing test' do
    task_params = { 'test_tool' => 'minitest', 'test_file' => 'example_fail.rb' }
    task_result = task_run('test::role', target_node_name, task_params, bolt_params)
    expect(task_result[0]['status']).to eq('failure')
  end
end
