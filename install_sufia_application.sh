#!/bin/bash
set -o errexit -o nounset -o xtrace -o pipefail

# Install Data-Repo Sufia application

PLATFORM=$1
BOOTSTRAP_DIR=$2
# Read settings and environmental overrides
[ -f "${BOOTSTRAP_DIR}/config.sh" ] && . "${BOOTSTRAP_DIR}/config.sh"
[ -f "${BOOTSTRAP_DIR}/config_${PLATFORM}.sh" ] && . "${BOOTSTRAP_DIR}/config_${PLATFORM}.sh"

# Install Java 8 and make it the default Java
add-apt-repository -y ppa:webupd8team/java
apt-get update -y
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections
apt-get install -y oracle-java8-installer
update-java-alternatives -s java-8-oracle

# Install FITS to /opt/fits
apt-get install -y unzip
TMPFILE=$(mktemp -d)
cd "$TMPFILE"
wget --quiet "http://projects.iq.harvard.edu/files/fits/files/${FITS_PACKAGE}.zip"
unzip -q "${FITS_PACKAGE}.zip" -d /opt
ln -sf "/opt/${FITS_PACKAGE}" /opt/fits
chmod a+x /opt/fits/fits.sh
rm -rf "$TMPFILE"
cd $INSTALL_DIR

# Install ffmpeg
# Instructions from the static builds link on this page: https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu
add-apt-repository -y ppa:mc3man/trusty-media
apt-get update
apt-get install -y ffmpeg

# Install nodejs from Nodesource
curl -sL https://deb.nodesource.com/setup | bash -
apt-get install -y nodejs

# Install Redis, ImageMagick, PhantomJS, and Libre Office
apt-get install -y redis-server imagemagick phantomjs libreoffice
# Install Ruby via Brightbox repository
add-apt-repository -y ppa:brightbox/ruby-ng
apt-get update
apt-get install -y $RUBY_PACKAGE ${RUBY_PACKAGE}-dev

# Install Nginx and Passenger.
# Install PGP key and add HTTPS support for APT
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
apt-get install -y apt-transport-https ca-certificates
# Add APT repository
echo "deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main" > $PASSENGER_REPO
chown root: $PASSENGER_REPO
chmod 600 $PASSENGER_REPO
apt-get update
# Install Nginx and Passenger
apt-get install -y nginx-extras passenger
# Uncomment passenger_root and passenger_ruby lines from config file
TMPFILE=`/bin/mktemp`
cat $NGINX_CONF_FILE | \
  sed "s/worker_processes .\+;/worker_processes auto;/" | \
  sed "s/# passenger_root/passenger_root/" | \
  sed "s/# passenger_ruby/passenger_ruby/" > $TMPFILE
sed "1ienv PATH;" < $TMPFILE > $NGINX_CONF_FILE
chown root: $NGINX_CONF_FILE
chmod 644 $NGINX_CONF_FILE
# Disable the default site
unlink ${NGINX_CONF_DIR}/sites-enabled/default
# Stop Nginx until the application is installed
service nginx stop

# Configure Passenger to serve our site.
# Create the virtual host for our Sufia application
cat > $TMPFILE <<HereDoc
passenger_max_pool_size ${PASSENGER_INSTANCES};
passenger_pre_start http://${SERVER_HOSTNAME};
limit_req_zone \$binary_remote_addr zone=clients:1m rate=${NGINX_CLIENT_RATE};

server {
    listen 80;
    listen 443 ssl;
    client_max_body_size 200M;
    passenger_min_instances ${PASSENGER_INSTANCES};
    limit_req zone=clients burst=${NGINX_CLIENT_BURST} ${NGINX_BURST_OPTION};
    root ${HYDRA_HEAD_DIR}/public;
    passenger_enabled on;
    passenger_app_env ${APP_ENV};
    server_name ${SERVER_HOSTNAME};
    ssl_certificate ${SSL_CERT};
    ssl_certificate_key ${SSL_KEY};
}
HereDoc
# Install the virtual host config as an available site
install -o root -g root -m 644 $TMPFILE $NGINX_SITE
rm $TMPFILE
# Enable the site just created
link $NGINX_SITE ${NGINX_CONF_DIR}/sites-enabled/${HYDRA_HEAD}.site
# Create the directories for the SSL certificate files
mkdir -p $SSL_CERT_DIR
mkdir -p $SSL_KEY_DIR
install -o root -m 444 ${BOOTSTRAP_DIR}/files/cert $SSL_CERT
install -o root -m 400 ${BOOTSTRAP_DIR}/files/key $SSL_KEY

