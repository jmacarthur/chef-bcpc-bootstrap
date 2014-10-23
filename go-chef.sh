#!/bin/sh

# Starts the Bloomberg BCPC chef script.


# delete any existing machines.
for i in bcpc-vm1 bcpc-vm2 bcpc-vm3 bcpc-bootstrap; do
vboxmanage controlvm $i poweroff
vboxmanage unregistervm $i --delete
done

git clone https://github.com/bloomberg/chef-bcpc.git
pushd chef-bcpc
./vbox_create.sh

