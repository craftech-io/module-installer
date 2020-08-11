#!/bin/bash
#
# Some basic automated tests for craftech-installer

set -e

readonly LOCAL_INSTALL_URL="file:///src/craftech-install"

echo "Using local copy of bootstrap installer to install local copy of craftech-install"
./src/bootstrap-craftech-installer.sh --download-url "$LOCAL_INSTALL_URL" --version "ignored-for-local-install" --no-sudo "true"

echo "Using craftech-install to install a binary from the gruntkms repo into a different folder without using sudo"
craftech-install \
  --binary-name "gruntkms" \
  --repo "https://github.com/craftech-io/gruntkms" \
  --tag "v0.0.1" \
  --binary-install-dir "$HOME" \
  --no-sudo "true"

echo "Checking that gruntkms installed correctly into home dir"
"$HOME/gruntkms" --help
