site :opscode

metadata

cookbook 'haproxy', github: 'rightscale-cookbooks-contrib/haproxy', branch: 'st_14_13_acu173881_addition_os_support'
cookbook 'collectd', github: 'EfrainOlivares/chef-collectd', branch: 'generalize_install_for_both_centos_and_ubuntu'
cookbook 'rs-base', github: 'rightscale-cookbooks/rs-base', tag: 'v1.1.2'

group :integration do
  cookbook 'apt', '~> 2.6.0'
  cookbook 'yum-epel', '~> 0.4.0'
  cookbook 'build-essential', '~> 1.4.4'
  cookbook 'mysql', github: 'rightscale-cookbooks-contrib/mysql', branch: 'COOK-2100'
  cookbook 'rs-application_php', github: 'rightscale-cookbooks/rs-application_php', branch: 'st_14_13_acu173881_update_new_os'
  cookbook 'application_php', github: 'rightscale-cookbooks-contrib/application_php', branch: 'updates_for_apache_24'
  cookbook 'curl'
  cookbook 'fake', path: './test/cookbooks/fake'
  cookbook 'chef-sugar'
  cookbook 'hostsfile'
  cookbook 'rhsm', '~> 1.0.0'
end
