Postfix
=======

Installs and configures Postfix.

Requirements
------------

This role uses debconf, and so expects to be installed on a Debian system.

Apt must be installed, along with the Common role.

Role Variables
--------------

Role variables are listed below, along with their defaults:

    postfix_inet_interfaces: loopback-only
