#!/usr/bin/env bash
set -o errexit

# 0. Vars
fitsdir="$HOME/fits" # Where FITS will be installed.
fitsver="fits-0.8.3" # Which version of FITS to install.
hydrahead="sufiademo" # Name of the Hydra head.
hydradir="$HOME/$hydrahead" # Where the Hydra head will be located.

# 1. Update packages
cd ~
sudo apt-get update
sudo apt-get upgrade -y

# 2. Install Ruby 2.1
# Brightbox also packages Passenger, which will be useful for production.
sudo add-apt-repository -y ppa:brightbox/ruby-ng
sudo apt-get update
sudo apt-get install -y ruby2.1

# 3. Install FITS
sudo apt-get install -y openjdk-7-jdk unzip
mkdir "$fitsdir/"
cd "$fitsdir/"
wget "http://projects.iq.harvard.edu/files/fits/files/$fitsver.zip"
unzip "$fitsdir/$fitsver.zip"
sudo chmod a+x "$fitsdir/$fitsver/fits.sh"
cd "$HOME/"

# 4. Install ffmpeg
# Instructions from the static builds link on this page: https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu
sudo add-apt-repository -y ppa:mc3man/trusty-media
sudo apt-get update
sudo apt-get install -y ffmpeg

# 5. Install Redis, ImageMagick, Node.js, PhantomJS, and Libre Office
sudo apt-get install -y redis-server imagemagick nodejs phantomjs libreoffice

# 6. Create Hydra head.
sudo apt-get install -y ruby2.1-dev git libsqlite3-dev zlib1g-dev build-essential
sudo gem install --no-document rails -v 4.1.8
rails new "$hydrahead" "$hydradir"

# 7. Add and set up Sufia
cd "$hydradir"
echo "gem 'sufia', '6.0.0.rc2'" >> "$hydradir/Gemfile"
echo "gem 'kaminari', github: 'harai/kaminari', branch: 'route_prefix_prototype'" >> "$hydradir/Gemfile"
bundle install
rails generate sufia:install -f
bundle exec rake db:migrate

# 8. Download and configure Jetty
bundle exec rake jetty:clean
bundle exec rake sufia:jetty:config

# 9. Fix Hydra head configs.
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

# 10. Start the components.
bundle exec rake jetty:start
QUEUE=* rake environment resque:work &
cd "$HOME/"

# 11. Install Nginx and Passenger.
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

# 12. Configure Sufia to use Passenger.
echo "server {" >> "$HOME/sufia.site"
echo "    listen 80;" >> "$HOME/sufia.site"
echo "    root $hydradir;" >> "$HOME/sufia.site"
echo "    passenger_enabled on;" >> "$HOME/sufia.site"
echo "}" >> "$HOME/sufia.site"
sudo mv -f "$HOME/sufia.site" "/etc/nginx/sites-available/sufia.site"
sudo chown root: "/etc/nginx/sites-available/sufia.site"
sudo chmod 644 "/etc/nginx/sites-available/sufia.site"
sudo link "/etc/nginx/sites-available/sufia.site" "/etc/nginx/sites-enabled/sufia-site"
sudo service nginx restart
