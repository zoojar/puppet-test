require 'serverspec'

describe service('isnotaservice1') do
  it { should_not be_running }
end

describe service('isnotaservice2') do
  it { should_not be_running }
end

describe service('com.apple.mediaremoted') do
  it { should_not be_running }
end
