require 'spec_helper'
require 'socket'

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
    [ "backend app1",  "cookie SERVERID insert indirect nocache" ],
    [ "backend app2",  "cookie SERVERID insert indirect nocache" ],
    [ "backend app3",  "cookie SERVERID insert indirect nocache" ],
    [ "backend default",  "cookie SERVERID insert indirect nocache" ],
    [ "backend app1",  "server disabled-server 127.0.0.1:1 disabled" ],
    [ "backend app2",  "server disabled-server 127.0.0.1:1 disabled" ],
    [ "backend app3",  "server disabled-server 127.0.0.1:1 disabled" ],
    [ "backend default",  "server disabled-server 127.0.0.1:1 disabled" ]
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

describe "Verify info setting through haproxy socket" do

  #This grabs the info from the socket and stores each line in an array
  let(:haproxy_show_info) do
    begin
      socket_info = []
      UNIXSocket.open('/var/run/haproxy.sock') do |socket|
        socket.puts('show info')
        while line = socket.gets do
          socket_info.push(line)
        end
      end
      return socket_info
    rescue Errno::EPIPE
      retry
    end
  end

  {
     maxconn: "4096",
     maxsock: "8204"
  }.each do |key, val|
    it "The setting #{key} should be set to #{val}" do
      haproxy_info("#{key}").should == val
    end
  end
end

describe 'load_balancer server tags' do
  let(:host_name) { Socket.gethostname.split('.').first }
  let(:tags) { MachineTag::Set.new(JSON.parse(IO.read("/vagrant/cache_dir/machine_tag_cache/#{host_name}/tags.json"))) }

  it "should have a UUID of 12345UUID" do
    tags['server:uuid'].first.value.should eq ('12345UUID')
  end

  it "should be an active load balancer" do
    tags['load_balancer:active'].first.value.should be_true
  end

  it "should include a public IP address of 33.33.33.5" do
    tags['server:public_ip_0'].first.value.should eq ('33.33.33.5')
  end

  it "should be be active for app1" do
    tags['load_balancer:active_app1'].first.value.should be_true
  end

  it "should be be active for app2" do
    tags['load_balancer:active_app2'].first.value.should be_true
  end

  it "should be be active for app3" do
    tags['load_balancer:active_app3'].first.value.should be_true
  end

  it "should be true for active_default" do
    tags['load_balancer:active_default'].first.value.should be_true
  end
end

describe "Verify monitoring file" do
  describe file("/usr/share/collectd/haproxy.db") do
    it { should be_file }
  end
end
