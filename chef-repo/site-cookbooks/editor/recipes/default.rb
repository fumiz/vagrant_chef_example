#
# Cookbook Name:: editor
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

package 'vim' do
  action :install
end

cookbook_file "#{ENV['HOME']}/.vimrc" do
  action :create
  source '.vimrc'
end

cookbook_file '/home/vagrant/.vimrc' do
  action :create
  source '.vimrc'
  user 'vagrant'
  group 'vagrant'
end
