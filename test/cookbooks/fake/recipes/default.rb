#
# Cookbook Name:: fake
# Recipe:: default
#
# Copyright (C) 2013 RightScale, Inc.
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

require 'json'

app1_host1_dir = "/vagrant/cache_dir/machine_tag_cache/app1-host1"

# Tags for server1 on the app1 pool
app1_host1_tags = [
  "server:uuid=app1host1",
  "application:active=true",
  "application:active_app1=true",
  "application:bind_ip_address_app1=10.1.55.22",
  "application:bind_port_app1=80",
  "application:vhost_path_app1=site.com"
]

::FileUtils.mkdir_p(app1_host1_dir)
::File.open(::File.join(app1_host1_dir, 'tags.json'), 'w') { |file| file.write(::JSON.pretty_generate(app1_host1_tags)) }

app1_host2_dir = "/vagrant/cache_dir/machine_tag_cache/app1-host2"

# Tags for server2 on the app1 pool
app1_host2_tags = [
  "server:uuid=app1host2",
  "application:active=true",
  "application:active_app1=true",
  "application:bind_ip_address_app1=10.1.55.33",
  "application:bind_port_app1=80",
  "application:vhost_path_app1=site.com"
]

::FileUtils.mkdir_p(app1_host2_dir)
::File.open(::File.join(app1_host2_dir, 'tags.json'), 'w') { |file| file.write(::JSON.pretty_generate(app1_host2_tags)) }

app2_host1_dir = "/vagrant/cache_dir/machine_tag_cache/app2-host1"

# Tags for server1 on the app2 pool
app2_host1_tags = [
  "server:uuid=app2host1",
  "application:active=true",
  "application:active_app2=true",
  "application:bind_ip_address_app2=10.1.66.22",
  "application:bind_port_app2=80",
  "application:vhost_path_app2=site.com"
]

::FileUtils.mkdir_p(app2_host1_dir)
::File.open(::File.join(app2_host1_dir, 'tags.json'), 'w') { |file| file.write(::JSON.pretty_generate(app2_host1_tags)) }
