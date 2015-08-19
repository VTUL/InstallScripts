#!/bin/sh
# Defaults for AWS environment Installs
INSTALL_USER="ubuntu" # Name of user to install under (must already exist)
# Next three settings specify data.lib.vt.edu in production mode
SERVER_HOSTNAME="data.lib.vt.edu" # The hostname of the server being installed.
AWS_ELASTIC_IP="eipalloc-23c49346" # 54.152.247.163 - data.lib.vt.edu
APP_ENV="production"
# Next three settings specify datadev.lib.vt.edu in development mode
#SERVER_HOSTNAME="datadev.lib.vt.edu" # The hostname of the server being installed.
#AWS_ELASTIC_IP="eipalloc-4fc4932a" # 54.209.80.216 - datadev.lib.vt.edu
#APP_ENV="development"
SOLR_CORE="$APP_ENV"
INSTALL_DIR="/home/$INSTALL_USER"
FITS_DIR="$INSTALL_DIR/fits" # Where FITS will be installed.
HYDRA_HEAD_DIR="$INSTALL_DIR/$HYDRA_HEAD" # Where the Hydra head will be located.
FEDORA4_DATA="$INSTALL_DIR/fedora-data"
FEDORA4_SRC="$INSTALL_DIR/fcrepo4"
RUN_AS_INSTALLUSER="sudo -H -u $INSTALL_USER"
AWS_KEY_PAIR="data_repo"
AWS_AMI="ami-d05e75b8"
AWS_EBS_SIZE="16"
AWS_INSTANCE_TYPE="t2.medium"
AWS_SECURITY_GROUP_IDS="sg-55159632 sg-e5149782"
AWS_SUBNET_ID="subnet-ec703bb5"
AWS_VPC_ID="vpc-bdd23fd9"
