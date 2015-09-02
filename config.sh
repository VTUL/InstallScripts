#!/bin/sh

# Default values for main configuration settings

HYDRA_HEAD="data-repo" # Name of the Hydra head.
HYDRA_HEAD_GIT_REPO="VTUL/data-repo" # The git repository to pull changes from during setup.
HYDRA_HEAD_GIT_BRANCH="master" # The branch of the repository to pull.
SERVER_HOSTNAME="localhost" # The hostname of the server being installed.
PASSENGER_REPO="/etc/apt/sources.list.d/passenger.list"
PASSENGER_INSTANCES="2"
NGINX_CONF_DIR="/etc/nginx"
NGINX_CONF_FILE="$NGINX_CONF_DIR/nginx.conf"
NGINX_SITE="$NGINX_CONF_DIR/sites-available/$HYDRA_HEAD.site"
NGINX_CLIENT_RATE="2r/s"
NGINX_CLIENT_BURST="10"
SSL_CERT_DIR="/etc/ssl/local/certs"
SSL_CERT="$SSL_CERT_DIR/$HYDRA_HEAD-crt.pem"
SSL_KEY_DIR="/etc/ssl/local/private"
SSL_KEY="$SSL_KEY_DIR/$HYDRA_HEAD-key.pem"
SOLR_USER="solr" # User under which Solr runs.  We adopt the default, "solr"
SOLR_VERSION="5.2.1"
SOLR_MIRROR="http://www.gtlib.gatech.edu/pub/apache/lucene/solr/$SOLR_VERSION/"
SOLR_DIST="solr-$SOLR_VERSION"
SOLR_INSTALL="/opt"
SOLR_MUTABLE="/var/solr"
SOLR_DATA="$SOLR_MUTABLE/data" # Where Solr cores live
SOLR_LOGSIZE="100MB"
TOMCAT_CONF="/etc/tomcat7"
FEDORA4_WAR_URL="https://github.com/fcrepo4/fcrepo4/releases/download/fcrepo-4.2.0/fcrepo-webapp-4.2.0.war"
FEDORA4_APP_DIR="/var/lib/tomcat7/webapps"
FEDORA4_USER="tomcat7"
FEDORA4_GROUP="tomcat7"
FEDORA4_VM_OPTS="-Djava.awt.headless=true -Dfile.encoding=UTF-8 -server -Xms512m -Xmx1024m -XX:NewSize=256m -XX:MaxNewSize=256m -XX:MetaspaceSize=256m -XX:MaxMetaspaceSize=256m -XX:+DisableExplicitGC"
JDK_HOME="/usr/lib/jvm/java-8-oracle"
FITS_PACKAGE="fits-0.6.2" # The version of FITS to install.
RUBY_PACKAGE="ruby2.2" # The version of Ruby to install.
RAILS_VERSION="~> 4.2" # The version of Rails to install.
SUFIA_VERSION="6.2.0" # The version of Sufia to install.
RUN_AS_SOLR_USER="sudo -H -u $SOLR_USER"
