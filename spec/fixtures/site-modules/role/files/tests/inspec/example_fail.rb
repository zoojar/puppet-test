
control 'control-01' do
  impact 1.0
  title 'Service that doesnt exist (this will fail)'
  desc 'isnotaservice should be running'
  describe service('isnotaservice1') do
    it { should be_running }
  end
end

control 'control-02' do
  impact 1.0
  title 'Service that doesnt exist (this will pass)'
  desc 'isnotaservice should not be running'
  describe service('isnotaservice2') do
    it { should_not be_running }
  end
end
