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
    fedora_java_vm_opts: -Xms512m -Xmx1024m -XX:NewSize=256m -XX:MaxNewSize=256m -XX:MetaspaceSize=256m -XX:MaxMetaspaceSize=256m -XX:+DisableExplicitGC


It should be noted that `fedora_java_vm_opts` is intended to define all memory-related Java VM options necessary to constrain the total amount of memory Tomcat may use.  As such, care should be exercised when changing `fedora_java_vm_opts`.  Omitting a setting in the string (e.g. `-Xms...`) will result in that Java VM option either to be unset or to revert to the default for the Java VM.  Users should exercise caution when deleting individual Java options from `fedora_java_vm_opts`. 
