# plan
#    bolt plan run test::role --modulepath . --run-as root --params \
#    '{"target":"webserver.local","test_params":{"test_tool":"serverspec", \
#    "test_file":"webserver.rb"},"ctrl_params":{"tmp_dir":"/Users/Shared/tmp"}}'
require 'spec_helper_acceptance'

describe 'plan test::role with minitest' do
  include Beaker::TaskHelper::Inventory
  include BoltSpec::Run
  describe 'test_tool=minitest' do
    it 'fails to run' do
      plan_result = plan_run('test::role', '', '', '', "target" => "webserver.local", "test_params" => {"test_tool" => "serverspec",  "test_file" => "webserver.rb" }, "ctrl_params" => { "tmp_dir" => "/Users/Shared/tmp" })
      expect(plan_result[0]['status']).to eq('failure')
    end
    it 'returns helpful error message' do
      task_result = task_run('test::role', '', '', '', 'test_tool' => 'minitest')
      expect(task_result[0]['result']['_output']).to match(%r{unable\sto\sdetect\sthis\snode.*\srole\susing\sfacter})
    end
  end
end
