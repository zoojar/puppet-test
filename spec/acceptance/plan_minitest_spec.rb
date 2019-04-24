# plan
#    bolt plan run test::role --modulepath . --run-as root --params \
#    '{"target":"webserver.local","test_params":{"test_tool":"serverspec", \
#    "test_file":"webserver.rb"},"ctrl_params":{"tmp_dir":"/Users/Shared/tmp"}}'
require 'spec_helper_acceptance'

describe 'plan test::role with minitest' do
  include BoltSpec::Run
  describe 'test_tool=minitest' do
    it 'fails to run' do
      plan_result = run_plan('test::role',
                             'target'      => 'webserver.local',
                             'test_params' => { 'test_tool' => 'serverspec', 'test_file' => 'webserver.rb' },
                             'ctrl_params' => { 'tmp_dir' => '/Users/Shared/tmp' })
      expect(plan_result['status']).to eq('failure')
    end
    it 'returns helpful error message' do
      plan_result = run_plan('test::role',
                             'target'      => 'webserver.local',
                             'test_params' => { 'test_tool' => 'serverspec' },
                             'ctrl_params' => { 'tmp_dir' => '/Users/Shared/tmp' })
      expect(plan_result['result']['_output']).to match(%r{unable\sto\sdetect\sthis\snode.*\srole\susing\sfacter})
    end
  end
end
