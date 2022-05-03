#!/bin/sh -eux

# This is based on the bento Vagrant boxes, taken from:
# https://github.com/chef/bento/blob/main/packer_templates/_common/minimize.sh

# The general idea (tm) is:
# 1. Count how many MB's are free in each file system
# 2. Write a file of this many MB's full of zeroes in a temporary location in that file system (using the file system
# itself make sure that any existing blocks no longer referenced by files get overwritten with zeroes,
# i.e. basically a poor man's zerofree while the file system is still mounted read/write), all the way until the
# file system is full, ignoring any errors cause by "No space left on device"
# 3. Delete this temporary file again, leaving a file system with real files in use and all the rest zeroed out

# Count the free space in the / file system
count=$(df --sync -kP / | tail -n1  | awk -F ' ' '{print $4}')
# Remove 1 from this space, to leave some room for other files being written at the same time
count=$(($count-1))
# Creat a dummy file in the file system with all zeroes
dd if=/dev/zero of=/tmp/whitespace bs=1M count=$count || echo "dd exit code $? is suppressed"
# Remove this file again
rm /tmp/whitespace

# Flush to disk a few times
sync
sync
sync