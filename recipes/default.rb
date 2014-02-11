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

log "Overriding haproxy/enable_stats_socket to 'true'..."
node.override['haproxy']['enable_stats_socket'] = true

log "Overriding haproxy/enable_admin to 'false'..."
node.override['haproxy']['enable_admin'] = false

log "Overriding haproxy/enable_default_http to 'false'..."
node.override['haproxy']['enable_default_http'] = false

log "Overriding haproxy/httpchk to '#{node['rs-haproxy']['health_check_uri']}'..."
node.override['haproxy']['httpchk'] = node['rs-haproxy']['health_check_uri']

log "Overriding haproxy/balance_algorithm to '#{node['rs-haproxy']['algorithm']}'..."
node.override['haproxy']['balance_algorithm'] = node['rs-haproxy']['algorithm']

pools = node['rs-haproxy']['pools'].split(%r{, *})

# Set up frontend
haproxy_lb 'all_requests' do
  mode 'http'
  type 'frontend'
  bind '127.0.0.1:85'
  params ({
    acl: "acl_#{pools.last} hdr_dom(host) -i default",
    use_backend: "#{pools.last} if acl_default",
    default_backend: pools.last
  })
end

class Chef::Recipe
  include Rightscale::RightscaleTag
end

# Set up backend pools in haproxy.cfg
servers = []
node['rs-haproxy']['pools'].split(%r{, *}).each do |pool_name|
  options = {
    stats: "uri #{node['rs-haproxy']['stats_uri']}"
  }
  if node['rs-haproxy']['session_stickiness']
    options['cookie'] = 'SERVERID insert indirect nocache'
    # When cookie is enabled the haproxy.cnf should have this dummy server
    # entry for the haproxy to start without any errors
    servers << "disabled-server 127.0.0.1:1 disabled"
  end

  if node['haproxy']['http_chk']
    options['option'] = "httpchk GET #{node['haproxy']['http_chk']}"
    options['http-check'] = 'disable-on-404'
  end

  # Find all application servers in the deployment and attach those with
  # application names same as the pool name
  app_servers = find_application_servers(node, pool_name)
  unless app_servers.empty?
    app_servers.each do |server_uuid, server_hash|
      server_hash['applications'].each do |app_name, app_hash|
        next if app_name != pool_name
        servers << "#{server_uuid} #{app_hash['bind_address']}"
      end
    end
  end

  haproxy_lb pool_name do
    type 'backend'
    mode 'http'
    params options
    servers servers
  end
end

include_recipe 'haproxy::default'

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
