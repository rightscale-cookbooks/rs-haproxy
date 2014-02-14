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
    # Categorizes the application servers hash returned by find_application_servers method based
    # on application names.
    #
    # @param servers [Hash{String, Hash}] the application servers hash
    #
    # @return [Hash] the pools hash with pool name as the key and the server hash as value
    #
    # @example Given the application servers hash as below
    #
    # {
    #   '01-ABCDEF7890123' => {
    #     'applications' => {
    #       'www' => {
    #         'bind_ip_address' => '10.0.0.3',
    #         'bind_port' => 8080,
    #         'vhost_path' => '/',
    #       }
    #     },
    #     'public_ips' => ['203.0.113.3'],
    #     'private_ips' => ['10.0.0.3']
    #   },
    #   '01-EDFHG9876DFG' => {
    #     'applications' => {
    #       'api' => {
    #         'bind_ip_address' => '10.0.0.3',
    #         'bind_port' => 8080,
    #         'vhost_path' => '/',
    #       }
    #     },
    #     'public_ips' => ['8.0.13.3'],
    #     'private_ips' => ['10.0.0.3']
    #   }
    # }
    #
    # This method returns
    #
    # {
    #   'www' => {
    #     '01-ABCDEF7890123' => {
    #       'bind_ip_address' => '10.0.0.3',
    #       'bind_port' => 8080,
    #       'vhost_path' => '/',
    #     }
    #   }
    #   'api' => {
    #     {
    #       '01-EDFHG9876DFG' => {
    #         'bind_ip_address' => '10.0.0.3',
    #         'bind_port' => 8080,
    #         'vhost_path' => '/',
    #       }
    #     }
    #   ]
    # }
    #
    def self.categorize_servers_by_pools(servers)
      pools_hash = {}
      servers.each do |server_uuid, server_hash|
        server_hash['applications'].each do |app_name, app_hash|
          pools_hash[app_name] ||= {}
          pools_hash[app_name][server_uuid] = app_hash
        end
      end
      pools_hash
    end

    def self.get_global_config(node)
      {
        :maxconn => node[:haproxy][:global_max_connections],
        :user => node[:haproxy][:user],
        :group => node[:haproxy][:group],
        :log => "/dev/log syslog info",
        :daemon => true,
        :quiet => true,
        :pidfile => node['haproxy']['pid_file']
      }
    end

    def self.get_backend_pool_config(node, options = {})
      config_hash = {
        :mode => 'http',
        :balance => node['haproxy']['balance_algorithm']
      }

      if node['haproxy']['enable_stats_socket']
        config_hash[:stats] = "uri #{node['rs-haproxy']['stats_uri']}"
      end

      if node['haproxy']['http_chk']
        config_hash[:option] = "httpchk GET #{node['haproxy']['http_chk']}"
        config_hash[:'http-check'] = 'disable-on-404'
      end

      config_hash.merge(options)
    end

    # Adds configuration options to the backend servers in haproxy.cfg.
    #
    # @param node [Chef::Node] the chef node
    # @param options [Hash{Symbol => Fixnum, nil}] the optional parameters to add to the configuration
    #
    # @return [Hash] the server configuration hash
    #
    def self.get_backend_server_config(node, options = {})
      config_hash = {
        :inter => 300,
        :rise => 2,
        :fall => 3,
        :maxconn => node['haproxy']['member_max_connections']
      }

      if node['haproxy']['http_chk']
        config_hash[:check] = true
      end

      config_hash.merge(options)
    end
  end
end
