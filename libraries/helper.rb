#
# Cookbook Name:: rs-haproxy
# Library:: helper
#
# Copyright (C) 2014 RightScale, Inc.
#·
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#·
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module RsHaproxy
  module Helper
    # Gets a haproxy.cfg compatible pool name.
    #
    # @param pool_name [String] the pool name
    #
    # @return [String] the config pool name
    #
    # @example Given a pool name www.foo.com/app
    #   this returns 'www.foo.com_app'
    #
    def self.get_config_pool_name(pool_name)
      pool_name.gsub(/[\/]/, '_')
    end
  end
end
