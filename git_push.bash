#!/bin/bash
set -e
set -x

whoami
# Home directory of ~/.ssh did not work for CF as it reaches /hom/vcap/app/.ssh. Hence this hardcoding for now
ssh_dir='/home/vcap/.ssh'
mkdir -p ${ssh_dir}

eval `ssh-agent -s`
ssh-add ./pr_test
touch ${ssh_dir}/known_hosts
ssh-keyscan -t rsa github.com >> ${ssh_dir}/known_hosts
ssh-keygen -l -F github.com

ls #{ssh_dir}
pr_no=$1
git clone git@github.com:divyabhargov/test.git test_${pr_no}
echo ${pr_no} > test_${pr_no}/pr.txt
cd test_${pr_no} && git add pr.txt
git config --global user.email "dbhargov.pivotal.io"
git config --global user.name "PR Test"
msg="Updated PR number to ${pr_no}" 
git commit -m "${msg}"
git push origin master
rm -rf ../test_${pr_no}
