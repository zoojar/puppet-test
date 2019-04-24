# run a test task
require 'spec_helper_acceptance'
include BoltSpec::Run

describe 'test::role with minitest' do
  describe 'test_tool=minitest' do
    it 'fails to run' do
      task_result = run_task('test::role', '', '', '', 'test_tool' => 'minitest')
      expect(task_result[0]['status']).to eq('failure')
    end
    it 'returns helpful error message' do
      task_result = run_task('test::role', '', '', '', 'test_tool' => 'minitest')
      expect(task_result[0]['result']['_output']).to match(%r{unable\sto\sdetect\sthis\snode.*\srole\susing\sfacter})
    end
  end

  describe 'test_tool=minitest, test_file=example_pass.rb' do
    it 'runs a passing test successfully' do
      task_result = run_task('test::role', '', '', '', 'test_tool' => 'minitest', 'test_file' => 'example_pass.rb')
      expect(task_result[0]['status']).to eq('success')
    end
    it 'returns output' do
      task_result = run_task('test::role', '', '', '', 'test_tool' => 'minitest', 'test_file' => 'example_pass.rb')
      expect(task_result[0]['result']['_output']).to match(%r{2\sruns,\s2\sassertions,\s0\sfailures,\s0\serrors,\s0\sskips})
    end
  end

  describe 'test_tool=minitest, test_file=example_pass.rb, return_status=false' do
    it 'does not return the status from the test' do
      task_result = run_task('test::role', '', '', '', 'test_tool' => 'minitest', 'test_file' => 'example_fail.rb', 'return_status' => false)
      expect(task_result[0]['status']).to eq('success')
    end
  end

  describe 'test_tool=minitest, test_file=example_pass.rb, return_status=true' do
    it 'returns status from test - success' do
      task_result = run_task('test::role', '', '', '', 'test_tool' => 'minitest', 'test_file' => 'example_pass.rb', 'return_status' => true)
      expect(task_result[0]['status']).to eq('success')
    end
    it 'returns status from test - failure' do
      task_result = run_task('test::role', '', '', '', 'test_tool' => 'minitest', 'test_file' => 'example_fail.rb', 'return_status' => true)
      expect(task_result[0]['status']).to eq('failure')
    end
  end
end
