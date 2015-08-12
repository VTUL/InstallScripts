#!/bin/sh
# Bootstrap application on server.
#
# This script takes two arguments: the install environment ("vagrant" or "aws")
# and the path to where these install scripts live on the server being
# provisioned.
set -x -o errexit

# Validate command line arguments
if [ $# -ne 2 ]; then
  echo "Error: wrong number of arguments to $0 (expected 2, got $#)"
  echo "Usage: $0 vagrant|aws /path/to/install/scripts"
  exit 1
fi
PLATFORM=$1
SCRIPTS_DIR=$2
if [ $PLATFORM != "vagrant" -a $PLATFORM != "aws" ]; then
  echo "Invalid server environment: $PLATFORM"
  exit 1
fi

# Read settings and environmental overrides
[ -f "${SCRIPTS_DIR}/config.sh" ] && . "${SCRIPTS_DIR}/config.sh"
[ -f "${SCRIPTS_DIR}/config_${PLATFORM}.sh" ] && . "${SCRIPTS_DIR}/config_${PLATFORM}.sh"

# Update packages
cd "$INSTALL_DIR"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade

# Install Fedora 4
${SCRIPTS_DIR}/install_fedora4.sh $PLATFORM $SCRIPTS_DIR

# Install Sufia Data-Repo application
${SCRIPTS_DIR}/install_sufia_application.sh $PLATFORM $SCRIPTS_DIR

# Install Solr
${SCRIPTS_DIR}/install_solr.sh $PLATFORM $SCRIPTS_DIR

# Start up services
echo "Starting services in $APP_ENV environment mode."
cd "$HYDRA_HEAD_DIR"
$RUN_AS_INSTALLUSER bash "$HYDRA_HEAD_DIR/scripts/restart_resque.sh" "$APP_ENV"
# Start system services
service tomcat7 start
service solr start
service nginx start
