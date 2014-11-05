#!/usr/bin/ruby

require "pry"

$LOAD_PATH.unshift("~/apps/chef/lib/chef")
require "chef.rb"

a = Chef::CookbookLoader.new "chef-bcpc/cookbooks"

a.load_cookbook("bcpc")

# Try loading a role

b = Chef::Role.new



c = Chef::Role::from_disk "BCPC-Worknode"

binding.pry
