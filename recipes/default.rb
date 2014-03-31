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

# Override haproxy cookbook attributes
Chef::Log.info "Overriding haproxy/install_method to 'source'..."
node.override['haproxy']['install_method'] = 'source'

Chef::Log.info "Overriding haproxy/source/version to '1.5-dev22'..."
node.override['haproxy']['source']['version'] = '1.5-dev22'

source_url = 'http://haproxy.1wt.eu/download/1.5/src/devel/haproxy-1.5-dev22.tar.gz'
Chef::Log.info "Overriding haproxy/source/url to '#{source_url}'"
node.override['haproxy']['source']['url'] = source_url
node.override['haproxy']['source']['checksum'] = 'b0978b4802a48ee60ca79c01c0b020c5155ac8248af65d24a248ace91b87ac2e'

Chef::Log.info "Overriding haproxy/source/use_openssl to 'true'"
node.override['haproxy']['source']['use_openssl'] = true

Chef::Log.info "Overriding haproxy/enable_stats_socket to 'true'..."
node.override['haproxy']['enable_stats_socket'] = true

Chef::Log.info "Overriding haproxy/http_chk to '#{node['rs-haproxy']['health_check_uri']}'..."
node.override['haproxy']['httpchk'] = node['rs-haproxy']['health_check_uri']

Chef::Log.info "Overriding haproxy/balance_algorithm to '#{node['rs-haproxy']['balance_algorithm']}'..."
node.override['haproxy']['balance_algorithm'] = node['rs-haproxy']['balance_algorithm']

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
    'balance' => node['haproxy']['balance_algorithm'],
  },
  'frontend' => {
    'all_requests' => {
      # HTTP bind address
      "bind #{node['haproxy']['incoming_address']}:#{node['haproxy']['incoming_port']}" => "",
      'default_backend' => RsHaproxy::Helper.get_config_pool_name(node['rs-haproxy']['pools'].last)
    }
  }
)

# Configure SSL if the SSL certificate and the keys are provided
if node['rs-haproxy']['ssl_cert']
  haproxy_conf_dir = ::File.join(node['haproxy']['source']['prefix'], node['haproxy']['conf_dir'])
  ssl_cert_file = ::File.join(haproxy_conf_dir, 'ssl_cert.pem')

  # Create the HAProxy configuration directory
  directory haproxy_conf_dir

  # Create the pem file in the HAProxy configuration directory
  file ssl_cert_file do
    content node['rs-haproxy']['ssl_cert']
    mode 0600
    action :create
  end

  # HTTPS bind address
  https_bind = "bind #{node['haproxy']['ssl_incoming_address']}:#{node['haproxy']['ssl_incoming_port']}"

  # SSL certificate configuration
  haproxy_config['frontend']['all_requests'][https_bind] = "ssl crt #{ssl_cert_file}"

  # Redirect all HTTP requests to HTTPS
  haproxy_config['frontend']['all_requests']['redirect'] = 'scheme https if !{ ssl_fc }'
end


# Set up haproxy socket
if node['haproxy']['enable_stats_socket']
  haproxy_config['global']['stats'] = "socket #{node['haproxy']['stats_socket_path']}" +
    " user #{node['haproxy']['stats_socket_user']}" +
    " group #{node['haproxy']['stats_socket_group']}"
end

# Set up statistics URI
if node['rs-haproxy']['stats_uri']
  haproxy_config['defaults']['stats'] = {'uri' => node['rs-haproxy']['stats_uri']}

  if node['rs-haproxy']['stats_user'] && node['rs-haproxy']['stats_password']
    haproxy_config['defaults']['stats']['auth'] = "#{node['rs-haproxy']['stats_user']}:#{node['rs-haproxy']['stats_password']}"
  end
end

# Enable HTTP health checks
if node['haproxy']['httpchk']
  haproxy_config['defaults']['option'] = "httpchk GET #{node['haproxy']['httpchk']}"
  haproxy_config['defaults']['http-check'] = 'disable-on-404'
end

# Set up backend pools and ACLs in haproxy.cfg
node['rs-haproxy']['pools'].each do |pool_name|
  # Get pool name accepted by haproxy when naming the backend section
  # in haproxy.cfg. Example: '/app' is changed to '_app'
  pool_name_config = RsHaproxy::Helper.get_config_pool_name(pool_name)

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
    # If pool name contains a '/' then the ACL should match the path in the request URI.
    # e.g., www.example.com/index
    haproxy_config['frontend']['all_requests']['acl'][acl_name] = "path_dom -i #{pool_name}"
  else
    # Else the ACL should match the domain name in the host name of the request URI.
    # e.g., if the request URI is http://test.example.com then the ACL will match 'test.example.com'
    # if the request URI is http://example.com then the ACL will match 'example.com'
    haproxy_config['frontend']['all_requests']['acl'][acl_name] = "hdr_dom(host) -i -m dom #{pool_name}"
  end
  haproxy_config['frontend']['all_requests']['use_backend'] ||= {}
  haproxy_config['frontend']['all_requests']['use_backend'][pool_name_config] = "if #{acl_name}"
end

# Install HAProxy and setup haproxy.cnf
haproxy "set up haproxy.cnf" do
  config haproxy_config
  action :create
end
