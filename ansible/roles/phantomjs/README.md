PhantomJS
=========

Installs PhantomJS the way the PhantomJS gem expects. If necessary, the role will cache the downloaded tar for future use.

Requirements
------------

None

Role Variables
--------------

Role variables are listed below, along with their defaults:

    phantomjs_distro: '{{ ansible_system | lower }}'
    phantomjs_arch: '{{ ansible_userspace_architecture }}'
    phantomjs_src: 'phantomjs-{{ phantomjs_version }}-{{ phantomjs_distro }}-{{ phantomjs_arch }}.tar.bz2'
    phantomjs_dir: '{{ project_user_home }}/.phantomjs/{{ phantomjs_version }}/{{ phantomjs_arch }}-{{ phantomjs_distro }}'

Additionally, when using this role, you must pass in the `phantomjs_version`.

This role makes use of the `local_files_dir` variable defined in the top-level `site_vars.yml` file. The `local_files_dir` setting points to a local directory on the provisioning host where locally-provided files may be supplied to the deployment and provisioning process. In the case of the `phantomjs` role, this directory is used to supply (and cache) a copy of the PhantomJS distribution, to avoid excessive downloads.
