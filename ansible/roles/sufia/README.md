Sufia
=========

Installs the Hydra application.

This involves cloning the project's repo, configuring passenger and postgres, creating solr cores, installing gems, configuring resque if the project needs it, and finally, project-specific setup.

Requirements
------------

Requires apt (and our Common role), Passenger and Nginx, ClamAV, FFmpeg, Postfix, NodeJS, PhantomJS, Ruby. Additionally, PostgreSQL, Solr, Redis, and Fedora must be available for the project.

Role Variables
--------------

Role variables are listed below, along with their defaults:

    passenger_instances: 2
    nginx_max_upload_size: 5200
    tls_cert_subject: "/C=US/ST=Virginia/O=Virginia Tech/localityName=Blacksburg/commonName={{ ansible_fqdn }}/organizationalUnitName=University Libraries"
    tls_cert_dir: /etc/ssl/local/certs
    tls_cert_file: cert.pem
    tls_key_dir: /etc/ssl/local/private
    tls_key_file: key.pem
    project_git_url: https://github.com/VTUL/{{ project_name }}.git
    project_deploy_key: ''
    project_app_root: '{{ project_user_home }}/{{ project_name }}'
    project_solr_test_core: test

This role makes use of the `local_files_dir` variable defined in the top-level `site_vars.yml` file. The `local_files_dir` setting points to a local directory on the provisioning host where locally-provided files may be supplied to the deployment and provisioning process. In the case of the `sufia` role, this directory is used to supply the `user_list.txt`, `admin_list.txt`, and `images.zip` carousel images for the `data-repo` application.
