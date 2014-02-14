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
  :global => {
    :maxconn => node[:haproxy][:global_max_connections],
    :user => node[:haproxy][:user],
    :group => node[:haproxy][:group],
    :log => "/dev/log syslog info",
    :daemon => true,
    :quiet => true,
    :pidfile => node['haproxy']['pid_file']
  },
  :defaults => {
    :log => 'global',
    :mode => 'http'
  },
  :frontend => {
    :all_requests => {
      :bind => "#{node[:haproxy][:incoming_address]}:#{node[:haproxy][:incoming_port]}",
      :default_backend => node['rs-haproxy']['pools'].last
    }
  }
)

if node['haproxy']['enable_stats_socket']
  haproxy_config[:global][:stats] = "socket #{node['haproxy']['stats_socket_path']}" +
    " user #{node['haproxy']['stats_socket_user']}" +
    " group #{node['haproxy']['stats_socket_group']}"
end

class Chef::Recipe
  include Rightscale::RightscaleTag
end

# Find all application servers in the deployment
app_servers = find_application_servers(node)
app_server_pools = RsHaproxy::Helper.categorize_servers_by_pools(app_servers)

# Set up backend pools in haproxy.cfg
node['rs-haproxy']['pools'].each do |pool_name|
  # Set up load balancer tags for the pool
  rightscale_tag_load_balancer pool_name do
    action :create
  end

  haproxy_config[:backend] ||= {}
  haproxy_config[:backend][pool_name] ||= {
    :mode => 'http',
    :balance => node['haproxy']['balance_algorithm']
  }

  if node['haproxy']['enable_stats_socket']
    haproxy_config[:backend][pool_name][:stats] = "uri #{node['rs-haproxy']['stats_uri']}"
  end

  if node['haproxy']['http_chk']
    haproxy_config[:backend][pool_name][:option] = "httpchk GET #{node['haproxy']['http_chk']}"
    haproxy_config[:backend][pool_name][:'http-check'] = 'disable-on-404'
  end

  haproxy_config[:backend][pool_name][:server] = []
  if node['rs-haproxy']['session_stickiness']
    haproxy_config[:backend][pool_name][:cookie] = 'SERVERID insert indirect nocache'
    # When cookie is enabled the haproxy.cnf should have this dummy server
    # entry for the haproxy to start without any errors
    haproxy_config[:backend][pool_name][:server] << {
      "disabled-server 127.0.0.1:1" => {
        :disabled => true
      }
    }
  end

  if app_server_pools[pool_name].nil?
    next
  else
    app_server_pools[pool_name].each do |server_uuid, server_hash|
      backend_server = "#{server_uuid} #{server_hash['bind_ip_address']}:#{server_hash['bind_port']}"

=begin
      hash = {
        :inter => 300,
        :rise => 2,
        :fall => 3,
        :maxconn => node['haproxy']['member_max_connections']
      }

      if node['rs-haproxy']['session_stickiness']
        hash[:cookie] = server_uuid
      end

      if node['haproxy']['http_chk']
        hash[:check] = true
      end
=end

      haproxy_config[:backend][pool_name][:server] << {backend_server => {}}
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
