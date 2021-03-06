# frozen_string_literal: true
#
# Cookbook Name:: fake
# Recipe:: wget_cacert
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

include_recipe 'chef-sugar::default'

# Set in wgetrc the ca-cert file to use.
compile_time do
  cookbook_file 'wgetrc' do
    path '/etc/wgetrc'
    owner 'root'
    group 'root'
    mode 0644
    action :create
    only_if { node[:platform] == 'redhat' }
  end
end
