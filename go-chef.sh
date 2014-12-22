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


git clone ssh://git@git.codethink.co.uk/people/jimmacarthur/bcpc
pushd chef-bcpc

vagrant init

# Enable VBox headless mode
sed -i -e 's/vb.gui = true/vb.gui = false/' Vagrantfile

./vbox_create.sh

# OK, now we modify the files present...

# We should now be able to:
#vagrant ssh -c "sed -i -e 's/\(actual\|expected\):/\1 => /' /home/vagrant/chef-bcpc/cookbooks/logrotate/libraries/matchers.rb"

# And continue? ./vbox_create would have called ./bootstrap_chef.sh and then
# ./enroll-cobbler.sh. Which of these do we want to run?

# It's bootstrap_chef.sh which would have had problems with ruby, so we restart this:
#./bootstrap_chef.sh  --vagrant-remote 10.0.100.3 Test-Laptop
#./enroll_cobbler.sh

# Now, boot each of the machines in sequence (all at once might overload your host)
vboxmanage startvm bcpc-vm1 --type headless
sleep 300
vboxmanage startvm bcpc-vm2 --type headless
sleep 300
vboxmanage startvm bcpc-vm3 --type headless
sleep 800

passwd=`vagrant ssh -c "cd chef-bcpc && knife data bag show configs Test-Laptop | grep cobbler-root-password: | sed -e 's/^.*: *//'"`

# Make us a private key set 
rm -f ceph-cluster-key.pub ceph-cluster-key
ssh-keygen -f "ceph-cluster-key" -N ""
ssh-keygen -f ~/.ssh/known_hosts -R 10.0.100.11
ssh-keygen -f ~/.ssh/known_hosts -R 10.0.100.12
ssh-keygen -f ~/.ssh/known_hosts -R 10.0.100.13
# Unfortunately, this keeps prompting for ID...
echo "Bootstrapping worker nodes using password $passwd"
../ssh-bootstrap.py $passwd ceph-cluster-key.pub 10.0.100.11
../ssh-bootstrap.py $passwd ceph-cluster-key.pub 10.0.100.12
../ssh-bootstrap.py $passwd ceph-cluster-key.pub 10.0.100.13
sshopts="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o BatchMode=Yes -i ceph-cluster-key"
ssh $sshopts ubuntu@10.0.100.11 "echo $passwd | sudo -S bash -c \"echo \\\"ubuntu    ALL=NOPASSWD:ALL\\\" >> /etc/sudoers\""
ssh $sshopts ubuntu@10.0.100.12 "echo $passwd | sudo -S bash -c \"echo \\\"ubuntu    ALL=NOPASSWD:ALL\\\" >> /etc/sudoers\""
ssh $sshopts ubuntu@10.0.100.13 "echo $passwd | sudo -S bash -c \"echo \\\"ubuntu    ALL=NOPASSWD:ALL\\\" >> /etc/sudoers\""

# Now we need to copy that key to the bootstrap machine...
mv ceph-cluster-key vbox/
vagrant ssh -c "mkdir -p ~/.ssh && mv /vagrant/ceph-cluster-key ~/.ssh/id_rsa"

# libnova patches - this section should no longer be necessary with latest chef-bcpc.

## Now use web interface https://10.0.100.3:4000/ to edit the "Test-Laptop" Environment and add the field "openstack_branch" : "updates" to json['overrides']['bcpc'].
## That is, click on "Environments", then "Test-Laptop", then "Edit", Expand the 'json' tree, then 'overrides' and click on 'bcpc'. Edit the text in the text box to add the field "openstack_branch" : "updates" to the hash. Now click "Save Attribute", "Yes" when asked to rebuild the tree, and then "Update Environment".
## OR: EDITOR=nano knife environment edit Test-Laptop

# Optionally (this is not tested) edit /opt/chef/embedded/lib/ruby/gems/1.9.1/gems/mixlib-shellout-1.4.0/lib/mixlib/shellout.rb on bcpc-bootstrap, and change DEFAULT_READ_TIMEOUT to 3600. This may be copied to 10.0.100.11, or not.

# Now:
#sudo knife bootstrap -E Test-Laptop -r 'role[BCPC-Headnode]' 10.0.100.11 -x ubuntu --sudo

# This will fail in a few minutes. Use the web interface to make the newly created machine an admin: Clients->bcpc-vm1.local.lan, click Edit, tick 'Admin' and 'Save Client'.
# OR:  EDITOR=nano knife client edit bcpc-vm1.local.lan and change 'admin' to 'true'.
