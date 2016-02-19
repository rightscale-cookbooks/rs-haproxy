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

# If 'find_application_servers' returns empty, there may be an issue with retrieving machine tags.
# Instead of continuing and removing all backend servers from haproxy config, we will stop here.
# If there truly are no application servers, the frontend website will show the same content as if
# each application server entry was removed from haproxy config.  If there is an issue with
# retrieving machine tags, the current config with existing application servers will continue
# to function as expected.
if app_servers.empty?
  Chef::Log.info 'No application servers found. No changes will be made.'
  return
end

# Group application servers by pools.
app_server_pools = group_servers_by_application_name(app_servers)

# If this recipe is called via the remote_recipe resource, add or remove the
# application server information sent through the resource with the
# application server pools hash. This is to ensure the application server
# which made the remote recipe call is updated in the list of application servers
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
      'bind_port' => node['remote_recipe']['application_bind_port'],
      'vhost_path' => node['remote_recipe']['vhost_path']
    }
  when 'detach'
    # Remove application server from the respective pool
    if app_server_pools[remote_server_pool]
      app_server_pools[remote_server_pool].delete(remote_server_uuid)
    end
  end

  # Set variable to application_action to keep within scope of this recipe after remote_recipe is reset below.
  application_action = node['remote_recipe']['application_action']

  # Reset the 'remote_recipe' hash in the node to nil to ensure subsequent recipe runs
  # don't use the existing values from this hash.
  node.default['remote_recipe'] = nil
end

# Initialize frontend section which will be generated in the haproxy.cfg
node.default['haproxy']['config']['frontend'] = {}
node.default['haproxy']['config']['frontend']['all_requests'] ||= {}
node.default['haproxy']['config']['frontend']['all_requests']['default_backend'] = node['rs-haproxy']['pools'].last
node.default['haproxy']['config']['frontend']['all_requests']['bind'] = "#{node['haproxy']['incoming_address']}:#{node['haproxy']['incoming_port']}"
node.default['haproxy']['config']['frontend']['all_requests']['maxconn'] = node['rs-haproxy']['maxconn']
# HAproxy Redirect all HTTP traffic to HTTPS when SSL is handled by haproxy.
# https://cbonte.github.io/haproxy-dconv/configuration-1.5.html#check-ssl
node.default['haproxy']['config']['redirect']['scheme'] = 'https if !{ ssl_fc }' if node['rs-haproxy']['force_ssl_redirect'] == true


# Initialize backend section which will be generated in the haproxy.cfg
node.default['haproxy']['config']['backend'] = {}

