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

app1_host1_dir = "/vagrant/cache_dir/machine_tag_cache/app-host-1"

# Tags for a Server on the app1 pool
app1_host1_tags = [
  "server:uuid=1111111111",
  "application:active=true",
  "application:active_app1=true",
  "application:bind_ip_address_app1=10.1.55.22",
  "application:bind_port_app1=80",
  "application:vhost_path_app1=site.com"
]

::FileUtils.mkdir_p(app1_host1_dir)
::File.open(::File.join(app1_host1_dir, 'tags.json'), 'w') { |file| file.write(::JSON.pretty_generate(app1_host1_tags)) }
