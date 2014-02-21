#
# Cookbook Name:: rs-haproxy
# Recipe:: default
#
# Copyright (C) 2014 RightScale, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

marker "recipe_start_rightscale" do
  template "rightscale_audit_entry.erb"
end

Chef::Log.info "Overriding haproxy/enable_stats_socket to 'true'..."
node.override['haproxy']['enable_stats_socket'] = true

Chef::Log.info "Overriding haproxy/http_chk to '#{node['rs-haproxy']['health_check_uri']}'..."
node.override['haproxy']['httpchk'] = node['rs-haproxy']['health_check_uri']

Chef::Log.info "Overriding haproxy/balance_algorithm to '#{node['rs-haproxy']['algorithm']}'..."
node.override['haproxy']['balance_algorithm'] = node['rs-haproxy']['algorithm']

# Build the haproxy configuration sections into a hash
haproxy_config = Mash.new(
  'global' => {
    'maxconn' => node['haproxy']['global_max_connections'],
    'user' => node['haproxy']['user'],
    'group' => node['haproxy']['group'],
    'log' => "/dev/log syslog info",
    'daemon' => true,
    'quiet' => true,
    'pidfile' => node['haproxy']['pid_file']
  },
  'defaults' => {
    'log' => 'global',
    'mode' => 'http',
    'option' => ['httplog', 'dontlognull', 'redispatch'],
    'mode' => 'http',
    'balance' => node['haproxy']['balance_algorithm'],
  },
  'frontend' => {
    'all_requests' => {
      'bind' => "#{node['haproxy']['incoming_address']}:#{node['haproxy']['incoming_port']}",
      'default_backend' => node['rs-haproxy']['pools'].last
    }
  }
)

# Set up haproxy socket
if node['haproxy']['enable_stats_socket']
  haproxy_config['global']['stats'] = "socket #{node['haproxy']['stats_socket_path']}" +
    " user #{node['haproxy']['stats_socket_user']}" +
    " group #{node['haproxy']['stats_socket_group']}"
end

# Set up statistics URI
if node['rs-haproxy']['stats_uri']
  haproxy_config['defaults']['stats'] = {
    'uri' => node['rs-haproxy']['stats_uri']
  }
  if node['rs-haproxy']['stats_user'] && node['rs-haproxy']['stats_password']
    haproxy_config['defaults']['stats']['auth'] = "#{node['rs-haproxy']['stats_user']}:#{node['rs-haproxy']['stats_password']}"
  end
end

if node['haproxy']['httpchk']
  haproxy_config['defaults']['option'] = "httpchk GET #{node['haproxy']['httpchk']}"
  haproxy_config['defaults']['http-check'] = 'disable-on-404'
end

class Chef::Recipe
  include Rightscale::RightscaleTag
end

# Find all application servers in the deployment
app_servers = find_application_servers(node)
app_server_pools = group_servers_by_application_name(app_servers)

# If this recipe is called via the remote_recipe resource, merge the
# application server information sent through the resource with the
# application server pools hash. This is to ensure the application server
# which made the remote recipe call is added to the list of application servers
# in the deployment.
unless node['cloud']['provider'] == 'vagrant'
  remote_server_pool = node['rs-haproxy']['application_name']
  remote_server_uuid = node['rs-haproxy']['application_server_id']

  if node['rs-haproxy']['action'] == 'attach'
    # Add the application server information to the respective pool
    app_server_pools[remote_server_pool] ||= {}
    app_server_pools[remote_server_pool][remote_server_uuid] = {
      'bind_ip_address' => node['rs-haproxy']['application_bind_ip'],
      'bind_port' => node['rs-haproxy']['application_bind_port']
    }
  elsif node['rs-haproxy']['action'] == 'detach'
    # Remove application server from the respective pool
    if app_server_pools[remote_server_pool]
      app_server_pools[remote_server_pool].delete(remote_server_uuid)
    end
  else
    raise "Unsupported action '#{node['rs-haproxy']['action']}' passed via remote_recipe!"
  end
end

