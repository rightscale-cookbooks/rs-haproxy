name             'rs-haproxy'
maintainer       'RightScale, Inc.'
maintainer_email 'cookbooks@rightscale.com'
license          'Apache 2.0'
description      'Application cookbook to set up HAProxy on a RightScale environment'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.1.8'

depends 'marker', '~> 1.0.1'
depends 'haproxy', '~> 1.6.0'
depends 'collectd', '~> 1.1.0'
depends 'rightscale_tag', '~> 1.0.3'
depends 'rs-base', '~> 1.1.2'

recipe 'rs-haproxy::default', 'Installs HAProxy and sets up monitoring for the HAProxy process.'
recipe 'rs-haproxy::tags', 'Adds load balancer related machine tags to the load balancer server.'
recipe 'rs-haproxy::collectd', 'Configures monitoring by setting up collectd plugin for HAProxy.'
recipe 'rs-haproxy::frontend', 'Queries for application servers in the deployment and adds them' +
 ' to the corresponding backend pools served by the load balancer.'
recipe 'rs-haproxy::schedule', 'Configure cron to periodically run rs-haproxy::frontend.'
recipe 'rs-haproxy::hatop', 'installs hatop on the server'

attribute "rs-haproxy/pools",
  :display_name => "Load Balance Pools",
  :description =>
    "List of application pools for which the load balancer" +
    " will create backend pools to answer website requests. The order of the" +
    " items in the list will be preserved when answering to requests." +
    " Last entry will be considered as the default backend and will answer for all" +
    " requests. Application servers can provide any number of URIs or FQDNs (virtual host paths)" +
    " to join corresponding server pool backends. The pool names can have only" +
    " alphanumeric characters and underscores. Example: mysite, _api, default123",
  :type => 'array',
  :required => "recommended",
  :default => ["default"],
  :recipes => [
    'rs-haproxy::default',
    'rs-haproxy::tags',
    'rs-haproxy::frontend'
  ]

attribute 'rs-haproxy/incoming_port',
  :display_name => 'HAProxy HTTP Listen Port',
  :description => 'The port on which HAProxy listens for HTTP requests.',
  :required => 'optional',
  :recipes => [
    'rs-haproxy::default',
    'rs-haproxy::frontend'
  ]

attribute "rs-haproxy/ssl_cert",
  :display_name => "HAProxy SSL Certificate",
  :description => "PEM formatted string containing SSL certificates and keys for SSL encryption." +
    " Unset this to configure HAProxy without SSL encryption.",
  :required => "optional",
  :recipes => [
    'rs-haproxy::default',
    'rs-haproxy::frontend'
  ]

attribute 'rs-haproxy/ssl_incoming_port',
  :display_name => 'HAProxy HTTPS Listen Port',
  :description => 'The port on which HAProxy listens for HTTPS requests',
  :required => 'optional',
  :recipes => [
    'rs-haproxy::default',
    'rs-haproxy::frontend'
  ]

attribute "rs-haproxy/stats_uri",
  :display_name => "Statistics URI",
  :description =>
    "The URI for the load balancer statistics report page." +
    " This page lists the current session, queued session, response error," +
    " health check error, server status, etc. for each load balancer group." +
    " Example: /haproxy-status",
  :required => "optional",
  :default => "/haproxy-status",
  :recipes => ['rs-haproxy::default']

attribute "rs-haproxy/stats_user",
  :display_name => "Statistics Page Username",
  :description =>
    "The username that is required to access the load balancer" +
    " statistics report page. Example: cred:STATS_USER",
  :required => "optional",
  :recipes => ['rs-haproxy::default']

attribute "rs-haproxy/stats_password",
  :display_name => "Statistics Page Password",
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
  :recipes => [
    'rs-haproxy::default',
    'rs-haproxy::frontend'
  ]

attribute "rs-haproxy/health_check_uri",
  :display_name => "Health Check URI",
  :description =>
    "The URI that the load balancer will use to check the health of a server." +
    " It is only used for HTTP (not HTTPS) requests. Example: /",
  :required => "optional",
  :default => "/",
  :recipes => ['rs-haproxy::default']

attribute "rs-haproxy/balance_algorithm",
  :display_name => "Load Balancing Algorithm",
  :description =>
    "The algorithm that the load balancer will use to direct traffic." +
    " Example: roundrobin",
  :required => "optional",
  :default => "roundrobin",
  :choice => ["roundrobin", "leastconn", "source"],
  :recipes => ['rs-haproxy::default']

attribute "rs-haproxy/schedule/enable",
  :display_name => 'Periodic Queries of Application Server',
  :description => 'Enable or disable periodic queries of application servers in the deployment.',
  :required => 'optional',
  :choice => ['true', 'false'],
  :default => 'true',
  :recipes => ['rs-haproxy::schedule']

attribute "rs-haproxy/schedule/interval",
  :display_name => 'Interval for Periodic Queries',
  :description => 'Interval in minutes to run periodic queries of application servers in the deployment.' +
    ' Example: 15',
  :required => 'optional',
  :default => '15',
  :recipes => ['rs-haproxy::schedule']

attribute "rs-haproxy/backend/fall",
  :display_name => "backend fall",
  :description => 'The "fall" parameter states that a server will be considered as dead after
<count> consecutive unsuccessful health checks. This value defaults to 3 if
unspecified. See also the "check", "inter" and "rise" parameters.',
  :required => 'optional',
  :default => '2'

attribute "rs-haproxy/backend/rise",
  :display_name => "backend rise",
  :description => 'The "rise" parameter states that a server will be considered as operational
after <count> consecutive successful health checks. This value defaults to 2',
  :required => "optional",
  :default => '3'

attribute "rs-haproxy/backend/inter",
  :display_name => "backend inter",
  :description => 'The "inter" parameter sets the interval between two consecutive health checks
to <delay> milliseconds. If left unspecified, the delay defaults to 2000 ms.',
  :required => "optional",
  :default => '300'

attribute "rs-haproxy/maxconn",
  :display_name => "max connections for haproxy",
  :description => "max connections for haproxy",
  :required => "optional",
  :default => '4096'

attribute "haproxy/member_max_connections",
  :dispay_name => "member_max_connections",
  :desciption => "member_max_connections",
  :required => "optional",
  :default => '100'
  
attribute "haproxy/config/defaults/http-check expect",
  :display_name => "http-check expect",
  :description => "http-check expect",
  :required => "optional",
  :choice => ['rstatus 20*', 'rstatus 30*|20*','rstatus 401|30*|20*' ],
  :default => 'rstatus 20*'
  
attribute "rs-haproxy/force_ssl_redirect",
  :display_name => "redirect scheme",
  :description => "Redirect all HTTP traffic to HTTPS when SSL is handled by haproxy.",
  :required => "optional",
  :choice => [true, false],
  :default => false   
  
