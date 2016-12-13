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
describe 'Verify settings in haproxy.cfg file' do
  [
    ['global', 'maxconn 4106'],
    ['global', 'user haproxy'],
    ['global', 'group haproxy'],
    ['global', 'stats socket +/var/run/haproxy.sock user haproxy group haproxy'],
    ['defaults', 'log +global'],
    ['defaults', 'mode +http'],
    ['defaults', 'balance +roundrobin'],
    ['defaults', 'stats uri /haproxy-status'],
    ['defaults', 'http-check disable-on-404'],
    ['defaults', 'stats auth statsuser:statspass'],
    ['defaults', 'cookie SERVERID insert indirect nocache'],
    ['defaults', 'timeout client 10s'],
    ['defaults', 'timeout server 10s'],
    ['defaults', 'timeout connect 10s']
  ].each do |pair|
    it "#{pair.first} should contain #{pair.last}" do
      expect(find_haproxy_setting(config_file, pair.first, pair.last)).to eq(true)
    end
  end
end

describe service('haproxy') do
  it { should be_enabled }
  it { should be_running }
end

describe port(85) do
  it { should be_listening }
end

describe 'The proper user and group should exist on the server' do
  describe user('haproxy') do
    it { should exist }
  end

  describe user('haproxy') do
    it { should belong_to_group 'haproxy' }
  end
end

describe 'Verify info setting through haproxy socket' do
  # This grabs the info from the socket and stores each line in an array
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
    maxconn: '4106',
    maxsock: '8243'
  }.each do |key, val|
    it "The setting #{key} should be set to #{val}" do
      expect(haproxy_info(key.to_s)).to eq(val)
    end
  end
end

describe 'load_balancer server tags' do
  hostname = `hostname -s`.chomp
  tag_file = "/vagrant/cache_dir/machine_tag_cache/#{hostname}/tags.json"

  describe file(tag_file) do
    it { should be_file }

    it 'should have the load balancer server tags' do
      tags_json = JSON.load(IO.read(tag_file))

      expect(tags_json).to include('load_balancer:active=true')
      expect(tags_json).to include('load_balancer:active_example=true')
      expect(tags_json).to include('load_balancer:active_appserver=true')
      expect(tags_json).to include('load_balancer:active_test_example=true')
    end
  end
end

describe 'Verify monitoring file' do
  describe file('/usr/share/collectd/haproxy.db') do
    it { should be_file }
  end
end
