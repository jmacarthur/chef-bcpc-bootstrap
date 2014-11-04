#!/bin/bash

# Starts the Bloomberg BCPC chef script.


# Add prerequisite software:
#apt-get install virtualbox vagrant

# Default install of virtualbox on Linux doesn't have a host-only network, so add one. You can do this using the
# GUI interface, or using:
# vboxmanage hostonlyif create

# delete any existing machines.
for i in bcpc-vm1 bcpc-vm2 bcpc-vm3 bcpc-bootstrap; do
vboxmanage controlvm $i poweroff
vboxmanage unregistervm $i --delete
done


git clone https://github.com/bloomberg/chef-bcpc.git
pushd chef-bcpc

# Reduce the amount of memory used by VMs, so this setup can run on my
# laptop
#sed -i -e 's/^CLUSTER_VM_MEM=.*$/CLUSTER_VM_MEM=1024/' vbox_create.sh

vagrant init
./vbox_create.sh

# We should now be able to:
#vagrant ssh -c "sed -i -e 's/\(actual\|expected\):/\1 => /' /home/vagrant/chef-bcpc/cookbooks/logrotate/libraries/matchers.rb"

# And continue? ./vbox_create would have called ./bootstrap_chef.sh and then
# ./enroll-cobbler.sh. Which of these do we want to run?

# It's bootstrap_chef.sh which would have had problems with ruby, so we restart this:
#./bootstrap_chef.sh  --vagrant-remote 10.0.100.3 Test-Laptop
#./enroll_cobbler.sh

# Now, boot each of the machines in sequence (all at once might overload your host)
VBoxManage startvm bcpc-vm1
sleep 600
VBoxManage startvm bcpc-vm2
sleep 600
VBoxManage startvm bcpc-vm3
sleep 600

# Connect to the bootstrap machine:
# vagrant ssh
# cd chef-bcpc

# Get the root password:
# knife data bag show configs Test-Laptop | grep cobbler-root-password: | sed -e 's/^.*: *//'
# ssh-keygen
# ssh-copy-id ubuntu@10.0.100.11
# ssh ubuntu@10.0.100.11
# sudo visudo
# (Add ubuntu ALL=NOPASSWD: ALL)
# exit

# so, how would we automate this? Is it something we should be able to do with chef?

# libnova patches - this section should no longer be necessary with latest chef-bcpc.

## Now use web interface https://10.0.100.3:4000/ to edit the "Test-Laptop" Environment and add the field "openstack_branch" : "updates" to json['overrides']['bcpc'].
## That is, click on "Environments", then "Test-Laptop", then "Edit", Expand the 'json' tree, then 'overrides' and click on 'bcpc'. Edit the text in the text box to add the field "openstack_branch" : "updates" to the hash. Now click "Save Attribute", "Yes" when asked to rebuild the tree, and then "Update Environment".
## OR: EDITOR=nano knife environment edit Test-Laptop

# Optionally (this is not tested) edit /opt/chef/embedded/lib/ruby/gems/1.9.1/gems/mixlib-shellout-1.4.0/lib/mixlib/shellout.rb on bcpc-bootstrap, and change DEFAULT_READ_TIMEOUT to 3600. This may be copied to 10.0.100.11, or not.


# Now:
#sudo knife bootstrap -E Test-Laptop -r 'role[BCPC-Headnode]' 10.0.100.11 -x ubuntu --sudo

# This will fail in a few minutes. Use the web interface to make the newly created machine an admin: Clients->bcpc-vm1.local.lan, click Edit, tick 'Admin' and 'Save Client'.
# OR:  EDITOR=nano knife client edit bcpc-vm1.local.lan and change 'admin' to 'true'.
