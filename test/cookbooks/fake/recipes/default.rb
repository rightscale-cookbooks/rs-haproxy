# frozen_string_literal: true
#
# Cookbook Name:: fake
# Recipe:: default
#
# Copyright (C) 2014 RightScale, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe 'curl'
package 'socat'

require 'json'

# Create 3 fake application servers that binds to #{node['ipaddress']}:8080. Have 1 application server
# serve for URL requests 'www.example.com', 1 server to serve URL requests '*/appserver',
# and the other server to serve URL requests 'test.example.com'. All the application servers
# will be serving the same application set up later in the recipe. We can verify HAProxy
# backend configuration by checking if it serves pages from the correct application server
# based on the request URL.
[
  ['01-ABCDEFGH0123', 'test_example', 'test.example.com'],
  ['02-ABCDEFGH0123', 'appserver', '/appserver'],
  ['03-ABCDEFGH0123', 'example', 'example.com']
].each do |server_uuid, app_name, vhost|
  # Fake machine_tags to be set in the VM to simulate 2-tier deployment
  tags = [
    "server:uuid=#{server_uuid}",
    'application:active=true',
    "application:active_#{app_name}=true",
    "application:bind_ip_address_#{app_name}=#{node['ipaddress']}",
    "application:bind_port_#{app_name}=8080",
    "application:vhost_path_#{app_name}=#{vhost}"
  ]

  r = directory "/vagrant/cache_dir/machine_tag_cache/#{server_uuid}" do
    action :nothing
    recursive true
  end
  r.run_action(:create)

  f = file "/vagrant/cache_dir/machine_tag_cache/#{server_uuid}/tags.json" do
    content JSON.pretty_generate(tags)
    action :nothing
  end
  f.run_action(:create)
end

# Add hostname entry in /etc/hosts to resolve to 127.0.0.1.
# This allows 'httpd -t' to not timeout during apache2::default.
cmd = Mixlib::ShellOut.new('hostname')
hostsfile_entry '127.0.0.1' do
  hostname  cmd.run_command.stdout
  action    :append
end

# Set up an application server in the VM to verify HAProxy backend configuration
node.set['rs-application_php']['application_name'] = 'example'
node.set['rs-application_php']['scm']['revision'] = 'unified_php'
node.set['rs-application_php']['scm']['repository'] = 'git://github.com/rightscale/examples.git'
include_recipe 'rs-application_php::default'
