# rs-haproxy cookbook

[![Build Status](https://travis-ci.org/rightscale-cookbooks/rs-haproxy.png?branch=master)](https://travis-ci.org/rightscale-cookbooks/rs-haproxy)

Sets up HAProxy on a server and attaches all application server in the same deployment
as the HAProxy server.

# Requirements

* Chef 11 or higher
* Cookbook requirements
  * [haproxy](http://community.opscode.com/cookbooks/haproxy)
  * [rightscale_tag](https://github.com/rightscale-cookbooks/rightscale_tag)
  * [marker](http://community.opscode.com/cookbooks/marker)
* Platform
  * Ubuntu 12.04
  * CentOS 6

# Usage

* Add the `rs-haproxy::default` recipe to your run list to install HAProxy as a package and
set up HAProxy server.
* Run the `rs-haproxy::tags` recipe to set up load balancer related machine tags to the
HAProxy server. Refer to [rightscale_tag cookbook][Load Balancer Tags] for the list of tags
set on a load balancer server.
* To attach all existing application servers in the deployment to the corresponding backend
pools served by HAProxy, run the `rs-haproxy::frontend` recipe. This recipe finds the
application server in the deployment by querying for the [application tags][Application Server Tags]
on the server.
* Run the `rs-haproxy::monitoring` to install HAProxy collectd plugin and set up monitoring for
the HAProxy server.

[Load Balancer Tags]: https://github.com/rightscale-cookbooks/rightscale_tag#load-balancer-servers
[Application Server Tags]: https://github.com/rightscale-cookbooks/rightscale_tag#application-servers

# Attributes

* `node['rs-haproxy']['pools']` - The list of pools that the HAProxy answers. The order
of the items in the list will be preserved when answering to requests. Last entry will
be the default backend and will answer for all pools not listed here.
Default: `['default']`
* `node['rs-haproxy']['stats_uri']` - The URI for the load balancer statistics report 
page.
* `node['rs-haproxy']['stats_user']` - Username for the load balancer statistics report 
page.
* `node['rs-haproxy']['stats_password']` - Password for the load balancer statistics
report page.
* `node['rs-haproxy']['session_stickiness']` - Determines session stickiness. Setting to
`true`, the load balancer will reconnect a session to the last server it was connected
to (via a cookie). Default: `true`.
* `node['rs-haproxy']['health_check_uri']` - The URI that the load balancer will use to
check the health of a server. Default: `/`
* `node['rs-haproxy']['algorithm']` - The algorithm that the load balancer will use to
direct traffic. Default: `roundrobin`

# Recipes

## `rs-haproxy::default`

Installs HAProxy as a package and configures an HAProxy server. This recipe simply sets up the HAProxy
configuration file using the [haproxy LWRP](https://github.com/hw-cookbooks/haproxy#haproxy), enables,
and starts the HAProxy service.

## `rs-haproxy::tags`

Tags the HAProxy server with the load balancer related machine tags. Refer to [rightscale_tag cookbook][Load Balancer Tags]
for the list of tags set on a load balancer server. This recipe must be run to make the HAProxy server
discoverable to the application servers in the deployment. The application servers can then attach to
the HAProxy server by running the `rs-haproxy::backend` recipe.

## `rs-haproxy::monitoring`

Sets up monitoring for the HAProxy service. This recipe installs the HAProxy collectd plugin to monitor
the HAProxy process.

## `rs-haproxy::frontend`

Attaches all existing application servers in the deployment to the corresponding pools served by HAProxy
server. This recipe finds the application server in the deployment by querying for the [application tags][Application Server Tags]
on the application server.

# Author

Author:: RightScale, Inc. (<cookbooks@rightscale.com>)
