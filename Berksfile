site :opscode

metadata

cookbook 'haproxy', github: 'nitinmohan87/haproxy', branch: 'rs-fixes'
cookbook 'collectd', github: 'EfrainOlivares/chef-collectd', branch: 'generalize_install_for_both_centos_and_ubuntu'

group :integration do
  cookbook 'apt', '~> 2.3.0'
  cookbook 'yum', '~> 2.4.4'
  cookbook 'build-essential', '~> 1.4.4'
  cookbook 'mysql', github: 'arangamani-cookbooks/mysql', branch: 'COOK-2100'
  cookbook 'rs-application_php', github: 'rightscale-cookbooks/rs-application_php'
  cookbook 'curl'
  cookbook 'fake', path: './test/cookbooks/fake'
end
