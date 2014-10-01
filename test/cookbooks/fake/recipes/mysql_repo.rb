#
# Cookbook Name:: fake
# Recipe:: mysql_repo
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

# Install MySQL Yum Repository

compile_time do
  remote_file '/tmp/mysql-community-release-el7-5.noarch.rpm' do
    source 'http://dev.mysql.com/get/mysql-community-release-el7-5.noarch.rpm'
  end
end

compile_time do
  rpm_package 'mysql repository' do
    source '/tmp/mysql-community-release-el7-5.noarch.rpm'
    action :install
  end
end
