site :opscode

metadata

cookbook 'rightscale_tag', github: 'rightscale-cookbooks/rightscale_tag', branch:'white_14_03_acu111916_add_list_tags_helpers'
cookbook 'haproxy', github: 'nitinmohan87/haproxy', branch: 'centos_support'
cookbook 'collectd', github: 'EfrainOlivares/chef-collectd', branch: 'generalize_install_for_both_centos_and_ubuntu'

group :integration do
  cookbook 'apt', '~> 2.3.0'
  cookbook 'yum', '~> 2.4.4'
  cookbook 'curl'
  cookbook 'fake', path: './test/cookbooks/fake'
end
