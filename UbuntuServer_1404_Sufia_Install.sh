#!/usr/bin/env bash
set -o errexit

# For Ubuntu Server 14_04
# Installs the default Sufia application and all of it's dependencies.
# Runs the application with Passenger/Nginx in production mode.

# Vars
fitsdir="$HOME/fits" # Where FITS will be installed.
fitsver="fits-0.6.2" # Which version of FITS to install.
hydrahead="sufiademo" # Name of the Hydra head.
hydradir="$HOME/$hydrahead" # Where the Hydra head will be located.

# Update packages
cd ~
sudo apt-get update
sudo apt-get upgrade -y

# Install Ruby 2.2
# Brightbox also packages Passenger, which will be useful for production.
sudo add-apt-repository -y ppa:brightbox/ruby-ng
sudo apt-get update
sudo apt-get install -y ruby2.2

# Install FITS
sudo apt-get install -y openjdk-7-jdk unzip
mkdir -p "$fitsdir/"
cd "$fitsdir/"
wget "http://projects.iq.harvard.edu/files/fits/files/$fitsver.zip"
unzip "$fitsdir/$fitsver.zip"
sudo chmod a+x "$fitsdir/$fitsver/fits.sh"
cd "$HOME/"

# Install ffmpeg
# Instructions from the static builds link on this page: https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu
sudo add-apt-repository -y ppa:mc3man/trusty-media
sudo apt-get update
sudo apt-get install -y ffmpeg

# Install nodejs from Nodesource
curl -sL https://deb.nodesource.com/setup | sudo bash -
sudo apt-get install -y nodejs

# Install Redis, ImageMagick, PhantomJS, and Libre Office
sudo apt-get install -y redis-server imagemagick phantomjs libreoffice

# Create Hydra head.
sudo apt-get install -y ruby2.2-dev git sqlite3 libsqlite3-dev zlib1g-dev build-essential
sudo gem install --no-document rails -v '>=4.2'
rails new "$hydrahead" "$hydradir"

# Add and set up Sufia
cd "$hydradir"
echo "gem 'sufia', '6.0.0'" >> "$hydradir/Gemfile"
echo "gem 'kaminari', github: 'jcoyne/kaminari', branch: 'sufia'" >> "$hydradir/Gemfile"
bundle install
rails generate sufia:install -f
bundle exec rake db:migrate

# Download and configure Jetty
bundle exec rake jetty:clean
bundle exec rake sufia:jetty:config

# Fix Hydra head configs.
# Point to FITS at our location.
sed "s/# config.fits_path = \"fits.sh\"/config.fits_path = \"$fitsdir\/$fitsver\/fits.sh\"/" \
<"$hydradir/config/initializers/sufia.rb" >"$hydradir/temp"
mv "$hydradir/temp" "$hydradir/config/initializers/sufia.rb"
# Replace 'require tree' with 'require sufia' in the head's CSS template.
sed "s/require_tree ./require sufia/" <"$hydradir/app/assets/stylesheets/application.css" >"$hydradir/temp"
mv "$hydradir/temp" "$hydradir/app/assets/stylesheets/application.css"
# Remove turbolinks and add sufia to the head's JS template.
sed "/\/\/= require turbolinks/ d" <"$hydradir/app/assets/javascripts/application.js" >"$hydradir/temp"
echo "//= require sufia" >> "$hydradir/temp"
mv "$hydradir/temp" "$hydradir/app/assets/javascripts/application.js"

# Start the components.
bundle exec rake jetty:start

# For a development server, stop here and run:
#QUEUE=* rake environment resque:work &
#bundle exec rails server
# The server will start on port 3000.

# Install Nginx and Passenger.
cd "$HOME/"
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7
#sudo apt-get install apt-transport-https ca-certificates # Not necessary for 14_04, but part of the Phusion Docs.
echo "deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main" >> "$HOME/passenger.list"
sudo mv -f "$HOME/passenger.list" "/etc/apt/sources.list.d/passenger.list"
sudo chown root: "/etc/apt/sources.list.d/passenger.list"
sudo chmod 600 "/etc/apt/sources.list.d/passenger.list"
sudo apt-get update
sudo apt-get install -y nginx-extras passenger
cp "/etc/nginx/nginx.conf" "$HOME/nginx.conf.bak"
sed "s/# passenger_root/passenger_root/" <"$HOME/nginx.conf.bak" >"$HOME/tmp"
sed "s/# passenger_ruby/passenger_ruby/" <"$HOME/tmp" >"$HOME/nginx.conf"
sudo mv -f "$HOME/nginx.conf" "/etc/nginx/nginx.conf"
rm "$HOME/tmp"
sudo chown root: "/etc/nginx/nginx.conf"
sudo chmod 644 "/etc/nginx/nginx.conf"
sudo unlink "/etc/nginx/sites-enabled/default"
sudo service nginx restart

# Configure Passenger to serve our site.
cat >> "$HOME/sufia.site" <<HereDoc
server {
    listen 80;
    root $hydradir/public;
    passenger_enabled on;
}
HereDoc

sudo mv -f "$HOME/sufia.site" "/etc/nginx/sites-available/sufia.site"
sudo chown root: "/etc/nginx/sites-available/sufia.site"
sudo chmod 644 "/etc/nginx/sites-available/sufia.site"
sudo link "/etc/nginx/sites-available/sufia.site" "/etc/nginx/sites-enabled/sufia.site"
sudo service nginx restart

# Application Deployment steps.
cd "$hydradir"
bundle install --deployment --without development test
sed "s/<%= ENV\[\"SECRET_KEY_BASE\"\] %>/$(bundle exec rake secret)" \
<"$hydradir/confing/secrets.yml" >"$hydradir/temp"
mv "$hydradir/temp" "$hydradir/config/secrets.yml"
RAILS_ENV=production bundle exec rake db:setup
RAILS_ENV=production bundle exec rake assets:precompile
sed "s|your.production.server:8080/bl_solr/core0|localhost:8983/solr/development|" \
<"$hydradir/config/solr.yml" >"$hydradir/temp"
mv "$hydradir/temp" "$hydradir/config/solr.yml"
sed "s/Resque.redis.namespace/#Resque.redis.namespace/" \
<"$hydradir/config/initializers/resque_config.rb" >"$hydradir/temp"
mv "$hydradir/temp" "$hydradir/config/initializers/resque_config.rb"
touch "$hydradir/tmp/restart.txt"

RAILS_ENV=production QUEUE='*' bundle exec rake resque:work &
