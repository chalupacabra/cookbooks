#
# Cookbook Name:: users
# Recipe:: default
#
# Copyright 2009-2011, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

sysadmin_group = Array.new

users = data_bag('users')

users.each do |user|

  u = data_bag_item('users', user)

  if u['groups'].include?('sysadmin')
    sysadmin_group << u['id']
  end

  home_dir = "/home/#{u['id']}"

  # fixes CHEF-1699
  ruby_block "reset group list" do
    block do
      Etc.endgrent
    end
    action :nothing
  end

  user u['id'] do
    uid u['uid']
    gid u['gid']
    shell u['shell']
    comment u['comment']
    supports :manage_home => true
    home home_dir
    notifies :create, "ruby_block[reset group list]", :immediately
  end

  directory "#{home_dir}/.ssh" do
    owner u['id']
    group u['gid'] || u['id']
    mode "0700"
  end

  template "#{home_dir}/.ssh/authorized_keys" do
    source "authorized_keys.erb"
    owner u['id']
    group u['gid'] || u['id']
    mode "0600"
    variables :ssh_keys => u['ssh_keys']
  end
  
  execute "Validate password expiration disabled for #{u['id']}" do
    command "chage -I -1 -m 0 -M 99999 -E -1 #{u['id']}"
    not_if "egrep ^#{u['id']}: /etc/shadow |cut -d: -f5 |egrep ^99999$"
  end

end

group "sysadmin" do
  members sysadmin_group
end
