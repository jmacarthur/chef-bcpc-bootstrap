#!/usr/bin/python

import paramiko
import sys

if len(sys.argv) != 4:
    print "Usage: ssh-bootstrap.py <password> <public key file> <ip address>"
    exit(1)

publicKeyFile = open(sys.argv[2])
publicKey = publicKeyFile.read().strip()
print "Public key: "+publicKey

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(sys.argv[3].strip(), password=sys.argv[1].strip(), username='ubuntu')
command = "mkdir -p ~/.ssh && bash -c \"echo %s >> ~/.ssh/authorized_keys\"" % publicKey
print "Executing command: "+command
stdin, stdout, stderr = client.exec_command(command)
print stdout.readlines()

