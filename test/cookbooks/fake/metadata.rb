name             'fake'
maintainer       'RightScale, Inc.'
maintainer_email 'cookbooks@rightscale.com'
license          'Apache 2.0'
description      'Installs/Configures a test haproxy server'
version          '0.1.0'

depends 'rs-haproxy'

recipe 'fake::default', 'Tags servers to be used in the haproxy backend'
