#!/bin/sh

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

# Install FITS
apt-get install -y unzip
$RUN_AS_INSTALLUSER mkdir -p $FITS_DIR
cd "$FITS_DIR"
$RUN_AS_INSTALLUSER wget --quiet "http://projects.iq.harvard.edu/files/fits/files/${FITS_PACKAGE}.zip"
$RUN_AS_INSTALLUSER unzip -q ${FITS_DIR}/${FITS_PACKAGE}.zip
chmod a+x ${FITS_DIR}/${FITS_PACKAGE}/fits.sh
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
# Install the Phusion Passenger APT repository
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7
#sudo apt-get install apt-transport-https ca-certificates # Not necessary for 14_04, but part of the Phusion Docs.
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
gem install --no-document rails -v "$RAILS_VERSION"
$RUN_AS_INSTALLUSER rails new $HYDRA_HEAD $HYDRA_HEAD_DIR
$RUN_AS_INSTALLUSER rm "$HYDRA_HEAD_DIR/README.rdoc"

# Pull from git. This fixes application configuration
cd $HYDRA_HEAD_DIR
$RUN_AS_INSTALLUSER git init
$RUN_AS_INSTALLUSER git remote add origin "https://github.com/$HYDRA_HEAD_GIT_REPO.git"
$RUN_AS_INSTALLUSER git fetch --all
$RUN_AS_INSTALLUSER git reset --hard origin/master
$RUN_AS_INSTALLUSER git branch --set-upstream-to=remotes/origin/master master
$RUN_AS_INSTALLUSER git checkout "$HYDRA_HEAD_GIT_BRANCH"

# Setup the application
$RUN_AS_INSTALLUSER bundle install
$RUN_AS_INSTALLUSER rake db:migrate
$RUN_AS_INSTALLUSER bundle exec rake datarepo:setup_defaults

# Application Deployment steps.
if [ "$APP_ENV" = "production" ]; then
    $RUN_AS_INSTALLUSER bundle install --deployment --without development test
    # Deploy production ORCID secrets from ${BOOTSTRAP_DIR}/files/orcid_secrets if they exist unless installing via Vagrant
    if [ -f ${BOOTSTRAP_DIR}/files/orcid_secrets -a $PLATFORM != "vagrant" ]; then
      # Remove any existing active ORCID settings from application.yml
      $RUN_AS_INSTALLUSER sed -i -r '/^[[:space:]]*ORCID_.*$/d' "$HYDRA_HEAD_DIR/config/application.yml"
      # Append contents of ${BOOTSTRAP_DIR}/files/orcid_secrets to application.yml
      $RUN_AS_INSTALLUSER cat "${BOOTSTRAP_DIR}/files/orcid_secrets" >> "$HYDRA_HEAD_DIR/config/application.yml"
    else
      echo 'Warning: No production orcid_secrets file supplied; using defaults!'
    fi
    # Point to production CAS
    $RUN_AS_INSTALLUSER sed -i 's/config.omniauth \(.*\)cas-dev.middleware.vt.edu/config.omniauth \1auth.vt.edu/' "$HYDRA_HEAD_DIR/config/initializers/devise.rb"
    # Install Application secret key
    $RUN_AS_INSTALLUSER sed --in-place=".bak" --expression="s|<%= ENV\[\"SECRET_KEY_BASE\"\] %>|$(bundle exec rake secret)|" "$HYDRA_HEAD_DIR/config/secrets.yml"
    $RUN_AS_INSTALLUSER RAILS_ENV=production bundle exec rake db:setup
    $RUN_AS_INSTALLUSER RAILS_ENV=production bundle exec rake assets:precompile
    $RUN_AS_INSTALLUSER RAILS_ENV=production bundle exec rake datarepo:setup_defaults
fi
# Fix up configuration files
# 1. FITS
$RUN_AS_INSTALLUSER sed -i "s@config.fits_path = \".*\"@config.fits_path = \"$FITS_DIR/$FITS_PACKAGE/fits.sh\"@" config/initializers/sufia.rb
# 2. Set Google Analytics ID, if supplied and we aren't installing via Vagrant
if [ -f ${BOOTSTRAP_DIR}/files/google_analytics_id -a $PLATFORM != "vagrant" ]; then
  # Uncomment config.google_analytics_id setting
  $RUN_AS_INSTALLUSER sed -i "s/# config.google_analytics_id/config.google_analytics_id/" "$HYDRA_HEAD_DIR/config/initializers/sufia.rb"
  # Set config.google_analytics_id to the one in ${BOOTSTRAP_DIR}/files/google_analytics_id
  $RUN_AS_INSTALLUSER sed -i "s/config.google_analytics_id = '.*'/config.google_analytics_id = '$(cat ${BOOTSTRAP_DIR}/files/google_analytics_id)'/" "$HYDRA_HEAD_DIR/config/initializers/sufia.rb"
fi
# 3. Make the solr.yml file point to an appropriate $APP_ENV core
sed -i '/production:/ {N; s@^production:.*development@production:\n  url: http://localhost:8983/solr/production@}' config/solr.yml
# 4. Make the blacklight.yml file point to an appropriate $APP_ENV core
sed -i '/production:/ {N; N; s@^production:\(.*\)/development@production:\1/production@}' config/blacklight.yml
# 5. Make the fedora.yml point to Tomcat 7 port, not to hydra-jetty port 8983
sed -i 's/url:\(.*\):8983/url:\1:8080/' config/fedora.yml
