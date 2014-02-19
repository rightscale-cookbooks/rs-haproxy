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

# Bind HAProxy to the public IP of the server
Chef::Log.info "Overriding haproxy/incoming_address to '#{node['cloud']['public_ips'].first}'"
node.override['haproxy']['incoming_address'] = node['cloud']['public_ips'].first

Chef::Log.info "Overriding haproxy/enable_stats_socket to 'true'..."
node.override['haproxy']['enable_stats_socket'] = true

Chef::Log.info "Overriding haproxy/http_chk to '#{node['rs-haproxy']['health_check_uri']}'..."
node.override['haproxy']['httpchk'] = node['rs-haproxy']['health_check_uri']

Chef::Log.info "Overriding haproxy/balance_algorithm to '#{node['rs-haproxy']['algorithm']}'..."
node.override['haproxy']['balance_algorithm'] = node['rs-haproxy']['algorithm']

haproxy_config = Mash.new(
  'global' => RsHaproxy::Config.global(node),
  'defaults' => RsHaproxy::Config.defaults(node)
)

haproxy_config['frontend'] ||= {}
haproxy_config['frontend'].merge!(RsHaproxy::Config.frontend(node, 'all_requests'))

class Chef::Recipe
  include Rightscale::RightscaleTag
end

# Find all application servers in the deployment
app_servers = find_application_servers(node)
app_server_pools = RsHaproxy::Helper.categorize_servers_by_pools(app_servers)

# If this recipe is called via the remote_recipe resource, merge the
# application server information sent through the resource with the
# application server pools hash. This is to ensure the application server
# which made the remote recipe call is added to the list of application servers
# in the deployment.
if node['remote_recipe'] && node['cloud']['provider'] != 'vagrant'
  remote_server_pool = node['remote_recipe']['pool_name']
  remote_server_uuid = node['remote_recipe']['server_id']

  if node['remote_recipe']['action'] == 'attach'
    # Add the application server information to the respective pool
    app_server_pools[remote_server_pool] ||= {}
    app_server_pools[remote_server_pool][remote_server_uuid] = {
      'bind_ip_address' => node['remote_recipe']['bind_ip_address'],
      'bind_port' => node['remote_recipe']['bind_ip_port']
    }
  elsif node['remote_recipe']['action'] == 'detach'
    # Remove application server from the respective pool
    if app_server_pools[remote_server_pool]
      app_server_pools[remote_server_pool].delete!(remote_server_uuid)
    end
  else
    raise "Unsupported action '#{node['remote_recipe']['action']}' passed via remote_recipe!"
  end
end

# Set up backend pools in haproxy.cfg
node['rs-haproxy']['pools'].each do |pool_name|
  # Get friendly pool name accepted by haproxy when naming the backend section
  # in haproxy.cfg. Example: '/app' is changed to '_app'
  pool_name_friendly = RsHaproxy::Helper.get_friendly_pool_name(pool_name)

  # Set up load balancer tags for the pool
  rightscale_tag_load_balancer pool_name do
    action :create
  end

  # Setup backend section
  haproxy_config['backend'] ||= {}
  haproxy_config['backend'].merge!(RsHaproxy::Config.backend_pool(node, pool_name_friendly))

  # Setup ACLs
  haproxy_config['frontend']['all_requests']['acl'] ||= {}
  haproxy_config['frontend']['all_requests']['use_backend'] ||= {}
  acl_config = RsHaproxy::Config.setup_acls('all_requests', pool_name)
  haproxy_config['frontend']['all_requests']['acl'].merge!(acl_config['acl'])
  haproxy_config['frontend']['all_requests']['use_backend'].merge!(acl_config['use_backend'])

  # Add servers to the corresponding backend section
  unless app_server_pools[pool_name].nil?
    app_server_pools[pool_name].each do |server_uuid, server_hash|
      backend_server = "#{server_uuid} #{server_hash['bind_ip_address']}:#{server_hash['bind_port']}"

      haproxy_config['backend'][pool_name_friendly]['server'] ||= []
      haproxy_config['backend'][pool_name_friendly]['server'] << RsHaproxy::Config.backend_server(node, backend_server)
    end
  end
end

# Install HAProxy and setup haproxy.cnf
haproxy "set up haproxy.cnf" do
  config haproxy_config
  action :create
end

# Set up monitoring for HAProxy
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

collectd_plugin 'haproxy' do
  template 'haproxy.conf.erb'
  cookbook 'rs-haproxy'
  options({
    collectd_lib: node['collectd']['plugin_dir'],
    instance_uuid: node['rightscale']['instance_uuid'],
    haproxy_socket: node['haproxy']['stats_socket_path']
  })
end

ruby_block "add HAProxy gauges to collectd types.db" do
  block do
    file = Chef::Util::FileEdit.new('/usr/share/collectd/types.db')
    file.insert_line_if_no_match(
      /haproxy_sessions/,
      "haproxy_sessions\tcurrent_queued:GAUGE:0:65535, current_session:GAUGE:0:65535"
    )
    file.write_file
    file.insert_line_if_no_match(
      /haproxy_traffic/,
      "haproxy_traffic\t\tcumulative_requests:COUNTER:0:200000000, response_errors:COUNTER:0:200000000, health_check_errors:COUNTER:0:200000000"
    )
    file.write_file
    file.insert_line_if_no_match(/haproxy_status/, "haproxy_status\t\tstatus:GAUGE:-255:255")
    file.write_file
  end
end
