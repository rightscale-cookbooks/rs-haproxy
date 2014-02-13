require 'spec_helper'

config_file = '/etc/haproxy/haproxy.cfg'

describe file(config_file) do
  it { should be_file }
end

describe "Verify settings in haproxy.cfg file" do
  [
    { "global" => "log 127\.0\.0\.1\.*local0$"},
    { "global" => "log 127\.0\.0\.1\s+local1 notice$" },
    { "global" => "maxconn 4096" },
    { "global" => "user haproxy" },
    { "global" => "group haproxy" },
    { "global" => "stats socket\s+/var/run/haproxy\.sock user haproxy group haproxy" },
    { "defaults" => "log\s+global" },
    { "defaults" => "mode\s+http" }, 
    { "backend default" => "mode http"}
  ].each do |pair| 
    pair.each do |group, setting|
      it "#{group} should contain #{setting}" do
        find_haproxy_setting(config_file, /#{group}/, /#{setting}/).should == TrueClass 
      end
    end
  end
end

describe service("haproxy") do
  it { should be_enabled }
  it { should be_running }
end
