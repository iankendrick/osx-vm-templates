#!/bin/sh

# Install the latest Puppet and Facter using AutoPkg recipes
# https://github.com/autopkg/autopkg
#
# PUPPET_VERSION and FACTER_VERSION can be overridden with specific versions,
# or "latest" to get the latest stable versions

PUPPET_VERSION=${PUPPET_VERSION:-latest}
FACTER_VERSION=${FACTER_VERSION:-latest}

# install function mostly borrowed dmg function from hashicorp/puppet-bootstrap,
# except we just take an already-downloaded dmg
function install_dmg() {
    local name="$1"
    local dmg_path="$2"

    echo "Installing: ${name}"

    # Mount the DMG
    echo "-- Mounting DMG..."
    tmpmount=$(/usr/bin/mktemp -d /tmp/puppet-dmg.XXXX)
    hdiutil attach "${dmg_path}" -mountpoint "${tmpmount}"

    echo "-- Installing pkg..."
    pkg_path=$(find "${tmpmount}" -name '*.pkg' -mindepth 1 -maxdepth 1)
    installer -pkg "${pkg_path}" -tgt /

    # Unmount
    echo "-- Unmounting and ejecting DMG..."
    hdiutil eject "${tmpmount}"
}

function get_dmg() {
    local recipe_name="$1"
    local version="$2"

    # Run AutoPkg setting VERSION, and saving the results as a plist
    "${AUTOPKG}" run --report-plist ${recipe_name} -k VERSION="${version}" > /tmp/autopkg-puppet-report.plist
    echo $(/usr/libexec/PlistBuddy -c 'Print :new_downloads:0' /tmp/autopkg-puppet-report.plist)
}

# Get AutoPkg
AUTOPKG_DIR=$(mktemp -d /tmp/autopkg-XXXX)
git clone https://github.com/autopkg/autopkg "$AUTOPKG_DIR"
AUTOPKG="$AUTOPKG_DIR/Code/autopkg"

# Add the recipes repo containing Puppet/Facter
"${AUTOPKG}" repo-add recipes

# Retrieve the installer DMGs
PUPPET_DMG=$(get_dmg Puppet.download "${PUPPET_VERSION}")
FACTER_DMG=$(get_dmg Facter.download "${FACTER_VERSION}")

# Install them
install_dmg "Puppet" "${PUPPET_DMG}"
install_dmg "Facter" "${FACTER_DMG}"

# Hide all users from the loginwindow with uid below 500, which will include the puppet user
defaults write /Library/Preferences/com.apple.loginwindow Hide500Users -bool YES

# Clean up
rm -rf "${PUPPET_DMG}" "${FACTER_DMG}" "~/Library/AutoPkg"
