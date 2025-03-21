#!/usr/bin/env bash
# Fail on any error
set -e

# Set version info
export BOX_VERSION_BASE="1.6.0"
export UBUNTU_2204_BASE_VERSION="22.04.5"
export UBUNTU_2204_BASE_ISO="ubuntu-${UBUNTU_2204_BASE_VERSION}-live-server-amd64.iso"
export UBUNTU_2204_BASE_ISO_SHA256="9bc6028870aef3f74f4e16b900008179e78b130e6b0b9a140635434a46aa98b0"

# Set versions requested of main components (These will be used in Packer and passed to Ansible downstream)
export ANSIBLE_VERSION="10.7.0"
export VBOXADD_VERSION="7.1.6"

# Set versions of supported tools, if they don't match, a warning will be shown on screen
export VIRTUALBOX_VERSION="7.1.6r167084"
export PACKER_VERSION="v1.12.0"
export VAGRANT_VERSION="2.4.3"

# Set the Vagrant cloud user and box name (make sure you have admin permissions to, or are the owner of this repository)
export VAGRANT_CLOUD_BOX_USER="ilionxde"
export VAGRANT_CLOUD_BOX_NAME="ubuntu2204"

# ############################################################################################## #
# Below this point there should be no need to edit anything, unless you know what you are doing! #
# ############################################################################################## #

# Generate the final version of the box, adding the date string of today
BOX_VERSION=${BOX_VERSION_BASE}-$(date +'%Y%m%d')
export BOX_VERSION

echo "Testing if all required tools are installed, please wait..."

# Check if all required tools are installed
if ( ! ( vboxmanage --version >/dev/null 2>&1 && packer version >/dev/null 2>&1 && vagrant version >/dev/null 2>&1 ) )
then
    echo "ERROR: One of the required tools (VirtualBox, Vagrant, and Packer) is not installed. Cannot continue."
    exit 1
fi

# Check the tool versions
INSTALLED_VIRTUALBOX_VERSION=$(vboxmanage --version)
INSTALLED_PACKER_VERSION=$(packer --version | awk '{print $2}')
INSTALLED_VAGRANT_VERSION=$(vagrant --version | awk '{print $2}')

if [[ "$INSTALLED_VIRTUALBOX_VERSION" != "$VIRTUALBOX_VERSION" || "$INSTALLED_PACKER_VERSION" != "$PACKER_VERSION" || "$INSTALLED_VAGRANT_VERSION" != "$VAGRANT_VERSION" ]]
then
    echo "WARNING: One of the tool versions does not match the tested versions. Your mileage may vary..."
    echo " * Using VirtualBox version ${INSTALLED_VIRTUALBOX_VERSION} (tested with version ${VIRTUALBOX_VERSION})"
    echo " * Using Packer version ${INSTALLED_PACKER_VERSION} (tested with version ${PACKER_VERSION})"
    echo " * Using Vagrant version ${INSTALLED_VAGRANT_VERSION} (tested with version ${VAGRANT_VERSION})"
    echo ""
    echo -n "To break, press Ctrl-C now, otherwise press Enter to continue"
    read -r
fi

echo "All required tools found. Continuing."

# Check if a build.env file is present, and if so: source it
if [ -f build.env ]
then
    source build.env
fi

# Check if the variables HCP_CLIENT_ID and HCP_CLIENT_SECRET have been set, if not ask for them
if [ -z "$DEFAULT_HCP_CLIENT_ID" ] || [ -z "$DEFAULT_HCP_CLIENT_SECRET" ]
then
    # Ask user for vagrant cloud token
    echo -n "What is your HCP Service Principal Client ID? "
    read -r user
    echo ""
    export HCP_CLIENT_ID=${user}

    # Ask user for vagrant cloud token
    echo -n "What is your HCP Service Principal Client Secret? "
    read -rs token
    echo ""
    export HCP_CLIENT_SECRET=${token}
else
    export HCP_CLIENT_ID=$DEFAULT_HCP_CLIENT_ID
    export HCP_CLIENT_SECRET=$DEFAULT_HCP_CLIENT_SECRET

    echo "Your HCP Client ID and Secret have been sourced from file build.env"
fi

# Export dynamic versioning info
commit=$(git --no-pager log -n 1 --format="%H")
BOX_VERSION_DESCRIPTION="
## Description
This base box is based on a clean Ubuntu 22.04 minimal install.

The box defaults to 1 CPU and 1GB of RAM, it is not advised to limit this.

---

## Versions included in this release
* Latest OS updates installed at build time
* ansible ${ANSIBLE_VERSION}
* VirtualBox guest additions ${VBOXADD_VERSION}

---

$(cat CHANGELOG.md)

---

## Source info
[View source on Github](https://github.com/Q24/vagrant-box-ubuntu2204)

Built on commit: \`${commit}\`
"

export BOX_VERSION_DESCRIPTION
echo "${BOX_VERSION_DESCRIPTION}"

# Install necessary packer plugins
echo "Installing packer plugins: virtualbox, ansible, and vagrant"
packer plugins install github.com/hashicorp/virtualbox
packer plugins install github.com/hashicorp/ansible
packer plugins install github.com/hashicorp/vagrant

# Validate build config
echo "Validating build json files"
packer validate packer.json

# Run the actual build
echo "Building box version ${BOX_VERSION}"
packer build -force -on-error=cleanup packer.json

# Tag git commit for this build
git tag -a "${BOX_VERSION}" -m "Version ${BOX_VERSION} built."