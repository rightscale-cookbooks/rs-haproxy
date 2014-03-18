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

apps_list2 = [
  ["app1", "app1_host1", "app1host1", "10.1.55.22", "alpha.com"],
  ["app1", "app1_host2", "app1host2", "10.1.55.33", "bravo.com"],
  ["app2", "app2_host1", "app2host1", "10.1.66.22", "charlie.com"],
  ["app3", "app3host1", "app3host1", "110.1.77.44", "delta.com"],
  ["default", "default_host", "discourse", "166.78.170.64", "discourse.test.rightscale.com"]
]

apps_list.each do |app, app_host, uuid, ip, domain|

  tags = [
    "server:uuid=#{uuid}",
    "application:active=true",
    "application:active_#{app}=true",
    "application:bind_ip_address_default=#{ip}",
    "application:bind_port_default=80",
    "application:vhost_path_default=#{domain}"
  ]

  r = directory "/vagrant/cache_dir/machine_tag_cache/#{app_host}" do
    action :nothing
    recursive true
  end
  r.run_action(:create)

  f = file "/vagrant/cache_dir/machine_tag_cache/#{app_host}/tags.json" do
    content JSON.pretty_generate(tags)
    action :nothing
  end
  f.run_action(:create)
end
