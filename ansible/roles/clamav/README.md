ClamAV
=========

Installs ClamAV and ensures the main.cvd database has been created.

Requirements
------------

The target system should have Apt, and our Common role.

Role Variables
--------------

Role variables are listed below:

- `clamav_private_mirror_enabled`: Whether to enable a ClamAV PrivateMirror to override the included DatabaseMirror definitions (true/false)
- `clamav_private_mirror_host`: The FQDN of the ClamAV PrivateMirror (string)

Dependencies
------------

Our Common role
