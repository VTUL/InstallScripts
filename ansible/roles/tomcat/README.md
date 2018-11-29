Tomcat
======

Installs Tomcat and add our configuration

Requirements
------------

Java and Apt must be installed, along with our Common role.

Role Variables
--------------

Role variables are listed below, along with their defaults:

    tomcat_shutdown_port: 8005
    tomcat_port: 8080
    tomcat_connection_timeout: 20000
    tomcat_redirect_port: 8443
    tomcat_ajp_port: 8009
