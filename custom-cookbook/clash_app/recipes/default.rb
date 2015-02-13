#
# Cookbook Name:: clash_app
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

%w(build-essential libsqlite3-dev libssl-dev).each do |pkg|
  package pkg
end

include_recipe "ruby_build"

ruby_build_ruby '2.1.4' do
  prefix_path '/usr/local'
  action :install
end

gem_package "bundler" do
  options("--prerelease --no-format-executable")
end

execute 'bundle install' do
  cwd '/vagrant/ruby'
  not_if 'bundle check' # This is not run inside /myapp
end

include_recipe "nodejs"
