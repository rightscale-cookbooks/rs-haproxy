# rs-haproxy cookbook

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

Add a dependency to your cookbook's `metadata.rb`:

```ruby
depends 'rs-haproxy'
```

Add the `rs-haproxy::default` recipe to your run list to set up HAProxy server. It also attaches all existing application servers in the deployment to the corresponding pools
that the HAProxy serves.

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

Sets up a HAProxy server. Attaches all existing application servers in the deployment to
the corresponding pools that the HAProxy serves.

# Author

Author:: RightScale, Inc. (<cookbooks@rightscale.com>)
