Tls_cert
========

Installs a TLS certificate.

The TLS certificate to be installed may be provided locally by putting the
certificate and private key files in a local directory.  If a pair of files
are not present locally then a self-signed certificate will be generated
instead.  See the Role Variables section for details on file names and locations.

Requirements
------------

This requires our Common role.

Role Variables
--------------

Role variables are listed below:

- `tls_local_files_dir`: The local directory in which the TLS certificate and private key may be found.
- `tls_cert_subject`: The TLS Subject metadata for the self-signed certificate.
- `tls_cert_dir`: The directory in which the TLS certificate will be placed.
- `tls_cert_file`: The filename of the TLS certificate.
- `tls_key_dir`: The directory in which the TLS certificate private key will be placed.
- `tls_key_file`: The filename of the TLS certificate private key.

See `defaults/main.yml` for current default settings.
