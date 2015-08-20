#!/bin/sh
# Defaults for Vagrant environment Installs
INSTALL_USER="vagrant" # Name of user to install under (must already exist)
SERVER_HOSTNAME="localhost" # The hostname of the server being installed.
APP_ENV="development" # What environment the app should run in. Should be 'development' or 'production'
#APP_ENV="production" # What environment the app should run in. Should be 'development' or 'production'
SOLR_CORE="$APP_ENV"
INSTALL_DIR="/home/$INSTALL_USER"
FITS_DIR="$INSTALL_DIR/fits" # Where FITS will be installed.
HYDRA_HEAD_DIR="$INSTALL_DIR/$HYDRA_HEAD" # Where the Hydra head will be located.
FEDORA4_DATA="$INSTALL_DIR/fedora-data"
RUN_AS_INSTALLUSER="sudo -H -u $INSTALL_USER"
