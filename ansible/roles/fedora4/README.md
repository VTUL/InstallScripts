Fedora4
=========

Creates the Fedora4 user and group, and installs Fedora 4.

Requirements
------------

Tomcat must be installed.  This role references variables from the `tomcat` role.

Role Variables
--------------

Role variables are listed below, along with their defaults:

    fedora_user: <tomcat_user>
    fedora_group: <tomcat_user>
    fedora_user_home: /var/local/<tomcat_user>
    fedora_data_dir: /var/local/<tomcat_user>/fedora-data
    fedora_app_dir: /var/lib/<tomcat_user>/webapps
    fedora_war_filename: fcrepo-webapp-<fedora_version>.war
    fedora_war_base_url: http://repo1.maven.org/maven2/org/fcrepo/fcrepo-webapp/<fedora_version>
    fedora_java_vm_opts: -Xms512m -Xmx1024m -XX:NewSize=256m -XX:MaxNewSize=256m -XX:MetaspaceSize=256m -XX:MaxMetaspaceSize=256m -XX:+DisableExplicitGC


It should be noted that `fedora_java_vm_opts` is intended to define all memory-related Java VM options necessary to constrain the total amount of memory Tomcat may use.  As such, care should be exercised when changing `fedora_java_vm_opts`.  Omitting a setting in the string (e.g. `-Xms...`) will result in that Java VM option either to be unset or to revert to the default for the Java VM.  Users should exercise caution when deleting individual Java options from `fedora_java_vm_opts`.