# Iterate through each application server pool served by the HAProxy server and set up the
# ACLs in the frontend section and the corresponding backed sections
node['rs-haproxy']['pools'].each do |pool_name|
  backend_servers_list = []

  if node['rs-haproxy']['session_stickiness']
    # When cookie is enabled the haproxy.cnf should have this dummy server
    # entry for the haproxy to start without any errors
    backend_servers_list << {'disabled-server 127.0.0.1:1' => {'disabled' => true}}
  end

  # If there exists application servers with application name same as pool name add those
  # servers to the corresponding backend section in the haproxy.cfg. Also, set up the ACLs
  # based on the vhost_path information in the application server.
  unless app_server_pools[pool_name].nil?
    acl_setting = ''
    app_server_pools[pool_name].each do |server_uuid, server_hash|
      if server_hash['vhost_path'].include?('/')
        # If vhost_path contains a '/' then the ACL should match the path in the request URI.
        # e.g., if the request URI is www.example.com/index then the ACL will match '/index'
        acl_setting = "path_dom -i #{server_hash['vhost_path']}"
      else
        # Else the ACL should match the domain name of the request URI.
        # e.g., if the request URI is http://test.example.com then the ACL will
        # match 'test.example.com' and if the request URI is http://example.com
        # then the ACL will match 'example.com'
        acl_setting = "hdr_dom(host) -i -m dom #{server_hash['vhost_path']}"
      end

      backend_server = "#{server_uuid} #{server_hash['bind_ip_address']}:#{server_hash['bind_port']}"
      backend_server_hash = {
        'inter' => node['rs-haproxy']['backend']['inter'],
        'rise' => node['rs-haproxy']['backend']['rise'],
        'fall' => node['rs-haproxy']['backend']['fall'],
        'maxconn' => node['haproxy']['member_max_connections']
      }

      if node['rs-haproxy']['health_check_uri']
        node.override['haproxy']['httpchk'] = node['rs-haproxy']['health_check_uri']
        backend_server_hash['check'] = true
      end

      # Configure cookie for backend server
      if node['rs-haproxy']['session_stickiness']
        backend_server_hash['cookie'] = backend_server.split(' ').first
      end

      backend_servers_list << {backend_server => backend_server_hash}

      # The machine tag "application:firewall_script_#{pool_name}" is placed on an application
      # server and has the value of a script or recipe that should run on the application server
      # after the load balancer adds it to its config. If the machine tag is set on the application server,
      # send a request to run it.
      remote_script_tag = app_servers[server_uuid]['tags']['application', "firewall_script_#{pool_name}"].first
      if remote_script_tag
        json_file = '/tmp/recipe_attributes.json'
        # Determine if remote_script is a RightScript or a Chef recipe
        if remote_script_tag.value =~ /^[\w-]+::[\w-]+$/
          # Value is a remote recipe

          # Create JSON file with expected attributes to pass to rs_run_recipe
          file json_file do
            owner 'root'
            group 'root'
            mode '0700'
            content ::JSON.pretty_generate({
              # Hash entries with a 'nil' value will be removed by the 'reject' method.
              'remote_recipe' => {
                'lb_private_ip' => ( node['cloud']['private_ips'].first || nil ),
                'lb_public_ip' => ( node['cloud']['public_ips'].first || nil ),
                'pool_name' => pool_name,
                'action' => ( application_action == 'detach' ? 'deny' : 'allow' ),
              }.reject { |key, value| value.nil? }
            })
            action :create
          end

          command = 'rs_run_recipe'
          command << " --recipient_tags 'server:uuid=#{server_uuid}'"
          command << " --name '#{remote_script_tag.value}'"
          command << " --policy '#{remote_script_tag.value}'"
          command << " --json '#{json_file}'"

        else
          # Value is a remote RightScript

          command = 'rs_run_right_script'
          command << " --recipient_tags 'server:uuid=#{server_uuid}'"
          command << " --name '#{remote_script_tag.value}'"
          # Common inputs for Windows App servers firewall RightScript
          command << " --parameter 'LB_ALLOW_DENY_PRIVATE_IP=text:#{node['cloud']['private_ips'].first}'" if node['cloud']['private_ips']
          command << " --parameter 'LB_ALLOW_DENY_PUBLIC_IP=text:#{node['cloud']['public_ips'].first}'" if node['cloud']['public_ips']
          command << " --parameter 'LB_ALLOW_DENY_POOL_NAME=text:#{pool_name}'"
          case application_action
          when 'attach'
            command << " --parameter 'LB_ALLOW_DENY_ACTION=text:allow'"
          when 'detach'
            command << " --parameter 'LB_ALLOW_DENY_ACTION=text:deny'"
          end
        end
        Chef::Log.info "Running remote script on #{server_uuid}: #{command}"

        execute 'Run postconnect script on application server' do
          command command
        end

        file json_file do
          action :delete
        end
      end

    end

    # Set up ACLs based on the vhost_path information from the application servers
    acl_name = "acl_#{pool_name}"
    node.default['haproxy']['config']['frontend']['all_requests']['acl'] ||= {}
    node.default['haproxy']['config']['frontend']['all_requests']['acl'][acl_name] = acl_setting
    node.default['haproxy']['config']['frontend']['all_requests']['use_backend'] ||= {}
    node.default['haproxy']['config']['frontend']['all_requests']['use_backend'][pool_name] = "if #{acl_name}"
  end

  # Set up backend section for each application server pool served by HAProxy
  node.default['haproxy']['config']['backend'][pool_name] = {}
  node.default['haproxy']['config']['backend'][pool_name]['server'] ||= []
  node.default['haproxy']['config']['backend'][pool_name]['server'] = backend_servers_list
end

include_recipe 'rs-haproxy::default'
