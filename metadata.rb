name             'rs-haproxy'
maintainer       'RightScale, Inc.'
maintainer_email 'cookbooks@rightscale.com'
license          'Apache 2.0'
description      'Application cookbook to set up HAProxy on a RightScale environment'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

depends 'marker', '~> 1.0.0'
depends 'haproxy'
depends 'collectd', '~> 1.1.0'
depends 'rightscale_tag'

recipe 'rs-haproxy::default', 'Installs HAProxy and sets up monitoring for the HAProxy process.'
recipe 'rs-haproxy::add_application_server', 'Adds an application server to the backend section in the haproxy.cnf file'

attribute "rs-haproxy/pools",
  :display_name => "Load Balance Pools",
  :description =>
    "List of URIs or FQDNs for which the load balancer" +
    " will create server pools to answer website requests. The order of the" +
    " items in the list will be preserved when answering to requests." +
    " Last entry will be the default backend and will answer for all URIs and" +
    " FQDNs not listed here. A single entry of any name, e.g. 'default', " +
    " 'www.mysite.com' or '/appserver', will mimic basic behavior of" +
    " one load balancer with one pool of application servers. This will be" +
    " used for naming server pool backends. Application servers can provide" +
    " any numbers of URIs or FQDNs to join corresponding server pool" +
    " backends.Example: www.mysite.com, api.mysite.com, /serverid, default",
  :type => 'array',
  :required => "recommended",
  :default => ["default"],
  :recipes => ['rs-haproxy::default']

attribute "rs-haproxy/stats_uri",
  :display_name => "Status URI",
  :description =>
    "The URI for the load balancer statistics report page." +
    " This page lists the current session, queued session, response error," +
    " health check error, server status, etc. for each load balancer group." +
    " Example: /haproxy-status",
  :required => "optional",
  :default => "/haproxy-status",
  :recipes => ['rs-haproxy::default']

attribute "rs-haproxy/stats_user",
  :display_name => "Status Page Username",
  :description =>
    "The username that is required to access the load balancer" +
    " statistics report page. Example: cred:STATS_USER",
  :required => "optional",
  :recipes => ['rs-haproxy::default']

attribute "rs-haproxy/stats_password",
  :display_name => "Status Page Password",
  :description =>
    "The password that is required to access the load balancer statistics" +
    " report page. Example: cred:STATS_PASSWORD",
  :required => "optional",
  :recipes => ['rs-haproxy::default']

attribute "rs-haproxy/session_stickiness",
  :display_name => "Use Session Stickiness",
  :description =>
    "Determines session stickiness. Set to 'True' to use session stickiness," +
    " where the load balancer will reconnect a session to the last server it" +
    " was connected to (via a cookie). Set to 'False' if you do not want to" +
    " use sticky sessions; the load balancer will establish a connection" +
    " with the next available server. Example: true",
  :required => "optional",
  :choice => ["true", "false"],
  :default => "true",
  :recipes => ['rs-haproxy::default']

attribute "rs-haproxy/health_check_uri",
  :display_name => "Health Check URI",
  :description =>
    "The URI that the load balancer will use to check the health of a server." +
    " It is only used for HTTP (not HTTPS) requests. Example: /",
  :required => "optional",
  :default => "/",
  :recipes => ['rs-haproxy::default']

attribute "rs-haproxy/algorithm",
  :display_name => "Load Balancing Algorithm",
  :description =>
    "The algorithm that the load balancer will use to direct traffic." +
    " Example: roundrobin",
  :required => "optional",
  :default => "roundrobin",
  :choice => ["roundrobin", "leastconn", "source"],
  :recipes => ['rs-haproxy::default']
