#!/bin/bash
set -x
whoami
# Home directory of ~/.ssh did not work for CF as it reaches /hom/vcap/app/.ssh. Hence this hardcoding for now
ssh_dir='/home/vcap/.ssh'
# ssh_dir='~/.ssh'

mkdir -p ${ssh_dir}

eval `ssh-agent -s`
ssh-add ./pr_test
touch ${ssh_dir}/known_hosts
ssh-keyscan -t rsa github.com >> ${ssh_dir}/known_hosts
ssh-keygen -l -F github.com

ls #{ssh_dir}
pr_no=$1
rm -rf ../log_${pr_no}
git clone git@github.com:divyabhargov/test.git log_${pr_no}
cd log_${pr_no}
git log | grep -B 4 "Updated PR number to ${pr_no}" | grep commit

rm -rf ../log_${pr_no}
