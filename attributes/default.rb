#
# Cookbook Name:: rs-haproxy
# Attribute:: default
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

# The pools served by the HAProxy load balancer
default['rs-haproxy']['pools'] = ['default']

# The port on which HAProxy listens for HTTP requests
default['rs-haproxy']['incoming_port'] = 80

# The port on which HAProxy listens for HTTPS requests
default['rs-haproxy']['ssl_incoming_port'] = 443

# SSL certificate to set up HTTPS support
default['rs-haproxy']['ssl_cert'] = nil

# URI for HAProxy statistics
default['rs-haproxy']['stats_uri'] = '/haproxy-status'

# Username to access HAProxy statistics
default['rs-haproxy']['stats_user'] = nil

# Password to access HAProxy statistics
default['rs-haproxy']['stats_password'] = nil

# Enable/Disable sticky sessions using cookie
default['rs-haproxy']['session_stickiness'] = true

# Enable/Disable periodically running rs-haproxy::frontend
default['rs-haproxy']['schedule']['enable'] = true

# Interval to periodically run rs-haproxy::frontend, in minutes
default['rs-haproxy']['schedule']['interval'] = '15'

# URI to check server health
default['rs-haproxy']['health_check_uri'] = '/'

# Algorithm used by load balancer to direct traffic
# Supported algorithms - "roundrobin", "leastconn", "source"
default['rs-haproxy']['balance_algorithm'] = 'roundrobin'

# HAProxy install method
# Supported values - 'package', 'source'
default['rs-haproxy']['install_method'] = 'source'

# HAProxy source version
# Set to nil to attempt retrieving version from rs-haproxy/source/url
default['rs-haproxy']['source']['version'] = nil

# HAProxy source URL
default['rs-haproxy']['source']['url'] = 'https://servertemplate-software-sources.s3.amazonaws.com/haproxy-1.5.6.tar.gz'

# HAProxy source SHA256 checksum
default['rs-haproxy']['source']['checksum'] = '214ab89dad7e0a43cc0f1c46367ca6803cd869e1717a4fa6b99451713f91f717'

default['rs-haproxy']['backend']['inter'] = 300
default['rs-haproxy']['backend']['rise'] = 3
default['rs-haproxy']['backend']['fall'] = 2
default[:haproxy][:config][:defaults][:options] = []
