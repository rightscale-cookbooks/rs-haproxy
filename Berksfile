site :opscode

metadata

#cookbook 'haproxy', github: 'nitinmohan87/haproxy', branch: 'centos_support'
cookbook 'haproxy', path: '../haproxy'
cookbook 'collectd', github: 'EfrainOlivares/chef-collectd', branch: 'generalize_install_for_both_centos_and_ubuntu'

group :integration do
  cookbook 'apt', '~> 2.3.0'
  cookbook 'yum', '~> 2.4.4'
  cookbook 'curl'
  cookbook 'fake', path: './test/cookbooks/fake'
end
