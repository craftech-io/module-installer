[![Maintained by Module.io](https://img.shields.io/badge/maintained%20by-module.io-%2254BEC5.svg?color=54BEC5)](https://module.io/?ref=ci-tools)
# Module Installer

`module-install` is a fork from [Gruntwork Installer](https://github.com/gruntwork-io/gruntwork-installer) bash script you run to easily download and install Terraform modules that follow an specific folder structure.

## Compatibility

Tested under CentOS 7, latest Amazon Linux and Ubuntu 16.04.

## Quick Start

### Install module-install

If `module-install` is our approach for installing Module Modules, how do we install `module-install` itself?

Our solution is to make the `module-install` tool open source and to publish a `bootstrap-module-installer.sh`
script that anyone can use to install `module-install` itself. To use it, execute the following:

```
curl -LsS https://raw.githubusercontent.com/craftech-io/module-installer/master/bootstrap-module-installer.sh | bash /dev/stdin --version v0.0.29
```

Notice the `--version` parameter at the end where you specify which version of `module-install` to install. See the
[releases](https://github.com/craftech-io/module-installer/releases) page for all available versions.

For paranoid security folks, see [is it safe to pipe URLs into bash?](#is-it-safe-to-pipe-urls-into-bash) below.

### Use module-install

#### Authentication

To install scripts and binaries from private GitHub repos, you must create a [GitHub access
token](https://help.github.com/articles/creating-an-access-token-for-command-line-use/) and set it as the environment
variable `GITHUB_OAUTH_TOKEN` so `module-install` can use it to access the repo:

```
export GITHUB_OAUTH_TOKEN="(your secret token)"
```

#### Options

Once that environment variable is set, you can run `module-install` with the following options:

Option                      | Required | Description
--------------------------- | -------- | ------------
`--repo`                    | Yes      | The GitHub repo to install from.
`--tag`                     | Yes      | The version of the `--repo` to install from.<br>Follows the syntax described at [Tag Constraint Expressions](https://github.com/craftech-io/fetch#tag-constraint-expressions).
`--module-name`             | XOR      | The name of a module to install.<br>Can be any folder within the `modules` directory of `--repo`.<br>You must specify exactly one of `--module-name` or `--binary-name`.
`--binary-name`             | XOR      | The name of a binary to install.<br>Can be any file uploaded as a release asset in `--repo`.<br>You must specify exactly one of `--module-name` or `--binary-name`.
`--binary-sha256-checksum`  | No       | The SHA256 checksum of the binary specified by `--binary-name`. Should be exactly 64 characters..
`--binary-sha512-checksum`  | No       | The SHA512 checksum of the binary specified by `--binary-name`. Should be exactly 128 characters..
`--module-param`            | No       | A key-value pair of the format `key=value` you wish to pass to the module as a parameter. May be used multiple times. <br>Note: a `--` will automatically be appended to the `key` when your module is invoked<br>See the documentation for each module to find out what parameters it accepts.
`--download-dir`            | No       | The directory to which the module will be downloaded and from which it will be installed.
`--branch      `            | No       | Download the latest commit from this branch in --repo. This is an alternative to --tag,<br>and is used only for testing.
`--help`                    | No       | Show the help text and exit.

#### Examples

##### Example 1: Download and Install a Script Module with No Parameters

Install the [install-rundeck
module](https://github.com/craftech-io/module-ci/tree/master/modules/install-rundeck) from the [module-ci
repo](https://github.com/craftech-io/module-ci), version `v0.0.1`:

```
module-install --module-name 'install-rundeck' --repo 'https://github.com/craftech-io/module-ci' --tag 'v0.0.1'
```

##### Example 2: Download and Install a Script Module with Parameters

Install the [install-rundeck
module](https://github.com/craftech-io/module-ci/tree/master/modules/install-rundeck) from the [module-ci
repo](https://github.com/craftech-io/module-ci), version `v0.0.1`:

```
module-install --module-name 'install-rundeck' --repo 'https://github.com/craftech-io/module-ci' --tag 'v0.0.1'
```


```
module-install --module-name 'install-rundeck' --repo 'https://github.com/craftech-io/module-ci' -module-param 'version=3.3.1.20200727-1'
```

##### Example 3: Use `module-install` in a Packer template

Finally, to put all the pieces together, here is an example of a Packer template that installs `module-install`
and then uses it to install several modules:

```json
{
  "variables": {
    "github_auth_token": "{{env `GITHUB_OAUTH_TOKEN`}}"
  },
  "builders": [
    {
      "ami_name": "module-install-example-{{isotime | clean_ami_name}}",
      "instance_type": "t2.micro",
      "region": "us-east-1",
      "type": "amazon-ebs",
      "source_ami": "ami-fce3c696",
      "ssh_username": "ubuntu"
    }
  ],
  "provisioners": [
    {
      "type": "shell",
      "inline":
        "curl -Ls https://raw.githubusercontent.com/craftech-io/module-installer/master/bootstrap-module-installer.sh | bash /dev/stdin --version v0.0.28"
    },
    {
      "type": "shell",
      "inline": [
        "module-install --module-name 'install-rundeck' --repo 'https://github.com/craftech-io/module-ci' --tag 'v0.0.1'",
      ],
      "environment_vars": ["GITHUB_OAUTH_TOKEN={{user `github_auth_token`}}"]
    }
  ]
}
```

### Freely Available Script Modules

Some Script Modules are so common that we've made them freely available in the [modules/](modules) folder of this repo.

### How `module-install` Works

To actually install a Module, we wrote a bash script named `module-install`. Here's how it works:

1. It uses [fetch](https://github.com/gruntwork-io/fetch) to download the specified version of the scripts or binary from
   the (public or private) git repo specified via the `--repo` option.
1. If you used the `--module-name` parameter, it downloads the files from the `modules` folder of `--repo` and runs
   the `install.sh` script of that module.
1. If you used the `--binary-name` parameter, it downloads the right binary for your OS, copies it to `/usr/local/bin`,
   and gives it execute permissions.

That's it!

## Create Your Own Modules

You can use `module-install` with any GitHub repo, not just repos maintained by Craftech.

That means that to create an installable Script Module, all you have to do is put it in the `modules` folder of
a GitHub repo to which you have access and include an `install.sh` script. To create a Binary Module, you just publish
it to a GitHub release with the name format `<NAME>_<OS>_<ARCH>`.

### Example

For example, in your Packer and Docker templates, you can use `module-install` to install the [install-rundeck
module](https://github.com/craftech-io/module-ci/tree/master/modules/install-rundeck) as follows:

```
module-install --module-name 'install-rundeck' --repo 'https://github.com/craftech-io/module-ci' --tag 'v0.0.1'
```

In https://github.com/craftech-io/module-ci, we download the contents of `/modules/install-rundeck` and run
`/modules/install-rundeck/install.sh`.

## Running tests

The tests for this repo are defined in the `test` folder. They are designed to run in a Docker container so that you
do not repeatedly dirty up your local OS while testing. We've defined a `test/docker-compose.yml` file as a convenient
way to expose the environment variables we need for testing and to mount local directories as volumes for rapid
iteration.

To run the tests:

1. Set your [GitHub access token](https://help.github.com/articles/creating-an-access-token-for-command-line-use/) as
   the environment variable `GITHUB_OAUTH_TOKEN`.
1. `./_ci/run-tests.sh`

## Security

### Validate the Downloaded Binary

Module-install will retrieve the desired GitHub Release Asset specified by the `--binary-name` property, but how can
we confirm that this binary has not been tampered with? In short, we trust that the maintainer has been responsible and
not allowed a malicious third-party to corrupt the Release Asset.

You can narrow the scope of this trust by computing a checksum on a Release Asset using a UNIX command like
`shasum -a 256 /path/to/file` when you first download the release. You can then feed this value (e.g. `b0b30cc24aed1b8cded2df903183b884c77f086efffc36ef19876d1c55fef93d`)
to `--binary-sha256-checksum` or `--binary-sha512-checksum`. If the checksum does not match, module-install will fail
with an error. This way, you are at least notified if the Release Asset you initially downloaded has since been changed.

### Is it safe to pipe URLs into bash?

Are you worried that our install instructions tell you to pipe a URL into bash? Although this approach has seen some
[backlash](https://news.ycombinator.com/item?id=6650987), we believe that the convenience of a one-line install
outweighs the minimal security risks. Below is a brief discussion of the most commonly discussed risks and what you can
do about them.

#### Risk #1: You don't know what the script is doing, so you shouldn't blindly execute it.

This is true of _all_ installers. For example, have you ever inspected the install code before running `apt-get install`
or `brew install` or double clicking a `.dmg` or `.exe` file? If anything, a shell script is the most transparent
installer out there, as it's one of the few that allows you to inspect the code (feel free to do so, as this script is
open source!). The reality is that you either trust the developer or you don't. And eventually, you automate the
install process anyway, at which point manual inspection isn't a possibility anyway.

#### Risk #2: The download URL could be hijacked for malicious code.

This is unlikely, as it is an https URL, and your download program (e.g. `curl`) should be verifying SSL certs. That
said, Certificate Authorities have been hacked in the past, and perhaps the Module GitHub account could be hacked
in the future, so if that is a major concern for you, feel free to copy the bootstrap code into your own codebase and
execute it from there. Alternatively, in the future we will publish checksums of all of our releases, so you could
optionally verify the checksum before executing the script.

#### Risk #3: The script may not download fully and executing it could cause errors.

We wrote our [bootstrap-module-installer.sh](bootstrap-module-installer.sh) as a series of bash functions that
are only executed by the very last line of the script. Therefore, if the script doesn't fully download, the worst
that'll happen when you execute it is a harmless syntax error.

## TODO

1. Add support for a `--version` flag to `bootstrap-module-installer.sh` and `module-install`.
1. Configure a CI build to automatically set the `--version` flag for each release.
1. Add an `uninstall` command that uses an `uninstall.sh` script in each module.
1. Add support for modules declaring their dependencies. Alternatively, consider Nix again as a dependency manager.
