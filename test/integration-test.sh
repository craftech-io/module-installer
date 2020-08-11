#!/bin/bash
#
# Some basic automated tests for craftech-installer

set -e

readonly LOCAL_INSTALL_URL="file:///src/craftech-install"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Using local copy of bootstrap installer to install local copy of craftech-install"
./src/bootstrap-craftech-installer.sh --download-url "$LOCAL_INSTALL_URL" --version "ignored-for-local-install"

echo "Using craftech-install to install a module from the module-ecs repo"
craftech-install --module-name "ecs-scripts" --repo "https://github.com/craftech-io/module-ecs" --branch "v0.0.1"

echo "Using craftech-install to install a module from the module-ecs repo with --download-dir option"
craftech-install --module-name "ecs-scripts" --repo "https://github.com/craftech-io/module-ecs" --branch "v0.0.1" --download-dir ~/tmp

echo "Checking that the ecs-scripts installed correctly"
configure-ecs-instance --help

echo "Using craftech-install to install a module from the craftech-install repo and passing args to it via --module-param"
craftech-install --module-name "dummy-module" --repo "https://github.com/craftech-io/craftech-installer" --tag "v0.0.25" --module-param "file-to-cat=$SCRIPT_DIR/integration-test.sh"

echo "Using craftech-install to install a test module from the craftech-install repo and test that it's args are maintained via --module-param"
craftech-install --module-name "args-test" --repo "https://github.com/craftech-io/craftech-installer" --tag "v0.0.25" --module-param 'test-args=1 2 3 *'

echo "Using craftech-install to install a binary from the gruntkms repo"
craftech-install --binary-name "gruntkms" --repo "https://github.com/craftech-io/gruntkms" --tag "v0.0.1"

echo "Checking that gruntkms installed correctly"
gruntkms --help

echo "Unsetting GITHUB_OAUTH_TOKEN to test installing from public repo (terragrunt)"
unset GITHUB_OAUTH_TOKEN

echo "Verifying private repo access is denied"
if craftech-install --binary-name "gruntkms" --repo "https://github.com/craftech-io/gruntkms" --tag "v0.0.1" ; then
  echo "ERROR: was able to access private repo"
  exit 1
fi

echo "Verifying public repo access is allowed"
craftech-install --repo 'https://github.com/craftech-io/terragrunt' --binary-name terragrunt --tag '~>v0.21.0'

echo "Checking that terragrunt installed correctly"
terragrunt --help
