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

marker "recipe_start_rightscale" do
  template "rightscale_audit_entry.erb"
end

node.override['collectd']['types_db'] = node['collectd']['types_db'] + ['/usr/share/collectd/haproxy.db']

include_recipe 'collectd::default'

log "Setting up monitoring for HAProxy..."

# Put the haproxy.rb collectd plugin script into the collectd lib directory
template "#{node['collectd']['plugin_dir']}/haproxy" do
  source 'haproxy.rb.erb'
  owner node['haproxy']['user']
  group node['haproxy']['group']
  mode '0755'
  cookbook 'rs-haproxy'
  variables(
    :socket => node['haproxy']['stats_socket_path']
  )
end

cookbook_file '/usr/share/collectd/haproxy.db' do
  mode 0644
  source 'haproxy.db'
  action :create_if_missing
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