# Create Hydra head
apt-get install -y git sqlite3 libsqlite3-dev zlib1g-dev build-essential
gem install bundler

# Pull application from git, using deployment key if specified.
GIT_SSH="${BOOTSTRAP_DIR}/ssh.sh"
if [ -n "$HYDRA_HEAD_GIT_REPO_DEPLOY_KEY" ]; then
  DEPLOY_KEY="${BOOTSTRAP_DIR}/files/$HYDRA_HEAD_GIT_REPO_DEPLOY_KEY"
  # Make sure deploy key is accessible to $INSTALL_USER
  chown $INSTALL_USER "$DEPLOY_KEY"
else
  DEPLOY_KEY=""
fi
$RUN_AS_INSTALLUSER -E GIT_SSH="$GIT_SSH" DEPLOY_KEY="$DEPLOY_KEY" \
  git clone --branch "$HYDRA_HEAD_GIT_BRANCH" "$HYDRA_HEAD_GIT_REPO_URL" "$HYDRA_HEAD_DIR"
cd "$HYDRA_HEAD_DIR"

# Install PostgreSQL
${BOOTSTRAP_DIR}/install_postgresql.sh $PLATFORM $BOOTSTRAP_DIR

# Move config/secrets.yml file into place
$RUN_AS_INSTALLUSER cp ${BOOTSTRAP_DIR}/files/secrets.yml "$HYDRA_HEAD_DIR/config/secrets.yml"

# Setup the application
if [ "$APP_ENV" = "production" ]; then
  $RUN_AS_INSTALLUSER bundle install --without development test
else
  $RUN_AS_INSTALLUSER bundle install
fi
# Be sure to run db:schema:load on initial install only as it will delete existing data
$RUN_AS_INSTALLUSER RAILS_ENV=${APP_ENV} bundle exec rake db:schema:load
$RUN_AS_INSTALLUSER RAILS_ENV=${APP_ENV} bundle exec rake db:seed
$RUN_AS_INSTALLUSER RAILS_ENV=${APP_ENV} bundle exec rake datarepo:add_roles
if [ -f ${BOOTSTRAP_DIR}/files/user_list.txt ]; then
  $RUN_AS_INSTALLUSER cp "${BOOTSTRAP_DIR}/files/user_list.txt" "${HYDRA_HEAD_DIR}/user_list.txt"
  $RUN_AS_INSTALLUSER RAILS_ENV=${APP_ENV} bundle exec rake datarepo:populate_users
  $RUN_AS_INSTALLUSER rm "${HYDRA_HEAD_DIR}/user_list.txt"
fi
if [ -f ${BOOTSTRAP_DIR}/files/admin_list.txt ]; then
  $RUN_AS_INSTALLUSER cp "${BOOTSTRAP_DIR}/files/admin_list.txt" "${HYDRA_HEAD_DIR}/admin_list.txt"
  $RUN_AS_INSTALLUSER RAILS_ENV=${APP_ENV} bundle exec rake datarepo:upgrade_users
  $RUN_AS_INSTALLUSER rm "${HYDRA_HEAD_DIR}/admin_list.txt"
fi

# Application Deployment steps.
if [ "$APP_ENV" = "production" ]; then
    $RUN_AS_INSTALLUSER RAILS_ENV=${APP_ENV} bundle exec rake assets:precompile
fi

# Fix up configuration files
# Set Google Analytics ID, if supplied and we aren't installing via Vagrant
if [ -f ${BOOTSTRAP_DIR}/files/google_analytics_id -a $PLATFORM != "vagrant" ]; then
  # Uncomment config.google_analytics_id setting
  $RUN_AS_INSTALLUSER sed -i "s/# config.google_analytics_id/config.google_analytics_id/" "$HYDRA_HEAD_DIR/config/initializers/sufia.rb"
  # Set config.google_analytics_id to the one in ${BOOTSTRAP_DIR}/files/google_analytics_id
  $RUN_AS_INSTALLUSER sed -i "s/config.google_analytics_id = '.*'/config.google_analytics_id = '$(cat ${BOOTSTRAP_DIR}/files/google_analytics_id)'/" "$HYDRA_HEAD_DIR/config/initializers/sufia.rb"
fi
