#!/bin/bash
set -o errexit -o nounset -o xtrace -o pipefail

# Install PostgreSQL

# Read settings and environmental overrides
# $1 = platform (aws or vagrant); $2 = path to install scripts
[ -f "${2}/config.sh" ] && . "${2}/config.sh"
[ -f "${2}/config_${1}.sh" ] && . "${2}/config_${1}.sh"

cd "$INSTALL_DIR"

apt-get install -y postgresql libpq-dev
$POSTGRESQL_COMMAND psql -c "CREATE USER ${INSTALL_USER} WITH PASSWORD '${DB_PASS}';"
$POSTGRESQL_COMMAND psql -c "CREATE DATABASE datarepo WITH OWNER ${INSTALL_USER} ENCODING 'UTF8';"
