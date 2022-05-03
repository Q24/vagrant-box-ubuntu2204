# Creating a new box release

To create a new box release, do the following:

## Prepare build environment

Check [README.md](README.md) to install all necessary tools and configurations to set up your local build environment.

## Update build.sh

* Update `BOX_VERSION_BASE` to a new version, use the semantic versioning scheme.
* Check if there is a new [Ubuntu server](https://ubuntu.com/download/server) release, if so update `UBUNTU_2204_BASE_VERSION`, `UBUNTU_2204_BASE_ISO`, and `UBUNTU_2204_BASE_ISO_SHA256`.
* Check if there is a new [Ansible](https://pypi.org/project/ansible/) release, if so update `ANSIBLE_VERSION`.
* Check if there is a new [VirtualBox](https://download.virtualbox.org/virtualbox) guest additions release, if so update `VBOXADD_VERSION`.
* Check your local tools versions, and update `VIRTUALBOX_VERSION`, `PACKER_VERSION`, and `VAGRANT_VERSION` accordingly.

## Update CHANGELOG.md

Create a new section in [CHANGELOG.md](CHANGELOG.md) with the new box version you have just created. The final version  tag will be `BOX_VERSION_BASE-YYYYMMDD` with `YYYYMMDD` being today's date (at the time of running `build.sh`).

In this section, add bullets for every item you have changed in the release.

## Update README.md

Check [README.md](README.md) under Prerequisites, check if you need to update the tool versions for VirtualBox, Packer and Vagrant in you used new versions to create the build.

## Commit your changes

If you are satisfied with all changes made to all files, commit your changes in git but do not push them yet.

```shell
git commit -am "New box version: BOX_VERSION_BASE-YYYYMMDD."
```

Be sure to replace the commit message with the actual box version.

## Run build.sh

Run `build.sh` to create the actual build.

This will create the base box and updload it to Vagrant, but will not publish it yet. It will incorporate the git commit you have just made in the documentation so the build can be reproduced.

## Push the code and publish the release

If you are happy with your new build, do the following:

Push your git commit and tag to GitHub:

```shell
git push
git push origin BOX_VERSION_BASE-YYYYMMDD
```

Log into Vagrant and publish the box you have just uploaded.

Finally, in GitHub, create a release based on the tag you have just pushed, copying the section you have added in [CHANGELOG.md](CHANGELOG.md) as the release notes.

## Failed build or changes needed

Should the build fail, or if you want to make changes, do the following:

* Delete the uploaded and unreleased box from Vagrant.
* If it had been created, delete the tag in your local git repository created by `build.sh`.
* Change anything as you so wish.
* Git `commit --amend` to update your previous commit.
* Run `build.sh` to build again.
* If you are happy with this build, push your code as normal, or re-run these steps until you are happy.