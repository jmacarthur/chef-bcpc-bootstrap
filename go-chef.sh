#!/bin/bash

# Starts the Bloomberg BCPC chef script.


# delete any existing machines.
for i in bcpc-vm1 bcpc-vm2 bcpc-vm3 bcpc-bootstrap; do
vboxmanage controlvm $i poweroff
vboxmanage unregistervm $i --delete
done


git clone https://github.com/bloomberg/chef-bcpc.git
pushd chef-bcpc

# Reduce the amount of memory used by VMs, so this setup can run on my
# laptop
sed -i -e 's/^CLUSTER_VM_MEM=.*$/CLUSTER_VM_MEM=1024/' vbox_create.sh

vagrant init
./vbox_create.sh

# If vagrant is installed, this will proceed to set up bcpc-bootstrap.
# Currently it'll fail due to the Ruby version bug. Can we fix this?

# We should now be able to:
vagrant ssh -c "sed -i -e 's/\(actual\|expected\):/\1 => /' /home/vagrant/chef-bcpc/cookbooks/logrotate/libraries/matchers.rb"

# And continue? ./vbox_create would have called ./bootstrap_chef.sh and then
# ./enroll-cobbler.sh. Which of these do we want to run?

# It's bootstrap_chef.sh which would have had problems with ruby, so we restart this:
./bootstrap_chef.sh  --vagrant-remote 10.0.100.3 Test-Laptop
./enroll_cobbler.sh

# Now, boot each of the machines in sequence (all at once might overload your host)
# VBoxManage startvm bcpc-vm1
# VBoxManage startvm bcpc-vm2
# VBoxManage startvm bcpc-vm3

# Connect to the bootstrap machine:
# vagrant ssh

# set up passwords for 10.0.100.11. You'll need the original password, accessible from http://10.0.100.3/ - log into the web interface using admin/p@ssw0rd1.
# ssh-keygen
# ssh-copy-id ubuntu@10.0.100.11
# ssh ubuntu@10.0.100.11 sudo visudo
# (Add ubuntu ALL=NOPASSWD: ALL)

# Now:
#sudo knife bootstrap -E Test-Laptop -r 'role[BCPC-Headnode]' 10.0.100.11 -x ubuntu --sudo

# But this will have the same problem we had before.




