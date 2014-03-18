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

app1_host1_dir = "/vagrant/cache_dir/machine_tag_cache/app1-host1"

# Tags for server1 on the app1 pool
app1_host1_tags = [
  "server:uuid=app1host1",
  "application:active=true",
  "application:active_app1=true",
  "application:bind_ip_address_app1=10.1.55.22",
  "application:bind_port_app1=80",
  "application:vhost_path_app1=alpha.com"
]

a1h1_dir = directory app1_host1_dir do
  recursive true
  action :nothing
end.run_action(:create)

a1h1_file = file "#{app1_host1_dir}/tags.json" do
  content JSON.pretty_generate(app1_host1_tags)
  action :nothing
end.run_action(:create)

app1_host2_dir = "/vagrant/cache_dir/machine_tag_cache/app1-host2"

# Tags for server2 on the app1 pool
app1_host2_tags = [
  "server:uuid=app1host2",
  "application:active=true",
  "application:active_app1=true",
  "application:bind_ip_address_app1=10.1.55.33",
  "application:bind_port_app1=80",
  "application:vhost_path_app1=beta.com"
]

a1h2_dir = directory app1_host2_dir do
  recursive true
  action :nothing
end.run_action(:create)

a1h2_file = file "#{app1_host2_dir}/tags.json" do
  content JSON.pretty_generate(app1_host2_tags)
  action :nothing
end.run_action(:create)

app2_host1_dir = "/vagrant/cache_dir/machine_tag_cache/app2-host1"

# Tags for server1 on the app2 pool
app2_host1_tags = [
  "server:uuid=app2host1",
  "application:active=true",
  "application:active_app2=true",
  "application:bind_ip_address_app2=10.1.66.22",
  "application:bind_port_app2=80",
  "application:vhost_path_app2=charlie.com"
]

a2h1_dir = directory app2_host1_dir do
  recursive true
  action :nothing
end.run_action(:create)

a2h1_file = file "#{app2_host1_dir}/tags.json" do
  content JSON.pretty_generate(app2_host1_tags)
  action :nothing
end.run_action(:create)

app3_host1_dir = "/vagrant/cache_dir/machine_tag_cache/app3-host1"

# Tags for server1 on the app2 pool
app3_host1_tags = [
  "server:uuid=app3host1",
  "application:active=true",
  "application:active_app3=true",
  "application:bind_ip_address_app3=10.1.77.44",
  "application:bind_port_app3=80",
  "application:vhost_path_app3=delta.com"
]

a3h1_dir = directory app3_host1_dir do
  action :nothing
  recursive true
end.run_action(:create)

a3h1_file = file "#{app3_host1_dir}/tags.json" do
  content JSON.pretty_generate(app3_host1_tags)
  action :nothing
end.run_action(:create)

default_folder = "/vagrant/cache_dir/machine_tag_cache/default"

# Tags for server1 on the app2 pool
default_tags = [
  "server:uuid=discourse",
  "application:active=true",
  "application:active_default=true",
  "application:bind_ip_address_default=166.78.170.64",
  "application:bind_port_default=80",
  "application:vhost_path_default=discourse.test.rightscale.com"
]

default_dir = directory default_folder do
  action :nothing
  recursive true
end.run_action(:create)

default_file = file "#{default_folder}/tags.json" do
  content JSON.pretty_generate(default_tags)
  action :nothing
end.run_action(:create)
