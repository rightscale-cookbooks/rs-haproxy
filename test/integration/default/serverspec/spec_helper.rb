require 'serverspec'
require 'pathname'
require 'rubygems/dependency_installer'

include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

installer = Gem::DependencyInstaller.new
installer.install('haproxy-tools')
Gem.clear_paths

require 'haproxy-tools'
