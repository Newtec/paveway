#!/bin/bash
 
 
[[ $# == 0 ]] && echo "Usage: $0 [ssh-args] user@hostname" && exit 1
 
ssh-keygen -R $@
ssh-keyscan -H $@ >> ~/.ssh/known_hosts
sshpass -p 'f00' ssh-copy-id $@  -o StrictHostKeyChecking=no || sshpass -p 'bar' ssh-copy-id $@  -o StrictHostKeyChecking=no
[[ $? -ne 0 ]] && echo "Connect failed, can't continue" && exit 2
 
ssh $@
