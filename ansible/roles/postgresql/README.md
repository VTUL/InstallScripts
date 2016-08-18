PostgreSQL
=========

Installs PostgreSQL from the official repository, and configures it.

Requirements
------------

Apt must be installed, along with our Common role.

Role Variables
--------------

While the role does not have any variables itself, there are three in `site_secrets.yml`:

    database_user: postgres
    database_group: postgres
    database_password: postgres
