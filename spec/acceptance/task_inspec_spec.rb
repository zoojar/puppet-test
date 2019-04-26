# run a test task
require 'spec_helper_acceptance'

describe 'test_tool=inspec' do

  # inspec requires build-essential for gem install
  it 'ensures build-essential is installed' do
    cmd_result = run_shell('puppet resource package build-essential ensure=installed')
    expect(cmd_result[0]).to eq('success')
  end



  it 'fails to run' do
    task_result = task_run('test::role', 'test_tool' => 'inspec')
    expect(task_result[0]['status']).to eq('failure')
  end

  it 'returns helpful error message' do
    task_result = task_run('test::role', 'test_tool' => 'inspec')
    expect(task_result[0]['result']['_output']).to match(%r{unable\sto\sdetect\sthis\snode.*\srole\susing\sfacter})
  end

  it 'installs inspec gem' do
    task_run('test::role', 'test_tool' => 'inspec', 'test_file' => 'example_pass.rb')
    cmd_result = run_shell('ls /tmp/puppet_test/inspec/gems/inspec*/inspec.gemspec')
    expect(cmd_result[0]['status']).to eq('success')
  end

  it 'runs a passing test successfully' do
    task_result = task_run('test::role', 'test_tool' => 'inspec', 'test_file' => 'example_pass.rb')
    expect(task_result[0]['status']).to eq('success')
  end

  it 'returns output' do
    task_result = task_run('test::role', 'test_tool' => 'inspec', 'test_file' => 'example_pass.rb')
    expect(task_result[0]['result']['_output']).to match(%r{\d+\sexamples,\s0\sfailures})
  end

  it 'fails a failing test' do
    task_result = task_run('test::role', 'test_tool' => 'inspec', 'test_file' => 'example_fail.rb')
    expect(task_result[0]['status']).to eq('failure')
  end
end

