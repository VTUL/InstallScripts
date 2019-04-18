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
    mail_relayhost: <undefined>

If `mail_relayhost` is defined then Postfix is configured to route all mail
via that hostname/IP.  If `mail_relayhost` is undefined then the `relayhost`
setting is removed from the Postfix configuration file.