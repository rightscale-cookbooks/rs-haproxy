# frozen_string_literal: true
#
# Cookbook Name:: rs-haproxy
# Recipe:: collectd
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

raise 'This script is only compatible with rs-base::monitoring_collectd' if node['rs-base']['monitoring_type'] != 'collectd'

if node['rightscale'] && node['rightscale']['instance_uuid']
  node.override['collectd']['fqdn'] = node['rightscale']['instance_uuid']
end

# Add the custom haproxy gauges file to collectd config
unless node['collectd']['service']['configuration']['types_d_b'].include?('/usr/share/collectd/haproxy.db')
  node.override['collectd']['service']['configuration']['types_d_b'] = [node['collectd']['service']['configuration']['types_d_b'], '/usr/share/collectd/haproxy.db']
end

# temporary patch until collectd 2.2.4+ works on debian families
node.override['collectd']['service']['configuration']['plugin_dir'] =
  value_for_platform_family(
    'rhel' => '/usr/lib64/collectd',
    'debian' => '/usr/lib/collectd'
  )

include_recipe 'rs-base::monitoring_collectd'

log 'Setting up monitoring for HAProxy...'

# Install socat package which is required by the haproxy collectd script
package 'socat'

# Put the haproxy collectd plugin script into the collectd lib directory
cookbook_file ::File.join(node['collectd']['service']['configuration']['plugin_dir'], 'haproxy') do
  source 'haproxy'
  mode 0755
  cookbook 'rs-haproxy'
  action :create
end

cookbook_file '/usr/share/collectd/haproxy.db' do
  mode 0644
  source 'haproxy.db'
  action :create
end

# Set up haproxy monitoring
collectd_plugin_file 'haproxy' do
  source 'haproxy.conf.erb'
  cookbook 'rs-haproxy'
  variables(collectd_lib: node['collectd']['service']['configuration']['plugin_dir'],
            instance_uuid: node['rightscale']['instance_uuid'],
            haproxy_socket: node['haproxy']['stats_socket_path'])
end

# Set up haproxy process monitoring
collectd_plugin 'processes' do
  options(process: 'haproxy')
end

service 'collectd' do
  action :restart
end
