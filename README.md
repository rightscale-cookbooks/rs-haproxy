# rs-haproxy cookbook

[![Build Status](https://travis-ci.org/rightscale-cookbooks/rs-haproxy.png?branch=master)](https://travis-ci.org/rightscale-cookbooks/rs-haproxy)

Sets up HAProxy load balancer on a server. HAProxy can be configured to support SSL encryption.
It also provides recipe to setup HAProxy as the front-end server by attaching all application servers
in the same deployment as the HAProxy server to its back-end.

The mechanism by which the HAProxy server identifies application servers in the same deployment is
by using machine tags. Refer to the [rightscale_tag cookbook][RightScale Tag] for more information
on the machine tags set up on the servers in a RightScale environment.

[RightScale Tag]: https://github.com/rightscale-cookbooks/rightscale_tag

# Requirements

* Chef 11 or higher
* Cookbook requirements
  * [haproxy](http://community.opscode.com/cookbooks/haproxy)
  * [rightscale_tag](http://community.opscode.com/cookbooks/rightscale_tag)
  * [marker](http://community.opscode.com/cookbooks/marker)
* Platform
  * Ubuntu 12.04
  * CentOS 6

# Usage

* Add the `rs-haproxy::default` recipe to your run list to install HAProxy and set up HAProxy server.
Configure SSL in HAProxy by setting the `node['rs-haproxy']['ssl_cert']` attribute to a PEM formatted
file containing the SSL certificate and credentials.
* To attach all existing application servers in the deployment to the corresponding backend
pools served by HAProxy, run the `rs-haproxy::frontend` recipe. This recipe finds the
application server in the deployment by querying for the [application tags][Application Server Tags]
on the server.

[Application Server Tags]: https://github.com/rightscale-cookbooks/rightscale_tag#application-servers

# Attributes

* `node['rs-haproxy']['pools']` - The list of pools that the HAProxy answers. The order
of the items in the list will be preserved when answering to requests. The last entry will
be the default backend and will answer for all pools not listed here. The pool names can only
have alphanumeric characters and underscores. Default: `['default']`
* `node['rs-haproxy']['ssl_cert']` - PEM formatted file containing SSL certificates and keys for SSL
encryption. If this attribute is set to `nil`, then HAProxy will be set up without support for
SSL. Default: `nil`
* `node['rs-haproxy']['stats_uri']` - The URI for the load balancer statistics report 
page. Default: `/haproxy-status`
* `node['rs-haproxy']['stats_user']` - Username for the load balancer statistics report 
page. Default: `nil`
* `node['rs-haproxy']['stats_password']` - Password for the load balancer statistics
report page. Default: `nil`
* `node['rs-haproxy']['session_stickiness']` - Determines session stickiness. Setting to
`true`, the load balancer will reconnect a session to the last server it was connected
to (via a cookie). Default: `true`.
* `node['rs-haproxy']['health_check_uri']` - The URI that the load balancer will use to
check the health of a server. Default: `/`
* `node['rs-haproxy']['balance_algorithm']` - The algorithm that the load balancer will use to
direct traffic. Default: `roundrobin`

# Recipes

## `rs-haproxy::default`

Installs HAProxy 1.5 by downloading the source package and compiling it. This recipe simply sets up
the HAProxy configuration file using the [haproxy LWRP](https://github.com/hw-cookbooks/haproxy#haproxy),
enables, and starts the HAProxy service. If the `node['rs-haproxy']['ssl_cert']` attribute is set
with the SSL certificate contents, then this recipe will configure HTTPS support on the HAProxy
server.

## `rs-haproxy::tags`

Tags the HAProxy server with the load balancer related machine tags. Refer to [rightscale_tag cookbook][Load Balancer Tags]
for the list of tags set on a load balancer server. This recipe must be run to make the HAProxy server
discoverable to the application servers in the deployment. The application servers can then attach to
the HAProxy server by running the `rs-haproxy::backend` recipe.

## `rs-haproxy::collectd`

Sets up monitoring for the HAProxy service. This recipe installs the HAProxy collectd plugin to monitor
the HAProxy process.

## `rs-haproxy::frontend`

Attaches all existing application servers in the deployment to the corresponding pools served by HAProxy
server. This recipe finds the application server in the deployment by querying for the [application tags][Application Server Tags]
on the application server.

# Author

Author:: RightScale, Inc. (<cookbooks@rightscale.com>)
