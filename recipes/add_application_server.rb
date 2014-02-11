#
# Cookbook Name:: rs-haproxy
# Recipe:: add_application_server
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

servers = []
options = {
  stats: "uri #{node['rs-haproxy']['stats_uri']}"
}

if node['rs-haproxy']['session_stickiness']
  options['cookie'] = 'SERVERID insert indirect nocache'
  # When cookie is enabled the haproxy.cnf should have this dummy server
  # entry for the haproxy to start without any errors
  servers << "disabled-server 127.0.0.1:1 disabled"
end

servers << "#{node['remote_recipe']['server_uuid']} #{node['remote_recipe']['bind_ip']}:#{node['remote_recipe']['bind_port']}"

haproxy_lb node['remote_recipe']['pool'] do
  type 'backend'
  mode 'http'
  params options
  servers servers
end

include_recipe 'haproxy::default'
