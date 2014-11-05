#!/usr/bin/ruby

require "pry"

$LOAD_PATH.unshift("~/apps/chef/lib/chef")
require "~/apps/chef/lib/chef.rb"

a = Chef::CookbookLoader.new "chef-bcpc/cookbooks"

a.load_cookbook("bcpc")

Chef::Config[:role_path] = "/home/jimmacarthur/bloomberg/chef-bcpc-bootstrap/chef-bcpc/roles"

def process_recipe(r)
  # Scan for packages
end

def iterate_role(roleName)
  print "Enumerating role #{roleName}\n"
  c = Chef::Role::from_disk roleName
  for r in c.recipes
    if r.role?
      iterate_role(r.name)
    else
      print "#{roleName}: #{r}\n"
      process_recipe(r)
    end
  end
end


iterate_role("BCPC-Worknode")



# Debugging/testing
c = Chef::Role::from_disk "BCPC-Worknode"
binding.pry

