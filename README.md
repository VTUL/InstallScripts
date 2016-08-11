# Install Scripts for Hydra Application

These files are used to install the a VA Tech Hydra Head on a target server. They can be used to install the application either to a VM under VirtualBox. Installation is done via [Vagrant](https://www.vagrantup.com/). Alternatively, Ansible may be used directly to set up VT Hydra Repo on a suitable target system.

When installing the  application, the `vagrant up` command is used to set up the server and deploy the application on a local VM.

## Installation

These scripts are intended to be run on a Unix-like system. They are tested to work on Mac OSX.

To use these scripts, [Vagrant](https://www.vagrantup.com/) must already have been installed on the local system with the [VirtualBox](http://www.virtualbox.org) provider working.

You will need version 1.6+ of [Vagrant](https://vagrantup.com) and a version of  [Ansible](https://ansible.com) at least 2.0+ installed on the local system.

Ansible is easily installed via [Homebrew](http://brew.sh) on Mac OSX via the following command:

```
brew install ansible
```

Finally, these install scripts must be installed on the local machine. This is most easily done by cloning the repository containing them.

## Configuration


A deployment settings file needs to be created in the `provision/` directory. This file is called `site_secrets.yml` and is easily created by copying the example file `example_site_secrets.yml`:

```
cp example_site_secrets.yml site_secrets.yml
```

The Ansible playbook will be expecting a repository-ignored `site_secrets.yml` YAML file. Read the variable contents of the file and adjust accordingly to match your local environment.

#### TLS certificate and key

If `tls_enabled` is set to `true` in `site_secrets.yml` then a TLS certificate and key file may be placed in the `secret_files/` directory for use in the system being set up. The certificate should be named `secret_files/cert` and the key named `secret_files/key`.

If either of the aforementioned files is not present then a self-signed TLS certificate and key pair will be generated and used instead.

## Usage

To install a hydra application from scratch on a server using the current local configuration file settings, do the following:

```
cd /path/to/install/scripts
vagrant up
```

If using Ansible directly, you will need the IP address of the server you plan to provision. Execute the following command:

```
cd /path/to/install/scripts/ansible
ansible-playbook --limit [ip address] site.yml -b
```

### Local VM

In the case of the plain `vagrant up` option, a VM will be brought up and configured in the current directory. The hydra application is accessible on the local machine from a Web browser at `https//localhost`.

You can use `vagrant ssh` to log in to this VM when it is up. When logged out of the VM, `vagrant halt` can be used to shut down the VM. The command `vagrant destroy` will destroy it entirely, requiring another `vagrant up` to recreate it.

### Ansible

When using Ansible to provision directly, the playbook will be executed on the server whose IP address is given as `IP`. When the playbook finishes with no failures, the VT hydra server is accessible at this URL:

```
http://[IP]
```

or

```
https://[IP]
```

if `tls_enabled` is set in `site_secrets.yml` during deployment.

