Project User
=========

Creates the project users and groups. There are two project users: one that owns the files (`project_owner`) and another under which the application runs (`project_runner`). These have corresponding groups, `project_owner_group` and `project_runner_group` respectively. The users and groups are defined in `site_secrets.yml`.

If the project user groups should be system (low-numbered) groups then `project_owner_group_system` and `project_runner_group_system` should be set to `true` appropriately. Similarly, if a specific numeric group id should be used, it should be set in `project_owner_group_id` or `project_runner_group_id` as appropriate.

Requirements
------------

None

Role Variables
--------------

Role variables are listed below, along with their defaults:

    project_owner_group_system: false
    project_owner_group_id: <Not Defined>
    project_runner_group_system: false
    project_runner_group_id: <Not Defined>

The group gid is omitted unless the variable is defined.
