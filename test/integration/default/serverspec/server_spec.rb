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
    { "defaults" => "http-check disable-on-404" },
    { "backend app1" => "server app1host2 10.1.55.33:80 inter 300 rise 2 fall 3 maxconn 100 cookie app1host2" },
    { "backend app1" => "server app1host1 10.1.55.22:80 inter 300 rise 2 fall 3 maxconn 100 cookie app1host1" },
    { "backend app2" => "server app2host1 10.1.66.22:80 inter 300 rise 2 fall 3 maxconn 100 cookie app2host1" },
    { "backend app3" => "server app3host1 10.1.77.44:80 inter 300 rise 2 fall 3 maxconn 100 cookie app3host1" },
    { "backend default" => "server discourse 166.78.170.64:80 inter 300 rise 2 fall 3 maxconn 100 cookie discourse" }
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

describe port(80) do
  it { should be_listening.with('tcp')  }
end

describe service("haproxy") do
  it { should be_enabled }
  it { should be_running }
end

describe "Should return the correct Discourse webpage greeting" do
  describe command('curl 33.33.33.5/login | grep -o "Welcome to RightScale RightScale Discourse"') do
    it { should return_stdout 'Welcome to RightScale RightScale Discourse'}
  end
end
