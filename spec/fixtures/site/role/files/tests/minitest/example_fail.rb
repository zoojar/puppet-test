require 'minitest/autorun'
require 'open3'

describe "file /etc/hosts" do
  it "must contain localhost" do
    stdout = Open3.capture3(*['cat', '/etc/hosts'])[0]
    assert stdout =~ /localhost/
  end
end

describe "file /etc/hosts" do
  it "must contain localhost" do
    stdout = Open3.capture3(*['cat', '/etc/hosts'])[0]
    assert stdout =~ /remotehost/
  end
end