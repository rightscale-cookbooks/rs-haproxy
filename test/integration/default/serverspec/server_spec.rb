require 'spec_helper'

config_file = '/etc/haproxy/haproxy.cfg'

describe file(config_file) do
  it { should be_file }
end

describe file('/var/run/haproxy.sock') do
  it { should be_socket }
end


# Helper function find_haproxy_setting takes three arguments.
# Name of cfg file, group name, setting under group.  (See spec_helper file)
# Function returns true if regex matching setting is found in that group.
# Array of pairs is used to avoid nested hashes, or a workaround for duplicate keys in the hashes.
describe "Verify settings in haproxy.cfg file" do
  [
    [ "global",  "maxconn 4096" ],
    [ "global",  "user haproxy" ],
    [ "global",  "group haproxy" ],
    [ "global",  "stats socket\s+/var/run/haproxy\.sock user haproxy group haproxy" ],
    [ "defaults",  "log\s+global" ],
    [ "defaults",  "mode\s+http" ],
    [ "defaults",  "balance\s+roundrobin" ],
    [ "defaults",  "stats uri /haproxy-status" ],
    [ "defaults",  "http-check disable-on-404" ],
    [ "backend app1",  "server app1host2 10.1.55.33:80 inter 300 rise 2 fall 3 maxconn 100 cookie app1host2" ],
    [ "backend app1",  "server app1host1 10.1.55.22:80 inter 300 rise 2 fall 3 maxconn 100 cookie app1host1" ],
    [ "backend app2",  "server app2host1 10.1.66.22:80 inter 300 rise 2 fall 3 maxconn 100 cookie app2host1" ],
    [ "backend app3",  "server app3host1 10.1.77.44:80 inter 300 rise 2 fall 3 maxconn 100 cookie app3host1" ],
    [ "backend default",  "server discourse 166.78.170.64:80 inter 300 rise 2 fall 3 maxconn 100 cookie discourse" ]
  ].each do |pair|
    it "#{pair.first} should contain #{pair.last}" do
        find_haproxy_setting(config_file, pair.first, pair.last).should == true 
    end
  end
end

describe service("haproxy") do
  it { should be_enabled }
  it { should be_running }
end

describe "The proper user and group should exist on the server" do
  describe user('haproxy') do
    it { should exist }
  end
  describe user('haproxy') do
    it { should belong_to_group 'haproxy' }
  end
end

describe "Verify correct port set and redirects to backend server." do
  describe port(80) do
    it { should be_listening.with('tcp')  }
  end
  describe "Accessing ip:port should return redirect message" do
    describe command('curl --silent 33.33.33.5:80 | grep -o "You are being.*redirected"') do
      it { should return_stdout 'You are being <a href="http://33.33.33.5/login">redirected' }
    end
  end
  describe "Request at IP/haproxy-status should return stats page" do
    describe command('curl --silent 33.33.33.5/haproxy-status | grep -o "Statistics Report for HAProxy"') do
      it { should return_stdout 'Statistics Report for HAProxy' }
    end
  end
  describe "Should return the correct Discourse webpage greeting from backend" do
    describe command('curl --silent 33.33.33.5/login | grep -o "Welcome to RightScale RightScale Discourse"') do
      it { should return_stdout 'Welcome to RightScale RightScale Discourse'}
    end
  end
  describe "Should return backend if we specify redirect but not /login" do
    describe command('curl --silent -L 33.33.33.5 | grep -o "Welcome to RightScale RightScale Discourse"') do
      it { should return_stdout 'Welcome to RightScale RightScale Discourse'}
    end
  end
end

describe "Verify info setting through haproxy socket" do
  {
     maxconn: "4096",
     maxsock: "8204"
  }.each do |key, val|
    it "The setting #{key} should be set to #{val}" do
      haproxy_info("#{key}").should == "#{val}"
    end
  end
end

describe "Verify settings through haproxy socket" do
  [
    ["all_requests", "FRONTEND",          "status", "OPEN"],
    ["app1",         "disabled-server",   "status", "MAINT"],
    ["app1",         "app1host2",         "status", "no check"],
    ["app1",         "app1host1",         "status", "no check"],
    ["app1",         "BACKEND",           "status", "UP"],
    ["app2",         "disabled-server",   "status", "MAINT"],
    ["app2",         "app2host1",         "status", "no check"],
    ["app2",         "BACKEND",           "status", "UP"],
    ["app3",         "disabled-server",   "status", "MAINT"],
    ["app3",         "app3host1",         "status", "no check"],
    ["app3",         "BACKEND",           "status", "UP"],
    ["default",      "disabled-server",   "status", "MAINT"],
    ["default",      "discourse",         "status", "no check"],
    ["default",      "BACKEND",           "status", "UP"]
  ].each do |stat|
    it "#{stat[0]} #{stat[1]} should have #{stat[2]} of #{stat[3]}" do
      haproxy_stat("#{stat[0]}", "#{stat[1]}", "#{stat[2]}").should == "#{stat[3]}"
    end
  end
end


