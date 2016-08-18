Tomcat7
=========

Installs Tomcat7 and add our configuration

Requirements
------------

Java and Apt must be installed, along with our Common role.

Role Variables
--------------

Role variables are listed below, along with their defaults:

    tomcat7_enabled: true
    tomcat7_hostname: localhost
    tomcat7_server_port: 8005
    tomcat7_catalina_port: 8983
    tomcat7_catalina_redirect_port: 8443
    tomcat_shutdown_port: 8005
    tomcat_port: 8080
    tomcat_connection_timeout: 20000
    tomcat_redirect_port: 8443
    tomcat_ajp_port: 8009
