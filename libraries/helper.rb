# frozen_string_literal: true
#
# Cookbook Name:: rs-haproxy
# Library:: helper
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

module RsHaproxy
  module Helper
    # Gets a haproxy.cfg and machine tag compatible pool name.
    #
    # @param pool_name [String] the pool name
    #
    # @return [String] the config pool name
    #
    # @example Given a pool name www.foo.com/app
    #   this returns 'www_foo_com_app'
    #
    def self.get_config_pool_name(pool_name)
      pool_name.gsub(%r{[\/.]}, '_')
    end

    # Determine version of HAProxy from source URL filename.
    #
    # @param uri [String] URI/URL of HAProxy source location
    #
    # @return [String] version number from HAProxy filename
    #   or nil if unable to determine version name
    #
    def self.get_haproxy_version(uri)
      require 'pathname'
      require 'uri'

      filename = Pathname.new(URI.parse(uri).path).basename.to_s
      version = filename.split('/').last.sub(/^haproxy-/, '').sub(/.tar.gz$|.tgz$/, '')
      version =~ /^\d/ ? version : nil
    end
  end
end
