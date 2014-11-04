#!/bin/bash

machines="bcpc-vm1 bcpc-vm2 bcpc-vm3 bcpc-bootstrap"

# delete any existing machines.
for i in $machines; do
vboxmanage controlvm $i poweroff
done
sleep 5

for i in $machines; do
vboxmanage unregistervm $i --delete
done
