#!/bin/bash
set -o errexit -o nounset -o xtrace -o pipefail

# Install PostgreSQL

# Read settings and environmental overrides
# $1 = platform (aws or vagrant); $2 = path to install scripts
[ -f "${2}/config.sh" ] && . "${2}/config.sh"
[ -f "${2}/config_${1}.sh" ] && . "${2}/config_${1}.sh"

cd "$INSTALL_DIR"

apt-get install -y libpq-dev
case $DB_IS_REMOTE in
  [Yy][Ee][Ss])
    echo "Assuming DB is on remote server."
    apt-get install -y postgresql-client
    PGPASSFILE=$(mktemp)
    echo "${DB_HOST}:${DB_PORT}:${DB_ADMIN_DB}:${DB_ADMIN_USER}:${DB_ADMIN_PASS}" > "$PGPASSFILE"
    chmod 0600 "$PGPASSFILE"
    export PGHOST=$DB_HOST
    export PGPORT=$DB_PORT
    export PGUSER=$DB_ADMIN_USER
    export PGDATABASE=$DB_ADMIN_DB
    export PGPASSFILE
    psql -c "DROP DATABASE IF EXISTS ${DB_NAME};"
    psql -c "DROP USER IF EXISTS ${DB_USER};"
    psql -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';"
    psql -c "CREATE DATABASE ${DB_NAME} WITH OWNER ${DB_USER} ENCODING 'UTF8';"
    rm "$PGPASSFILE"
    ;;
  *)
    echo "Assuming DB is local."
    apt-get install -y postgresql
    sudo -u postgres psql -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';"
    sudo -u postgres psql -c "CREATE DATABASE ${DB_NAME} WITH OWNER ${DB_USER} ENCODING 'UTF8';"
    ;;
esac
