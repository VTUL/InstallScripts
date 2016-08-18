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
