#
# Cookbook Name:: rs-haproxy
# Recipe:: frontend
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

include_recipe 'rightscale_tag::default'

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
unless node['remote_recipe'].nil? || node['remote_recipe'].empty?
  raise "Load balancer pool name is missing in the remote recipe call!" if node['remote_recipe']['pool_name'].nil?
  remote_server_pool = node['remote_recipe']['pool_name']

  raise "Instance UUID of the remote server is missing!" if node['remote_recipe']['application_server_id'].nil?
  remote_server_uuid = node['remote_recipe']['application_server_id']

  case node['remote_recipe']['application_action']
  when 'attach'
    # Add the application server information to the respective pool
    app_server_pools[remote_server_pool] ||= {}
    app_server_pools[remote_server_pool][remote_server_uuid] = {
      'bind_ip_address' => node['remote_recipe']['application_bind_ip'],
      'bind_port' => node['remote_recipe']['application_bind_port']
    }
  when 'detach'
    # Remove application server from the respective pool
    if app_server_pools[remote_server_pool]
      app_server_pools[remote_server_pool].delete(remote_server_uuid)
    end
  end

  # Reset the 'remote_recipe' hash in the node to nil to ensure subsequent recipe runs
  # don't use the existing values from this hash.
  node.set['remote_recipe'] = nil
end

# Set up backend pools in haproxy.cfg
node.set['haproxy']['config']['backend'] = {}
node['rs-haproxy']['pools'].each do |pool_name|
  # Get pool name accepted by haproxy when naming the backend section
  # in haproxy.cfg. Example: '/app' is changed to '_app'
  pool_name_config = RsHaproxy::Helper.get_config_pool_name(pool_name)
  node.set['haproxy']['config']['backend'][pool_name_config] = {}

  # Add servers to the corresponding backend section
  unless app_server_pools[pool_name].nil?
    backend_servers_list ||= []

    app_server_pools[pool_name].each do |server_uuid, server_hash|
      backend_server = "#{server_uuid} #{server_hash['bind_ip_address']}:#{server_hash['bind_port']}"

      backend_server_hash = {
        'inter' => 300,
        'rise' => 2,
        'fall' => 3,
        'maxconn' => node['haproxy']['member_max_connections']
      }

      if node['haproxy']['http_chk']
        backend_server_hash['check'] = true
      end

      # Configure cookie for backend server
      if node['rs-haproxy']['session_stickiness']
        backend_server_hash['cookie'] = backend_server.split(' ').first
      end

      backend_servers_list << {backend_server => backend_server_hash}
    end

    node.set['haproxy']['config']['backend'][pool_name_config]['server'] ||= []
    node.set['haproxy']['config']['backend'][pool_name_config]['server'] = backend_servers_list
  end
end

include_recipe 'rs-haproxy::default'
