#
# Cookbook Name:: sample
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
execute "apt-get update" do
  command "apt-get update"
end

package 'git' do
  action :install
end

rvm_ruby "#{node['rvm']['app_version']}" do
  user   'vagrant'
  action :install
end

rvm_gemset "#{node['rvm']['app_gemset']}" do
  ruby_string "#{node['rvm']['app_version']}"
  user   'vagrant'
  action :create
end

rvm_default_ruby "#{node['rvm']['app_version']}@#{node['rvm']['app_gemset']}" do
  user   'vagrant'
  action :create
end
