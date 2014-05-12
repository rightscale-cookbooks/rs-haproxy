require 'spec_helper'
require 'socket'

config_file = '/usr/local/etc/haproxy/haproxy.cfg'

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
    ["global", "maxconn 4096"],
    ["global", "user haproxy"],
    ["global", "group haproxy"],
    ["global", "stats socket\s+/var/run/haproxy\.sock user haproxy group haproxy"],
    ["defaults", "log\s+global"],
    ["defaults", "mode\s+http"],
    ["defaults", "balance\s+roundrobin"],
    ["defaults", "stats uri /haproxy-status"],
    ["defaults", "http-check disable-on-404"],
    ["defaults", "stats auth statsuser:statspass"],
    ["defaults", "cookie SERVERID insert indirect nocache"]
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

describe port(85) do
  it { should be_listening }
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
     maxsock: "8223"
  }.each do |key, val|
    it "The setting #{key} should be set to #{val}" do
      haproxy_info("#{key}").should == val
    end
  end
end

describe 'load_balancer server tags' do
  hostname = `hostname -s`.chomp
  tag_file = "/vagrant/cache_dir/machine_tag_cache/#{hostname}/tags.json"

  describe file(tag_file) do
    it { should be_file }

    it "should have the load balancer server tags" do
      tags_json = JSON.load(IO.read(tag_file))

      tags_json.should include("load_balancer:active=true")
      tags_json.should include("load_balancer:active_example=true")
      tags_json.should include("load_balancer:active_appserver=true")
      tags_json.should include("load_balancer:active_test_example=true")
    end
  end
end

describe "Verify monitoring file" do
  describe file("/usr/share/collectd/haproxy.db") do
    it { should be_file }
  end
end
