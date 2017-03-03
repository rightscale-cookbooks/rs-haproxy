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

marker 'recipe_start_rightscale' do
  template 'rightscale_audit_entry.erb'
end

raise 'This script is only compatible with rs-base::monitoring_collectd' if node['rs-base']['monitoring_type'] != 'collectd'
# chef_gem 'chef-rewind' do
#  action :install
# end
# require 'chef/rewind'

if node['rightscale'] && node['rightscale']['instance_uuid']
  node.override['collectd']['fqdn'] = node['rightscale']['instance_uuid']
end

# Add the custom haproxy gauges file to collectd config
unless node['collectd']['service']['configuration']['types_d_b'].include?('/usr/share/collectd/haproxy.db')
  node.override['collectd']['service']['configuration']['types_d_b'] = [node['collectd']['service']['configuration']['types_d_b'], '/usr/share/collectd/haproxy.db']
end

include_recipe 'rs-base::monitoring_collectd'

# unwind 'package[collectd]' do
#   only_if { ::File.exist?('/etc/collect.d/collectd.conf') }
# end
# collectd::default recipe attempts to delete collectd plugins that were not
# created during the same runlist as this recipe. Some common plugins are installed
# as a part of base install which runs in a different runlist. This resource
# will safeguard the base plugins from being removed.
# rewind 'ruby_block[delete_old_plugins]' do
#   action :nothing
# end

log 'Setting up monitoring for HAProxy...'

# Install socat package which is required by the haproxy collectd script
apt_package 'socat' do
  options '--assume-no'
  action :install
  only_if { node['platform_family'] == 'debian' }
end

yum_package 'socat' do
  action :install
  only_if { node['platform_family'] == 'rhel' }
end

# Put the haproxy collectd plugin script into the collectd lib directory
cookbook_file "#{node['collectd']['plugin_dir']}/haproxy" do
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
collectd_plugin 'haproxy' do
  #  template 'haproxy.conf.erb'
  #  cookbook 'rs-haproxy'
  options(collectd_lib: node['collectd']['plugin_dir'],
          instance_uuid: node['rightscale']['instance_uuid'],
          haproxy_socket: node['haproxy']['stats_socket_path'])
end

# Set up haproxy process monitoring
collectd_plugin 'processes' do
  options(process: 'haproxy')
end
