Chroot-sftp
===========

Configures a chroot SFTP upload area.

Requirements
------------

This requires our Common role.

Role Variables
--------------

Role variables are listed below:

- `sftp_user`: The username of the chroot SFTP upload user.
- `sftp_group`: The group name of the chroot SFTP upload user.
- `sftp_user_uid`: The numeric user id of the chroot SFTP upload user.
- `sftp_user_gid`: The numeric group id of the chroot SFTP upload user.
- `sftp_chroot_owner`: The username of the user that owns the chroot SFTP area directory hierarchy directories.
- `sftp_chroot_uid`: The numeric user id of the user that owns the chroot SFTP area directory hierarchy directories.
- `sftp_chroot_group`: The group name to be used for the chroot SFTP area directory hierarchy directories.
- `sftp_chroot_gid`: The numeric group id of the user that owns the chroot SFTP area directory hierarchy directories.
- `sftp_home_dir`: The home directory of the chroot SFTP upload user (separate from the chroot directory).
- `sftp_upload_root`: The root directory of the chroot SFTP upload area.
