# test tools
require 'spec_helper_acceptance'

describe 'test::role task test_tool' do
  include Beaker::TaskHelper::Inventory
  include BoltSpec::Run
  describe 'test_tool=minitest, test_file=example_pass.rb, return_status=true' do
    it 'returns status from test - success' do
      task_result = task_run('test::role', '', '', '', 'test_tool' => 'minitest', 'test_file' => 'example_pass.rb', 'return_status' => true)
      expect(task_result[0]['status']).to eq('success')
    end
    it 'returns status from test - failure' do
      task_result = task_run('test::role', '', '', '', 'test_tool' => 'minitest', 'test_file' => 'example_fail.rb', 'return_status' => true)
      expect(task_result[0]['status']).to eq('failure')
    end
  end

  describe 'test_tool=serverspec, test_file=example_pass.rb, return_status=true' do
    it 'returns status from test - success' do
      task_result = task_run('test::role', '', '', '', 'test_tool' => 'serverspec', 'test_file' => 'example_pass.rb', 'return_status' => true)
      expect(task_result[0]['status']).to eq('success')
    end
    it 'returns status from test - failure' do
      task_result = task_run('test::role', '', '', '', 'test_tool' => 'serverspec', 'test_file' => 'example_fail.rb', 'return_status' => true)
      expect(task_result[0]['status']).to eq('failure')
    end
  end

  describe 'test_tool=inspec, test_file=example_pass.rb, return_status=true' do
    it 'returns status from test - success' do
      task_result = task_run('test::role', '', '', '', 'test_tool' => 'inspec', 'test_file' => 'example_pass.rb', 'return_status' => true)
      expect(task_result[0]['status']).to eq('success')
    end
    it 'returns status from test - failure' do
      task_result = task_run('test::role', '', '', '', 'test_tool' => 'inspec', 'test_file' => 'example_fail.rb', 'return_status' => true)
      expect(task_result[0]['status']).to eq('failure')
    end
  end
end
