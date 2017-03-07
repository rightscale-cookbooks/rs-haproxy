# frozen_string_literal: true
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

# If installing from source, update attributes accordingly.
if node['rs-haproxy']['install_method'] == 'source'
  Chef::Log.info "Overriding haproxy/install_method to 'source'..."
  node.override['haproxy']['install_method'] = node['rs-haproxy']['install_method']

  # If rs-haproxy/source/version attribute not set, determine version from source filename.
  if node['rs-haproxy']['source']['version']
    source_version = node['rs-haproxy']['source']['version']
  else
    source_version = RsHaproxy::Helper.get_haproxy_version(node['rs-haproxy']['source']['url'])
    unless source_version
      raise 'Unable to determine version from source filename. Please set version in rs-haproxy/source/version attribute.'
    end
  end

  Chef::Log.info "Overriding haproxy/source/version to #{source_version}"
  node.override['haproxy']['source']['version'] = source_version

  Chef::Log.info "Overriding haproxy/source/url to #{node['rs-haproxy']['source']['url']}"
  node.override['haproxy']['source']['url'] = node['rs-haproxy']['source']['url']
  node.override['haproxy']['source']['checksum'] = node['rs-haproxy']['source']['checksum']
end

# Override haproxy cookbook attributes
Chef::Log.info "Overriding haproxy/source/use_openssl to 'true'"
node.override['haproxy']['source']['use_openssl'] = true

Chef::Log.info "Overriding haproxy/incoming_port to #{node['rs-haproxy']['incoming_port']}"
node.override['haproxy']['incoming_port'] = node['rs-haproxy']['incoming_port']

Chef::Log.info "Overriding haproxy/enable_stats_socket to 'true'..."
node.override['haproxy']['enable_stats_socket'] = true

Chef::Log.info "Overriding haproxy/httpchk to '#{node['rs-haproxy']['health_check_uri']}'..."
node.override['haproxy']['httpchk'] = node['rs-haproxy']['health_check_uri']

Chef::Log.info "Overriding haproxy/balance_algorithm to '#{node['rs-haproxy']['balance_algorithm']}'..."
node.override['haproxy']['balance_algorithm'] = node['rs-haproxy']['balance_algorithm']

# Setting haproxy config in attributes
node.default['haproxy']['config']['global'] = {
  'user' => node['haproxy']['user'],
  'group' => node['haproxy']['group'],
  'pidfile' => node['haproxy']['pid_file'],
  'log' => '/dev/log syslog info',
  'daemon' => true,
  'quiet' => true,
}

node.default['haproxy']['config']['defaults']['log'] = 'global'
node.default['haproxy']['config']['defaults']['mode'] = 'http'
node.default['haproxy']['config']['defaults']['balance'] = 'roundrobin'

Chef::Log.info node['haproxy']['config']['defaults']['option']
option_array = %w(httplog dontlognull redispatch)
node['haproxy']['config']['defaults']['option'].each { |i| option_array << i } unless node['haproxy']['config']['defaults']['option'].nil?
node.default['haproxy']['config']['defaults']['option'] = option_array

Chef::Log.info 'creating base connection'
node.default['haproxy']['config']['frontend']['all_requests']['bind'] = "#{node['haproxy']['incoming_address']}:#{node['haproxy']['incoming_port']}"

# Configure SSL if the SSL certificate and the keys are provided
if node['rs-haproxy']['ssl_cert']
  Chef::Log.info "Overriding haproxy/ssl_incoming_port to #{node['rs-haproxy']['ssl_incoming_port']}"
  node.override['haproxy']['ssl_incoming_port'] = node['rs-haproxy']['ssl_incoming_port']

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
  node.default['haproxy']['config']['frontend']['all_requests'][https_bind] = "ssl crt #{ssl_cert_file} no-sslv3"

  # Redirect all HTTP requests to HTTPS
  node.default['haproxy']['config']['frontend']['all_requests']['redirect'] = 'scheme https if !{ ssl_fc }'
end

# Set up haproxy socket
if node['haproxy']['enable_stats_socket']
  node.default['haproxy']['config']['global']['stats'] = "socket #{node['haproxy']['stats_socket_path']}" \
                                                         " user #{node['haproxy']['stats_socket']['user']}" \
                                                         " group #{node['haproxy']['stats_socket']['group']}"
end

# Set up statistics URI
if node['rs-haproxy']['stats_uri']
  node.default['haproxy']['config']['defaults']['stats'] = { 'uri' => node['rs-haproxy']['stats_uri'] }

  if node['rs-haproxy']['stats_user'] && node['rs-haproxy']['stats_password']
    node.default['haproxy']['config']['defaults']['stats']['auth'] = "#{node['rs-haproxy']['stats_user']}:#{node['rs-haproxy']['stats_password']}"
  end
end

# Enable HTTP health checks
if node['haproxy']['httpchk']
  node.default['haproxy']['config']['defaults']['option'].push("httpchk GET #{node['haproxy']['httpchk']}")
  node.default['haproxy']['config']['defaults']['http-check'] = 'disable-on-404'
end

if node['rs-haproxy']['session_stickiness']
  node.default['haproxy']['config']['defaults']['cookie'] = 'SERVERID insert indirect nocache'
end

Chef::Log.info node['haproxy']['config']
haproxy_config = Mash.new(
  'global' => {
    'maxconn' => (node['rs-haproxy']['maxconn'].to_i + 10),
  }
)

# Install HAProxy and setup haproxy.cnf
haproxy 'set up haproxy.cnf' do
  config haproxy_config
  action :create
  notifies :restart, 'service[haproxy]', :delayed
end

service 'haproxy' do
  action :nothing
end

# Confirm that rsyslog is installed.
include_recipe 'rs-base::rsyslog'

# Configure rsyslog to handle logs from haproxy.
cookbook_file '/etc/rsyslog.d/10-haproxy.conf' do
  source 'rsyslog-10-haproxy.conf'
  backup 0
  mode 0644
  owner 'root'
  group 'root'
  action :create
  notifies :restart, 'service[rsyslog]'
end

cookbook_file '/etc/logrotate.d/haproxy' do
  source 'logrotate-haproxy.conf'
  backup 0
  mode 0644
  owner 'root'
  group 'root'
  action :create
end
