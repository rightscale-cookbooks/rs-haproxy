# frozen_string_literal: true
name             'fake'
maintainer       'RightScale, Inc.'
maintainer_email 'cookbooks@rightscale.com'
license          'Apache 2.0'
description      'Installs/Configures a test haproxy server'
version          '0.1.0'

depends 'rs-haproxy'
depends 'rs-application_php'
depends 'chef-sugar'
depends 'hostsfile'
depends 'curl'
depends 'yum-epel'
depends 'yum-mysql-community'

recipe 'fake::default', 'Creates fake application servers to verify HAProxy backend configuration.'
recipe 'fake::mysql_repo', 'Creates fake application servers to verify HAProxy backend configuration.'
recipe 'fake::wget_cacert', 'If RHEL, update /etc/wgetrc to look at /etc/ssl/certs/ca-bundle.trust.crt.'
recipe 'fake::create_secrets', 'creates secrets file'
