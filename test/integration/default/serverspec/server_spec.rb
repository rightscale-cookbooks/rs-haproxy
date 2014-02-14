require 'spec_helper'

config_file = '/etc/haproxy/haproxy.cfg'

describe file(config_file) do
  it { should be_file }
end

describe "Verify settings in haproxy.cfg file" do
  [
    { "global" => "maxconn 4096" },
    { "global" => "user haproxy" },
    { "global" => "group haproxy" },
    { "global" => "stats socket\s+/var/run/haproxy\.sock user haproxy group haproxy" },
    { "defaults" => "log\s+global" },
    { "defaults" => "mode\s+http" },
    { "defaults" => "balance\s+roundrobin" },
    { "defaults" => "stats uri /haproxy-status" },
    { "defaults" => "http-check disable-on-404" }
  ].each do |pair|
    pair.each do |group, setting|
      it "#{group} should contain #{setting}" do
        find_haproxy_setting(config_file, /#{group}/, /#{setting}/).should == TrueClass
      end
    end
  end
end

describe "The proper user and group should exist on the server" do
  describe user('haproxy') do
    it { should exist }
  end

  describe user('haproxy') do
    it { should belong_to_group 'haproxy' }
  end
end

describe service("haproxy") do
  it { should be_enabled }
  it { should be_running }
end
