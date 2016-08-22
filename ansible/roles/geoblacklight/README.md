Geoblacklight
=============

Installs the GeoBlacklight application.


Requirements
------------

This requires our Common role as well as the Project_user; Passenger; a Tls_cert; Ruby; Postfix (for the contact form e-mail); and Nodejs (to provide a Ruby JavaScript engine).

Role Variables
--------------

Role variables are listed below:

- `passenger_instances`: Maximum number of Passenger workers to spawn for application.
- `nginx_max_upload_size`: Maximum size of a POST request.
