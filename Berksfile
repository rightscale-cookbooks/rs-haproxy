site :opscode

metadata

cookbook 'haproxy', github: 'rightscale-cookbooks-contrib/haproxy', branch: 'rs-fixes'
cookbook 'collectd', github: 'rightscale-cookbooks-contrib/chef-collectd', branch: 'generalize_install_for_both_centos_and_ubuntu'
cookbook 'rs-base', github:'rightscale-cookbooks/rs-base', branch: 'v1.4.0'
cookbook 'rightscale_tag', github:'rightscale-cookbooks/rightscale_tag'
cookbook 'machine_tag', github:'rightscale-cookbooks/machine_tag'
cookbook 'rsc_remote_recipe', github:'rightscale-services-cookbooks/rsc_remote_recipe'
cookbook 'iptables', '~> 1.1.0' # keep for compatiblity with chef 11, can remove with chef 12
cookbook 'logrotate','1.9.2' # keep for compatiblity with chef 11, can remove with chef 12
cookbook 'aws','3.4.1' # keep for compatiblity with chef 11, can remove with chef 12
cookbook 'ohai', '3.0.0' # keep for compatiblity with chef 11, can remove with chef 12

group :integration do
  cookbook 'apt', '~> 2.9.2'
  cookbook 'yum','3.9.0'
  cookbook 'yum-epel', '~> 0.4.0'
  cookbook 'build-essential', '~> 1.4.4'
  cookbook 'mysql', github: 'rightscale-cookbooks-contrib/mysql', branch: 'COOK-2100'
  cookbook 'rs-application_php', github: 'rightscale-cookbooks/rs-application_php'
  cookbook 'application_php', github: 'rightscale-cookbooks-contrib/application_php', branch: 'template_fix_and_application_cookbook_upgrade'
  cookbook 'curl'
  cookbook 'chef-sugar'
  cookbook 'hostsfile'
  cookbook 'rhsm', '~> 1.0.0'
  cookbook 'swap', '= 0.3.5'
end

group :test do
  cookbook 'fake', path: './test/cookbooks/fake'
end
