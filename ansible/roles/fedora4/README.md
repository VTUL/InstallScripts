Fedora4
=========

Creates the Fedora4 user and group, and installs Fedora 4.

Requirements
------------

Tomcat7 must be installed.

Role Variables
--------------

Role variables are listed below, along with their defaults:

    fedora_user: tomcat7
    fedora_group: tomcat7
    fedora_user_home: /var/local/tomcat7
    fedora_data_dir: /var/local/tomcat7/fedora-data
    fedora_app_dir: /var/lib/tomcat7/webapps
