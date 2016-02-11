site :opscode

metadata

cookbook 'haproxy', github: 'rightscale-cookbooks-contrib/haproxy', branch: 'rs-fixes'
cookbook 'collectd', github: 'rightscale-cookbooks-contrib/chef-collectd', branch: 'generalize_install_for_both_centos_and_ubuntu'
cookbook 'rs-base', github:'rightscale-cookbooks/rs-base'
cookbook 'rightscale_tag', github:'rightscale-cookbooks/rightscale_tag'
cookbook 'machine_tag', github:'rightscale-cookbooks/machine_tag'
cookbook 'rsc_remote_recipe', github:'rightscale-services-cookbooks/rsc_remote_recipe'



group :integration do
  cookbook 'apt', '~> 2.6.0'
  cookbook 'yum-epel', '~> 0.4.0'
  cookbook 'build-essential', '~> 1.4.4'
  cookbook 'mysql', github: 'rightscale-cookbooks-contrib/mysql', branch: 'COOK-2100'
  cookbook 'rs-application_php', github: 'rightscale-cookbooks/rs-application_php'
  cookbook 'application_php', github: 'rightscale-cookbooks-contrib/application_php', branch: 'template_fix_and_application_cookbook_upgrade'
  cookbook 'curl'
  cookbook 'fake', path: './test/cookbooks/fake'
  cookbook 'chef-sugar'
  cookbook 'hostsfile'
  cookbook 'rhsm', '~> 1.0.0'
  cookbook 'swap', '= 0.3.5'
end
