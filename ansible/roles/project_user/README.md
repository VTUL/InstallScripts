Project User
=========

Creates the project users and groups. There are two project users: one that owns the files (`project_owner`) and another under which the application runs (`project_runner`). These have corresponding groups, `project_owner_group` and `project_runner_group` respectively. The users and groups are defined in `site_secrets.yml`.

If the project user groups should be system (low-numbered) groups then `project_owner_group_system` and `project_runner_group_system` should be set to `true` appropriately. Similarly, if a specific numeric group id should be used, it should be set in `project_owner_gid` or `project_runner_gid` as appropriate. Finally, the numeric id of the `project_owner` and `project_runner` user is specified in the `project_owner_uid` and `project_runner_uid` variables respectively.

Requirements
------------

None

Role Variables
--------------

Role variables are listed below, along with their defaults:

    project_owner: 'hydra'
    project_owner_uid: 60001
    project_owner_gid: 60001
    project_runner: 'railsapps'
    project_runner_uid: 60002
    project_runner_gid: 60002
    project_owner_group_system: false
    project_runner_group_system: false

The group gid is omitted unless the variable is defined.
