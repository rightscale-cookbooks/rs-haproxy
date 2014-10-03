site :opscode

metadata

cookbook 'haproxy', github: 'nitinmohan87/haproxy', branch: 'rs-fixes'
cookbook 'collectd', github: 'EfrainOlivares/chef-collectd', branch: 'generalize_install_for_both_centos_and_ubuntu'
cookbook 'rs-base', github: 'rightscale-cookbooks/rs-base', tag: 'v1.1.2'

group :integration do
  cookbook 'apt', '~> 2.6.0'
  cookbook 'yum-epel', '~> 0.4.0'
  cookbook 'build-essential', '~> 1.4.4'
  cookbook 'mysql', github: 'arangamani-cookbooks/mysql', branch: 'COOK-2100'
  cookbook 'rs-application_php', github: 'rightscale-cookbooks/rs-application_php', branch: 'st_14_13_acu173881_ubuntu_1404_testing'
  cookbook 'application_php', github: 'lopakadelp/application_php', branch: 'updates_for_apache_24'
  cookbook 'curl'
  cookbook 'fake', path: './test/cookbooks/fake'
  cookbook 'chef-sugar'
  cookbook 'hostsfile'
  cookbook 'rhsm', '~> 1.0.0'
end
