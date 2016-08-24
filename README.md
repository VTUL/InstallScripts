Install Scripts for Hydra/Rails Applications
============================================

These files are used to install a Virginia Tech Hydra Head (or other supported application) on a target server. They can be used to install the application either to a VM under VirtualBox; to a server running under Amazon Web Services (AWS); or to a server running under OpenStack in the Chameleon Cloud. Installation is done via [Vagrant](https://www.vagrantup.com/). Alternatively, Ansible may be used directly to set up the application on a suitable target system.

The `vagrant up` command is used to set up the server and deploy the application on the chosen platform. To deploy to AWS, select the `aws` Vagrant provider: `vagrant up --provider aws`.  To deploy to OpenStack in the Chameleon Cloud, select the `openstack` provider: `vagrant up --provider openstack`. If no provider is specified, it defaults to VirtualBox, which will set up a local VM.

Installation
------------

These scripts are intended to be run on a Unix-like system. They are tested to work on Mac OSX.

To use these scripts, [Vagrant](https://www.vagrantup.com/) must already have been installed on the local system with the [VirtualBox](http://www.virtualbox.org) provider working. For provisioning to AWS, the `aws` provider must also be installed. This can be done by executing the following command, which will install the `aws` Vagrant provider plugin: `vagrant plugin install vagrant-aws`. To provision to the OpenStack Chameleon Cloud, the `openstack` provider needs to be installed. It can be installed via the following command: `vagrant plugin install vagrant-openstack-provider`.

You will need version 1.6+ of [Vagrant](https://vagrantup.com) installed on the local system.

If you choose to use the `ansible` Vagrant provisioner (see below), a version of  [Ansible](https://ansible.com) at least 2.1+ must also be installed on the local system.

Ansible is easily installed via [Homebrew](http://brew.sh) on Mac OSX via the following command:

```
brew install ansible
```

Finally, these install scripts must be installed on the local machine. This is most easily done by cloning the repository containing them.

Configuration
-------------

For all environments, a deployment settings file needs to be created in the `ansible/` directory. This file is called `site_secrets.yml` and is easily created by copying the example file `example_site_secrets.yml`:

```
cp example_site_secrets.yml site_secrets.yml
```

The Ansible playbook will be expecting a repository-ignored `site_secrets.yml` YAML file. Read the variable contents of the file and adjust accordingly to match your local environment.

#### TLS certificate and key

A TLS certificate and key file may be placed in the `local_files/` directory for use in the system being set up. The certificate should be named `local_files/cert.pem` and the key named `local_files/key.pem`.

If either of the aforementioned files is not present then a self-signed TLS certificate and key pair will be generated and used instead.

#### Authorized keys for SFTP

The chroot SFTP server limits the upload user to public key based authentication only. As such, the upload user's `authorized_keys` file is used to determine which people may log in as the upload user via SFTP.

SSH public key files should be placed in `local_files/authorized_keys/` prior to setup. These public keys will be added to the upload user's `~/.ssh/authorized_keys` file. (Note, files in `local_files/authorized_keys/` should contain only public keys.)

If no public keys are supplied then the upload user's `~/.ssh/authorized_keys` file will have to be set up manually afterwards to enable the upload user to log in via SFTP.

#### Choosing a Vagrant Ansible provisioner

Vagrant supports two Ansible provisioners: `ansible` and `ansible_local`. These basically achieve the same end result but differ in how that is achieved.

With the `ansible` provisioner, a version of Ansible that is installed on the local system is used to provision the system that Vagrant creates. This Ansible software must be installed prior to invoking `vagrant up`.

The Vagrant `ansible_local` provisioner, on the other hand, installs Ansible on the system that Vagrant creates and then uses this to provision the machine. No Ansible software need be installed locally when using the `ansible_local` Vagrant provisioner.

The choice of provisioner may be made by setting the environment variable `ANSIBLE_PROVISIONER` prior to running `vagrant up`. This should be set to either `ansible` or `ansible_local`. If that environment is unset, or is set to something other than those two choices, then it is set to `ansible_local`.

#### Choosing a target application to install

Normally, `vagrant up` will be able to determine the type of application you want to provision based upon settings in the `site_secrets.yml` file. You can override this choice by setting the `APP_TYPE` environment variable to the chosen application prior to `vagrant up`.  Valid settings for `APP_TYPE` are either `sufia` or `geoblacklight`.

### AWS

When using the `aws` provider to `vagrant up` it is necessary to define several environment variables in order to authenticate to AWS and supply a keypair with which Vagrant can log in to the new AWS EC2 instance being deployed.  These environment variables are as follows:

- `KEYPAIR_NAME`: the name of the AWS keypair that will be used to log in to the instance. This keypair should already exist within your AWS account and its private key file should reside on the local system.
- `KEYPAIR_FILE`: the pathname of the private key on the local system corresponding to the aforementioned keypair.
- `AWS_ACCESS_KEY`: the AWS IAM access key to the account under which the EC2 instance will be created.
- `AWS_SECRET_KEY`: the AWS IAM secret key to the account under which the EC2 instance will be created.
- `AWS_SECURITY_GROUPS`: a space-separated list of existing AWS security groups to apply to this instance. (If `AWS_SECURITY_GROUPS` is not set then a default security group is used.)

WARNING: Many of the other AWS EC2 instance settings (e.g., instance type) are set directly in the `Vagrantfile` and make sense only for VTUL users. Please check these are appropriate before bringing up the instance with Vagrant and edit where necessary beforehand.

### OpenStack

When deploying to the OpenStack Chameleon Cloud, several environment variables must be defined in order to authenticate to OpenStack and define a keypair to be used to log in to the new Chameleon Cloud instance being deployed.  The following environment variables must be defined:

- `KEYPAIR_NAME`: the name of the OpenStack keypair that will be used to log in to the instance. This keypair should already exist within your OpenStack account and its private key file should reside on the local system.
- `KEYPAIR_FILE`: the pathname of the private key on the local system corresponding to the aforementioned keypair.
- `OS_FLOATING_IP`: the floating IP address (as a "dotted quad", i.e., x.x.x.x) to be assigned to this instance. This floating IP must already be available to the OpenStack project under which the instance is being deployed.
- `OS_SECURITY_GROUPS`: a space-separated list of existing OpenStack security groups to apply to this instance. (If `OS_SECURITY_GROUPS` is not set then a default security group is used.)
- `OS_USERNAME`: your OpenStack user name
- `OS_PASSWORD`: your OpenStack login password
- `OS_AUTH_URL`: the URL of the OpenStack endpoint
- `OS_TENANT_NAME`: the ID of your OpenStack Chameleon Cloud project (tenant)
- `OS_REGION_NAME`: the OpenStack region in which you wish to deploy the instance

The `OS_USERNAME`; `OS_PASSWORD`; `OS_AUTH_URL`; `OS_TENANT_NAME`; and `OS_REGION_NAME` settings are most easily set via an OpenStack RC file downloaded via the OpenStack dashboard. To do this, log in to the dashboard and select the "Compute" -> "Access & Security" page. On that page, select the "API Access" tab. Click the "Download OpenStack RC File" to download the RC script to your local system. This is a bash script that sets the aforementioned environment variables when run. The script also prompts the user to enter his or her OpenStack password. The `OS_PASSWORD` environment variable is set to the value entered. You should run this script to define those environment variables prior to deploying via Vagrant, e.g., by executing `. /path/to/OpenStack_RC_File.sh`.

Usage
-----

To install the chosen application from scratch on a server using the current local configuration file settings, do the following:

```
cd /path/to/install/scripts
vagrant up
```

This will install to a local VM. To install to AWS do the following:

```
cd /path/to/install/scripts
vagrant up --provider aws
```

If you wish to install to OpenStack then do the following:

```
cd /path/to/install/scripts
vagrant up --provider openstack
```

If using Ansible directly, you will need the IP address of the server you plan to provision. Execute the following command:

```
cd /path/to/install/scripts/ansible
ansible-playbook --limit [ip address] site.yml -b
```

### Local VM

In the case of the plain `vagrant up` option, a VM will be brought up and configured in the current directory. The application is accessible on the local machine from a Web browser.

You can use `vagrant ssh` to log in to this VM when it is up. When logged out of the VM, `vagrant halt` can be used to shut down the VM. The command `vagrant destroy` will destroy it entirely, requiring another `vagrant up` to recreate it.

Several ports in the running VM are made accessible on the local machine.
Accessing the local port in a Web browser will actually result in the forwarded
port being accessed on the VM. These ports are as follows:

Local | VM   | Description
----- | ---- | -----------
8983  | 8983 | Solr services
8888  | 8080 | Tomcat (if applicable)
8080  | 80   | Application (HTTP)
4443  | 443  | Application (HTTPS)

To access the Solr admin page in the VM from the local machine you would access
this URL: `http://localhost:8983/solr`.  (Note that only the "Local" ports in the above table are directly accessible from the local machine.)

### AWS

For the `vagrant up --provider aws` option, a server running the application will be provisioned in AWS. After a while, it should be possible to log in to this machine via SSH:

```
vagrant ssh
```

The installation and setup of the application and associated software could take quite a while. Its progress will be logged to the screen during the execution of `vagrant up --provider aws`.

When installation is complete and services are running, you can access the application via this URL: `https://$SERVER_HOSTNAME`, where `$SERVER_HOSTNAME` is the hostname of the AWS instance just deployed.  This can be determined by running the following command in the installation scripts directory:

```
vagrant ssh-config | grep HostName | awk '{print $2}'
```

Vagrant commands such as `halt` and `destroy` behave analogously on the AWS instance as they do for local Vagrant VMs.

### OpenStack

Installation to OpenStack is similar to that of AWS above. After provisioning with `vagrant up --provider openstack` it should be possible to log in to the newly-deployed machine via SSH:

```
vagrant ssh
```

As with the `aws` provider, the application can be accessed via the URL `https://$SERVER_HOSTNAME`, where `$SERVER_HOSTNAME` is the hostname of the OpenStack instance just deployed. You can determine the hostname by using the following command:

```
vagrant ssh-config | grep HostName | awk '{print $2}'
```

As with the `aws` provider, Vagrant commands such as `halt` and `destroy` behave analogously on the OpenStack instance as they do for local Vagrant VMs.

### Ansible

When using Ansible to provision directly, the playbook will be executed on the server whose IP address is given as `IP`. When the playbook finishes with no failures, the server is accessible at this URL:

```
http://[IP]
```

or

```
https://[IP]
```
