# frozen_string_literal: true
#
# Cookbook Name:: rs-haproxy
# Recipe:: tags
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

include_recipe 'rightscale_tag::default'

Chef::Log.info 'Setting load balancer tags...'
node['rs-haproxy']['pools'].each do |pool_name|
  # Set up load balancer tags for the pool
  rightscale_tag_load_balancer RsHaproxy::Helper.get_config_pool_name(pool_name) do
    action :create
  end
end
