Install Scripts for Data Repository Application
===============================================

These scripts install the [Data Repository
application](https://github.com/VTUL/data-repo) on a target server. They can be
used to install the application either to a VM under VirtualBox
via[Vagrant](https://www.vagrantup.com/) or to a server running under Amazon Web
Services (AWS).

When installing the Data Repository application, first application settings are
configured to determine how it is to be installed on the server. Supplementary
files such as Web server certificates can also be placed in the `files/`
directory for deployment to the installed application. Next, the `bootstrap.sh`
script is used to set up the server and deploy the application on the chosen
platform: `vagrant` or `aws`.

Installation
------------

These scripts are intended to be run on a Unix-like system. They are tested to
work on Mac OSX.

To utilise the `vagrant` option, [Vagrant](https://www.vagrantup.com/) must
already been installed on the local system with
the[VirtualBox](http://www.virtualbox.org) provider working.

For the `aws` option to work, [awscli](https://aws.amazon.com/cli/) must be
installed and configured on the local system. (Under Mac OSX, this is most
easily done using [Homebrew](http://brew.sh/): `brew install awscli`.) In
particular, `awscli` must be configured correctly to access the AWS account
under which the new server will be installed and have the necessary EC2
permissions to create new servers, etc.

Finally, these install scripts must be installed on the local machine. This is
most easily done by cloning the
[VTUL/InstallScripts](https://github.com/VTUL/InstallScripts) repository from
GitHub:

```
git clone https://github.com/VTUL/InstallScripts.git
```

Configuration
-------------

Many aspects of how the application is installed can be configured by editing
the configuration files accompanying the install scripts. These are shell
scripts that contain variable definitions and are sourced in by the install
scripts during execution.

There is a general configuration file called `config.sh`. This file contains
common settings. These may then be overridden by platform-specific settings in
the `config_PLATFORM.sh` files, where `PLATFORM` currently is one of
either`vagrant` or `aws`. So, for example, settings in `config_vagrant.sh` will
override those in `config.sh` when installing via the `vagrant` option.

Some settings are only relevant for certain platforms and only make sense when
set in the corresponding `config_PLATFORM.sh` settings file. For example, it
isn't meaningful to set `AWS_AMI` in `config_vagrant.sh`, although it is
possible to do so.

Note that settings often refer to other settings. For example, `HYDRA_HEAD_DIR`
is usually set relative to `INSTALL_DIR`. If such a setting is overridden
(redefined) in a platform-specific configuration file then all the other
settings referring to it must also be re-specified in the platform-specific
configuration file, too (otherwise they will still refer to the original default
value).

Some important settings are as follows:

- `INSTALL_USER`: the user account under which the Data Repository application is
to be installed. This user must exist on the target server/VM and conventionally
is `vagrant` for the `vagrant` deployment option and `ubuntu` for the `aws`
option.
- `APP_ENV`: the Rails application environment in which the Data Repository
application will be installed and run. This is either `development`
or`production`.
- `SERVER_HOSTNAME`: the hostname of the Web server hosting the application.
- `AWS_KEY_PAIR`: the AWS SSH key pair used to access the deployed server. The
secret key of this SSH key *must* exist on the local system beforehand,
otherwise the user will not be able to SSH in to the deployed server.

Note that many AWS-related settings refer to AWS entities such as AMIs, key
pairs, security groups, etc. These must all exist in the AWS account being used
to host the deployed server prior to running these install scripts.

The `aws` install tacitly expects the SERVER_HOSTNAME set in `config_aws.sh` to
resolve to the AWS_ELASTIC_IP set there, too.

### Secrets

The `files/` directory is used to convey server-specific data such as the Web
server certificate and key for HTTPS, as well as ORCID API information. Such
files placed in `files/` will override application defaults.

If a specific certificate is to be used then the certificate and key file should
be placed in `files/` and named `cert` and `key` respectively. If no such files
are present, the install scripts will generate a self-signed certificate and
place the resultant `cert` and `key` files under `files/`.

To specify specific ORCID API credentials, place a file called `orcid_secrets`
in `files/`. The `orcid_secrets` file should contain two lines:

```
ORCID_APP_ID: ORCID-Application-Key
ORCID_APP_SECRET: ORCID-Application-Secret
```

These ORCID settings will then replace the defaults in the application.

Usage
-----

To install the Data Repository application from scratch on a server using the
current local configuration file settings, do the following:

```
cd /path/to/install/scripts
./bootstrap.sh PLATFORM
```

Where `PLATFORM` is either `vagrant` or `aws`.  (Note, in the information below,
where `$VAR` appears, you should substitute it with the value of the `$VAR`
setting in the appropriate configuration file.  Do not use `$VAR` directly in
the example commands below.)

### vagrant

In the case of the `vagrant` option, a VM will be brought up and configured in
the current directory. The Data Repository application is accessible on the
local machine from a Web browser at `http://$SERVER_HOSTNAME:4443`.

You can use `vagrant ssh` to log in to this VM when it is up. When logged out of
the VM, `vagrant halt` can be used to shut down the VM. The command `vagrant
destroy` will destroy it entirely.

Several ports in the running VM are made accessible on the local machine.
Accessing the local port in a Web browser will actually result in the forwarded
port being accessed on the VM. These ports are as follows:

Local | VM | Description
----- | -- | -----------
8983 | 8983 | Solr services
8888 | 8080 | Tomcat (Fedora 4)
8080 | 80 | Data Repository (HTTP)
4443 | 443 | Data Respository (HTTPS)

To access the Solr admin page in the VM from the local machine you would access
this URL: `http://localhost:8983/solr`

Similarly, to access the Fedora 4 REST endpoint in the VM from the local machine
you would access this URL: `http://localhost:8888/fedora/rest`

### aws

For the `aws` option, a server running the application will be provisioned in
AWS. After a while, it should be possible to log in to this machine via SSH:

```
ssh -i /path/to/$AWS_KEY_PAIR ubuntu@$SERVER_HOSTNAME
```

The installation and setup of the Data Repository application and associated
software could take quite a while. You may observe its progress when logged in
to the AWS server by looking at the file `/var/log/cloud-init-output.log`.

When installation is complete and services are running, you can access the
application via this URL: `https://$SERVER_HOSTNAME`
