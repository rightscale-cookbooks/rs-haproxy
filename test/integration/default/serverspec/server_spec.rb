require 'spec_helper'

describe file("/etc/haproxy/haproxy.cfg") do
  it { should be_file }
end

config = HAProxy::Config.parse_file('/etc/haproxy/haproxy.cfg')

describe "gem haproxy-tools should be intalled" do
  describe command("gem list | grep haproxy-tools") do
    it { should return_stdout /haproxy-tools/  }
  end
end

describe "Verify values in config file" do
  describe "global maxconn" do
    config.global["maxconn"].should == "4096"
  end
end


describe service("haproxy") do
  it { should be_enabled }
  it { should be_running }
end
