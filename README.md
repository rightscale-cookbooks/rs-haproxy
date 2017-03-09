# rs-haproxy cookbook

[![Release](https://img.shields.io/github/release/rightscale-cookbooks/rs-haproxy.svg?style=flat)][release]
[![Build Status](https://img.shields.io/travis/rightscale-cookbooks/rs-haproxy.svg?style=flat)][travis]

[release]: https://github.com/rightscale-cookbooks/rs-haproxy/releases/latest
[travis]: https://travis-ci.org/rightscale-cookbooks/rs-haproxy

Sets up HAProxy load balancer on a server. This cookbook also provides attributes and recipes to
configure SSL on HAProxy and set up HAProxy as the front-end by attaching application servers to its
back-end in a 3-tier deployment setup.

The HAProxy server identifies application servers in the same deployment by using machine tags.
Refer to the [rightscale_tag cookbook][RightScale Tag] for more information on the machine tags
set up on the servers in a RightScale environment.

Github Repository: [https://github.com/rightscale-cookbooks/rs-haproxy](https://github.com/rightscale-cookbooks/rs-haproxy)

[RightScale Tag]: https://github.com/rightscale-cookbooks/rightscale_tag

# Requirements

* Chef 12
* Requires [RightLink 10](http://docs.rightscale.com/rl10/)
  * for Chef 11 - v1.2.3
  * for RightLink 6 support - v1.1.3
* Cookbook requirements
  * [haproxy](http://community.opscode.com/cookbooks/haproxy)
  * [rightscale_tag](http://community.opscode.com/cookbooks/rightscale_tag)
  * [marker](http://community.opscode.com/cookbooks/marker)
  * [collectd](https://github.com/rightscale-cookbooks-contrib/chef-collectd)
* Platform
  * Ubuntu 12.04, 14.04, 16.04
  * CentOS 6.x, 7.x
  * RHEL 6.x, 7.x

# Usage

To **install and configure** HAProxy with **SSL** support

* Add the `rs-haproxy::default` recipe to your run list.
* To enable SSL in HAProxy set the `node['rs-haproxy']['ssl_cert']` attribute to a PEM formatted
string containing the SSL certificate and the credentials. If the `node['rs-haproxy']['ssl_cert']`
attribute is not set HAPRoxy will be configured without SSL support.

To **configure** HAProxy as the **front-end**

* Add the `rs-haproxy::frontend` recipe to your run list.
* Set the `node['rs-haproxy']['pools']` attribute to a list of pool names that the HAProxy should
serve.
* Ensure that the application servers to be attached to HAProxy's back-end have application names
same as one of the pool names served by HAProxy and the servers have the required machine tags
set up. Refer to [Application Servers][Application Servers] section in the `rightscale_tag` cookbook
for the machine tags set on the application servers.

[Application Servers]: https://github.com/rightscale-cookbooks/rightscale_tag#application-servers

# Attributes

* `node['rs-haproxy']['pools']` - The list of pools that the HAProxy answers. The order
of the items in the list will be preserved when answering to requests. The last entry will
be the default backend and will answer for all pools not listed here. The pool names can only
have alphanumeric characters and underscores. Default: `['default']`
* `node['rs-haproxy']['ssl_cert']` - PEM formatted string containing SSL certificates and keys for SSL
encryption. If this attribute is set to `nil`, then HAProxy will be set up without support for
SSL. Default: `nil`
* `node['rs-haproxy']['incoming_port']` - The port on which HAProxy listens for HTTP requests. Default is `80`.
* `node['rs-haproxy']['ssl_incoming_port']` - The port on which HAProxy listens for HTTPS requests. Default is `443`.
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
* `node['rs-haproxy']['backend']['inter']` - The "inter" parameter sets the interval between
two consecutive health checks to <delay> milliseconds. Default: `300`
* `node['rs-haproxy']['backend']['rise']` - The "rise" parameter states that a server will be considered
 as operational after <count> consecutive successful health checks. Default: `3`
* `node['rs-haproxy']['backend']['fall']` - 'The "fall" parameter states that a server will be considered
as dead after <count> consecutive unsuccessful health checks. Default: `2`
* `node['rs-haproxy']['maxconn']` - 'Fix the maximum number of concurrent connections on a frontend'. Default: `4096`

# Recipes

## `rs-haproxy::default`

Installs HAProxy 1.5 by downloading the source package and compiling it. This recipe simply sets up
the HAProxy configuration file using the [haproxy LWRP](https://github.com/hw-cookbooks/haproxy#haproxy),
enables, and starts the HAProxy service. If the `node['rs-haproxy']['ssl_cert']` attribute is set
then this recipe will configure HTTPS support on the HAProxy server. All HTTP requests will be
redirected to HTTPS in this scenario.

## `rs-haproxy::tags`

Tags the HAProxy server with the load balancer related machine tags. Refer to [rightscale_tag cookbook][Load Balancer Tags]
for the list of tags set on a load balancer server. This recipe must be run to make the HAProxy server
discoverable to the application servers in the deployment. The application servers can then attach to
the HAProxy server by running the `rs-haproxy::backend` recipe.

## `rs-haproxy::collectd`

Sets up monitoring for the HAProxy service. This recipe installs the HAProxy collectd plugin to monitor
the HAProxy process.

## `rs-haproxy::frontend`

This recipe can be used in two different contexts.

* To attach all existing application servers in the deployment to the corresponding pools served by
the HAProxy server. This recipe finds application servers in the deployment by querying for the
[application tags][Application Server Tags] on the application server. Only the application servers
whose application name matches one of the pool names in HAProxy are identified and attached to the
HAProxy server.
* To be run as a remote recipe for attaching/detaching a single application server to/from the HAProxy
servers. To *attach* a single application server, the server invoking the remote recipe call should
set `node['remote_recipe']['application_action']` attribute to `attach` and pass its application
name, bind IP address and port, server UUID, and the virtual host name to the HAProxy server.
To *detach* a single application server, this attribute should be set to `detach` and the invoking
server should pass its application name and the server UUID to the HAProxy server. Refer to
[rs_run_recipe utility][rs_run_recipe] for making remote recipe calls and passing information to the
remote recipe.

## `rs-haproxy::schedule`

Configure cron to periodically run `rs-haproxy::frontend` confirming that all application servers in the
deployment are registered with HAProxy.

## `rs-haproxy::hatop`

Downloads and installs hatop on the haproxy server, will install python also as it is a requirement

[rs_run_recipe]: http://support.rightscale.com/12-Guides/RightLink/02-RightLink_5.9/Using_RightLink/Command_Line_Utilities#rs_run_recipe
[Load Balancer Tags]: https://github.com/rightscale-cookbooks/rightscale_tag#load-balancer-servers
[Application Server Tags]: https://github.com/rightscale-cookbooks/rightscale_tag#application-servers

# Author

Author:: RightScale, Inc. (<cookbooks@rightscale.com>)
