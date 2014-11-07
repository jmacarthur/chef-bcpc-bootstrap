#!/usr/bin/ruby

require "pry"

$LOAD_PATH.unshift("~/apps/chef/lib/chef")
require "~/apps/chef/lib/chef.rb"

a = Chef::CookbookLoader.new "chef-bcpc/cookbooks"

a.load_cookbook("bcpc")

Chef::Config[:role_path] = "/home/jimmacarthur/bloomberg/chef-bcpc-bootstrap/chef-bcpc/roles"

$packages = []
$indent = 0
$included_already = []

class FakePackage
  attr_reader :name, :versionText
  def initialize(name, block)
    @versionText = "default"
    @name = name
    print "Package #{name}: "
    if block == nil
      print "Plain package, no block.\n"
    else
      print "block supplied.\n"      
      self.instance_eval &block
    end
    $packages << self
  end
  def action(action_arg)
    print "Package action: #{action_arg}\n"
  end
  def version(version_arg)
    print "Package action: #{version_arg}\n"
    @versionText = version_arg
  end
  def method_missing(name, *args, &block)
    puts "Unknown method in package (probably from recipe): %s" % name
  end
end

class FakeRecipe
  def initialize
  end
  def package(package_name, &block)
    print "Package: #{package_name}\n"
    p = FakePackage.new package_name,block
  end
  def get_ceph_osd_nodes
    return []
  end
  def get_head_nodes
    return []
  end
  def get_cached_head_node_names
    return []
  end
  def get_all_nodes
    return []
  end
  def include_recipe(recipe_spec)
    
    # include this
    (cookbook, recipe_name) = Chef::Recipe::parse_recipe_name recipe_spec
    print " "*$indent,"Recursing into included recipe #{cookbook}::#{recipe_name}\n"
    $indent += 1
    process_recipe(cookbook, recipe_name)
    $indent -= 1
    print " "*$indent,"Recursing out\n"
  end
  def from_file(filename)
    json = JSON.parse (IO.read("FakeNode.json"))

    nodeX = Chef::Node.json_create(json)

    node = nodeX.default
    node['bcpc']['enabled']['apt_upgrade'] = true
    default = nodeX.default

    # Attempt to read all the default attributes into our node
    self.instance_eval(IO.read("/home/jimmacarthur/bloomberg/chef-bcpc-bootstrap/chef-bcpc/cookbooks/bcpc/attributes/default.rb"))

    # Hacks
    node['network']['interfaces']['eth0']['addresses'] = { "10.0.100.11" => { "family" => "inet" } }
    node['bcpc']['management']['ip'] =  "10.0.100.11"

    self.instance_eval(IO.read(filename), filename, 1)
  end
  def method_missing(name, *args, &block)
    puts "Unknown method (probably from recipe): %s" % name
  end
end


def process_recipe(cookbook, recipe_name)
  
  potential_file_name = "/home/jimmacarthur/bloomberg/chef-bcpc-bootstrap/chef-bcpc/cookbooks/#{cookbook}/recipes/#{recipe_name}.rb"

  if $included_already.include? potential_file_name
    print "#{potential_file_name} has been included already, so it's ignored\n"
    return
  end

  if File::exists? potential_file_name
    print "Scanning: #{potential_file_name}\n"
    fr = FakeRecipe.new
    $included_already << potential_file_name
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


iterate_role("BCPC-Headnode")

print "Final list of packages:\n"
for p in $packages
    print "#{p.name}: #{p.versionText}\n"
end

# Debugging/testing

#c = Chef::Role::from_disk "BCPC-Worknode"
#binding.pry
