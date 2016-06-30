#!/bin/sh

# Default values for main configuration settings

# Name of the Hydra head.
HYDRA_HEAD="data-repo"
# The git repository to pull changes from during setup.
HYDRA_HEAD_GIT_REPO_URL="https://github.com/VTUL/data-repo.git"
# SSH deployment key, if any, needed for cloning above repository
HYDRA_HEAD_GIT_REPO_DEPLOY_KEY=""
# The branch of the repository to pull.
HYDRA_HEAD_GIT_BRANCH="master"
# The hostname of the server being installed.
SERVER_HOSTNAME="localhost"
PASSENGER_REPO="/etc/apt/sources.list.d/passenger.list"
# How many instances of our application we want Passenger to keep running
PASSENGER_INSTANCES="2"
# Where the NGINX configuration files live
NGINX_CONF_DIR="/etc/nginx"
NGINX_CONF_FILE="$NGINX_CONF_DIR/nginx.conf"
NGINX_SITE="$NGINX_CONF_DIR/sites-available/$HYDRA_HEAD.site"
# The next three options configure NGINX request rate limiting.  They define
# the rate; the size of a "burst" of requests that can temporarily exceed
# this rate without being dropped; and whether burst requests should be delayed
# or not.
NGINX_CLIENT_RATE="75r/s"
NGINX_CLIENT_BURST="500"
NGINX_BURST_OPTION="nodelay"
# Cap the size of uploads
NGINX_MAX_UPLOAD_SIZE="5200M"
# Where the TLS certificate resides
SSL_CERT_DIR="/etc/ssl/local/certs"
SSL_CERT="$SSL_CERT_DIR/$HYDRA_HEAD-crt.pem"
# Where the TLS certificate private key resides
SSL_KEY_DIR="/etc/ssl/local/private"
SSL_KEY="$SSL_KEY_DIR/$HYDRA_HEAD-key.pem"
# User under which Solr runs.  We adopt the default, "solr"
SOLR_USER="solr"
# Which Solr version we will install
SOLR_VERSION="5.2.1"
SOLR_MIRROR="http://archive.apache.org/dist/lucene/solr/$SOLR_VERSION/"
SOLR_DIST="solr-$SOLR_VERSION"
# The directory under which we will install Solr.
SOLR_INSTALL="/opt"
# The directory under which Solr cores and other mutable Solr data live.
SOLR_MUTABLE="/var/solr"
# Where Solr cores live
SOLR_DATA="$SOLR_MUTABLE/data"
# The size at which Solr logs will be rotated
SOLR_LOGSIZE="100MB"
TOMCAT_CONF="/etc/tomcat7"
# The URL of the Fedora 4 WAR we will install.
FEDORA4_WAR_URL="https://github.com/fcrepo4/fcrepo4/releases/download/fcrepo-4.2.0/fcrepo-webapp-4.2.0.war"
# The Tomcat directory in which to deploy the Fedora 4 WAR
FEDORA4_APP_DIR="/var/lib/tomcat7/webapps"
FEDORA4_USER="tomcat7"
FEDORA4_GROUP="tomcat7"
# Java VM options for Tomcat to use to run Fedora 4
FEDORA4_VM_OPTS="-Djava.awt.headless=true -Dfile.encoding=UTF-8 -server -Xms512m -Xmx1024m -XX:NewSize=256m -XX:MaxNewSize=256m -XX:MetaspaceSize=256m -XX:MaxMetaspaceSize=256m -XX:+DisableExplicitGC"
JDK_HOME="/usr/lib/jvm/java-8-oracle"
# The version of FITS to install.
FITS_PACKAGE="fits-0.6.2"
# The version of Ruby to install.
RUBY_PACKAGE="ruby2.2"
RUN_AS_SOLR_USER="sudo -H -u $SOLR_USER"
# Is PostgreSQL running on a remote system?
DB_IS_REMOTE="NO"
DB_ADMIN_USER="postgres"
DB_ADMIN_PASS="MyAdminPW"
DB_ADMIN_DB="postgres"
DB_NAME="datarepo"
DB_PASS="changeme"
DB_HOST="localhost"
DB_PORT="5432"