# Set up backend pools in haproxy.cfg
node['rs-haproxy']['pools'].each do |pool_name|
  # Get pool name accepted by haproxy when naming the backend section
  # in haproxy.cfg. Example: '/app' is changed to '_app'
  pool_name_config = RsHaproxy::Helper.get_config_pool_name(pool_name)

  # Set up load balancer tags for the pool
  rightscale_tag_load_balancer pool_name do
    action :create
  end

  # Setup backend section
  haproxy_config['backend'] ||= {}
  haproxy_config['backend'][pool_name_config] ||= {}

  # Configure session stickiness using cookies
  if node['rs-haproxy']['session_stickiness']
    haproxy_config['backend'][pool_name_config]['cookie'] = 'SERVERID insert indirect nocache'
    # When cookie is enabled the haproxy.cnf should have this dummy server
    # entry for the haproxy to start without any errors
    haproxy_config['backend'][pool_name_config]['server'] ||= []
    haproxy_config['backend'][pool_name_config]['server'] << {
      'disabled-server 127.0.0.1:1' => {'disabled' => true}
    }
  end

  # Setup ACLs
  haproxy_config['frontend']['all_requests']['acl'] ||= {}
  acl_name = "acl_#{pool_name_config}"
  if pool_name.include?('/')
    haproxy_config['frontend']['all_requests']['acl'][acl_name] = "path_dom -i #{pool_name}"
  else
    haproxy_config['frontend']['all_requests']['acl'][acl_name] = "hdr(dom) -i #{pool_name}"
  end
  haproxy_config['frontend']['all_requests']['use_backend'] ||= {}
  haproxy_config['frontend']['all_requests']['use_backend'][pool_name_config] = "if #{acl_name}"

  # Add servers to the corresponding backend section
  unless app_server_pools[pool_name].nil?
    app_server_pools[pool_name].each do |server_uuid, server_hash|
      backend_server = "#{server_uuid} #{server_hash['bind_ip_address']}:#{server_hash['bind_port']}"

      server_hash = {
        'inter' => 300,
        'rise' => 2,
        'fall' => 3,
        'maxconn' => node['haproxy']['member_max_connections']
      }

      if node['haproxy']['http_chk']
        server_hash['check'] = true
      end

      # Configure cookie for backend server
      if node['rs-haproxy']['session_stickiness']
        server_hash['cookie'] = backend_server.split(' ').first
      end

      haproxy_config['backend'][pool_name_config]['server'] ||= []
      haproxy_config['backend'][pool_name_config]['server'] << {
        backend_server => server_hash
      }
    end
  end
end

# Install HAProxy and setup haproxy.cnf
haproxy "set up haproxy.cnf" do
  config haproxy_config
  action :create
end

# Set up monitoring for HAProxy
node.override['collectd']['types_db'] = node['collectd']['types_db'] + ['/usr/share/collectd/haproxy.db']
include_recipe 'collectd::default'

# Put the haproxy.rb collectd plugin script into the collectd lib directory
template "#{node['collectd']['plugin_dir']}/haproxy.rb" do
  source 'haproxy.rb.erb'
  owner node['haproxy']['user']
  group node['haproxy']['group']
  mode '0755'
  cookbook 'rs-haproxy'
  variables(
    :socket => node['haproxy']['stats_socket_path']
  )
end

file '/usr/share/collectd/haproxy.db' do
  mode 0644
  content [
    "haproxy_sessions\tcurrent_queued:GAUGE:0:65535, current_session:GAUGE:0:65535",
    "haproxy_traffic\t\tcumulative_requests:COUNTER:0:200000000, response_errors:COUNTER:0:200000000, health_check_errors:COUNTER:0:200000000",
    "haproxy_status\t\tstatus:GAUGE:-255:255"
  ].join("\n")
  action :create
end

collectd_plugin 'haproxy' do
  template 'haproxy.conf.erb'
  cookbook 'rs-haproxy'
  options({
    :collectd_lib => node['collectd']['plugin_dir'],
    :instance_uuid => node['rightscale']['instance_uuid'],
    :haproxy_socket => node['haproxy']['stats_socket_path']
  })
end
