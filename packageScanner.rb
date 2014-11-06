#!/usr/bin/ruby

require "pry"

$LOAD_PATH.unshift("~/apps/chef/lib/chef")
require "~/apps/chef/lib/chef.rb"

a = Chef::CookbookLoader.new "chef-bcpc/cookbooks"

a.load_cookbook("bcpc")

Chef::Config[:role_path] = "/home/jimmacarthur/bloomberg/chef-bcpc-bootstrap/chef-bcpc/roles"

class FakePackage
  def initialize(name, block)
    print "Package #{name}: "
    if block == nil
      print "Plain package, no block.\n"
    else
      print "block supplied.\n"      
      self.instance_eval &block
    end
  end
  def action(action_arg)
    print "Package action: #{action_arg}\n"
  end
end

class FakeRecipe
  def initialize
  end
  def include_recipe(recipe_name)
    print "Fake include_recipe: #{recipe_name}\n"
  end
  def package(package_name, &block)
    print "Package: #{package_name}\n"
    p = FakePackage.new package_name,block
  end
  def template(template_name)
    print "Template: #{template_name}\n"
  end
  def service(service_name)
    print "Service: #{service_name}\n"
  end
  def from_file(filename)
    node=Chef::Node.new
    node['bcpc']['enabled']['apt_upgrade'] = true
    self.instance_eval(IO.read(filename), filename, 1)
  end
  def bash(script_name, &block)
    print "Bash script: #{script_name}\n"
    # Ignore these for now
  end
  def apt_repository(repo_name, &block)
    print "APT repository: #{repo_name}\n"
  end
end


def process_recipe(cookbook, recipe_name)
  potential_file_name = "/home/jimmacarthur/bloomberg/chef-bcpc-bootstrap/chef-bcpc/cookbooks/#{cookbook}/recipes/#{recipe_name}.rb"

  if File::exists? potential_file_name
    print "Scanning: #{potential_file_name}\n"
    fr = FakeRecipe.new
    fr.from_file potential_file_name
  else
    print "Warning: #{potential_file_name} does not exist (Probably not a BCPC recipe)\n"
  end

end

def iterate_role(roleName)
  print "Enumerating role #{roleName}\n"
  c = Chef::Role::from_disk roleName
  for r in c.recipes
    if r.role?
      iterate_role(r.name)
    else
      (cookbook, recipe_name) = Chef::Recipe::parse_recipe_name r.name
      print "#{roleName}: Cookbook #{cookbook}, recipe #{recipe_name}\n"
      process_recipe(cookbook, recipe_name)
    end
  end
end


iterate_role("BCPC-Worknode")

# Debugging/testing



#c = Chef::Role::from_disk "BCPC-Worknode"
#binding.pry
