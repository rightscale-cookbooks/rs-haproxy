source 'https://supermarket.chef.io'

metadata

cookbook 'marker', github: 'rightscale-cookbooks/marker'
cookbook 'rs-base', github: 'rightscale-cookbooks/rs-base'
cookbook 'rightscale_tag', github: 'rightscale-cookbooks/rightscale_tag'
cookbook 'machine_tag', github: 'rightscale-cookbooks/machine_tag'
cookbook 'rsc_remote_recipe', github: 'rightscale-services-cookbooks/rsc_remote_recipe'
# cookbook 'haproxy', github: 'rightscale-cookbooks-contrib/haproxy', branch: 'centos-7-support'

group :integration do
  cookbook 'rs-application_php', github: 'rightscale-cookbooks/rs-application_php'
  cookbook 'application_php', github: 'rightscale-cookbooks-contrib/application_php', branch: 'chef-12-migration'
end

group :test do
  cookbook 'fake', path: './test/cookbooks/fake'
end
