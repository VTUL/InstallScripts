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
sudo apt-get install -y ruby2.1-dev

# 3. Install FITS
sudo apt-get install -y openjdk-7-jdk unzip
mkdir "$fitsdir/"
cd "$fitsdir/"
wget "http://projects.iq.harvard.edu/files/fits/files/$fitsver.zip"
unzip "./$fitsver.zip"
sudo chmod a+x "$fitsdir/$fitsver/fits.sh"
cd ~/

# 4. Install ffmpeg
# Instructions from the static builds link on this page: https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu
sudo add-apt-repository -y ppa:mc3man/trusty-media
sudo apt-get update
sudo apt-get install -y ffmpeg

# 5. Install Redis, ImageMagick, Node.js, PhantomJS, and Libre Office
sudo apt-get install -y redis-server imagemagick nodejs phantomjs libreoffice

# 6. Create Hydra head.
sudo apt-get install -y git libsqlite3-dev zlib1g-dev build-essential
sudo gem install --no-document rails -v 4.1.8
rails new "$hydrahead" "$hydradir"

# 7. Add and set up Sufia
cd "$hydradir"
echo "gem 'sufia', '6.0.0.rc2'" >> "$hydradir/Gemfile"
echo "gem 'kaminari', github: 'harai/kaminari', branch: 'route_prefix_prototype'" >> "$hydradir/Gemfile"
bundle install
# TODO: Remove next 'sudo gem install X' lines when the final version is released
sudo gem install --no-document devise-guests -v 0.3.3
sudo gem install --no-document rspec-rails
rails generate sufia:install -f
rake db:migrate

#8. Download and configure Jetty
bundle exec rake jetty:clean
bundle exec rake sufia:jetty:config

#9. Fix Hydra head configs.
# Point to FITS at our location.
sed "s/# config.fits_path = \"fits.sh\"/config.fits_path = \"$fitsdir\/$fitsver\/fits.sh\"/" \
<"$hydradir/config/initializers/sufia.rb" >"$hydradir/temp"
mv "$hydradir/temp" "$hydradir/config/initializers/sufia.rb"
# Replace 'require tree' with 'require sufia' in the head's CSS template.
sed 's/require_tree ./require sufia/' <"$hydradir/app/assets/stylesheets/application.css" >"$hydradir/temp"
mv "$hydradir/temp" "$hydradir/app/assets/stylesheets/application.css"
# Remove turbolinks and add sufia to the head's JS template.
sed '/\/\/= require turbolinks/ d' <"$hydradir/app/assets/javascripts/application.js" >"$hydradir/temp"
echo '//= require sufia' >> "$hydradir/temp"
mv "$hydradir/temp" "$hydradir/app/assets/javascripts/application.js"

#10. Start the components.
bundle exec rake jetty:start
QUEUE=* rake environment resque:work &

#11. Install set up and use Apache and Passenger.
sudo apt-get install -y apache2 libapache2-mod-passenger
# TODO: Add below to /etc/apache2/apache2.conf
#<VirtualHost *:80>
#    DocumentRoot $hydradir
#    <Directory $hydradir>
#        Allow from all
#        Options -MultiViews
#        Require all granted
#    </Directory>
#</VirtualHost>
sudo service apache2 restart
