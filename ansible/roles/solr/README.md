Solr
=========

Installs Solr.

Requirements
------------

Solr is a Java application and so requires our OpenJDK8 role

Role Variables
--------------

Role variables are listed below, along with their defaults:

    solr_mirror: 'http://archive.apache.org/dist'
    solr_logsize: '100MB'
    solr_mutable_dir: '/var/solr'
    solr_install_dir: '/opt'
    solr_workspace: '/tmp'
    solr_create_user: 'true'
    solr_log_file_path: '/var/log/solr/solr.log'
    solr_host: '127.0.0.1'
    solr_port: '8983'
    solr_xms: '256M'
    solr_xmx: '512M'
    solr_dist: 'solr-{{ solr_version }}'
