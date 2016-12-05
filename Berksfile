source "https://supermarket.chef.io"

metadata

cookbook 'rs-base', github:'rightscale-cookbooks/rs-base', branch: 'chef-12-migration'
cookbook 'rightscale_tag', github:'rightscale-cookbooks/rightscale_tag', branch: 'chef-12-migration'
cookbook 'machine_tag', github:'rightscale-cookbooks/machine_tag', branch: 'chef-12-migration'
cookbook 'rsc_remote_recipe', github:'rightscale-services-cookbooks/rsc_remote_recipe', branch: 'chef-12-migration'

group :test do
  cookbook 'fake', path: './test/cookbooks/fake'
end
