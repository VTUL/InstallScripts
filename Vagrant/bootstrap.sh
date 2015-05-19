#!/usr/bin/env bash
set -o errexit

# For Ubuntu Server 14_04
# Installs the default Sufia application and all of it's dependencies.

# Vars
fitsdir="$HOME/fits" # Where FITS will be installed.
fitsver="fits-0.6.2" # Which version of FITS to install.
hydrahead="data-repo" # Name of the Hydra head.
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
sudo gem install --no-document rails -v ">=4.2"
rails new "$hydrahead" "$hydradir"

# Add and set up Sufia
cd "$hydradir"
echo "gem 'sufia', '6.0.0'" >> "$hydradir/Gemfile"
echo "gem 'kaminari', github: 'jcoyne/kaminari', branch: 'sufia'" >> "$hydradir/Gemfile"
bundle install
rails generate sufia:install -f
bundle exec rake db:migrate

# Download and configure Jetty
bundle exec rake jetty:clean sufia:jetty:config

# Fix Hydra head configs.
# Point to FITS at our location.
sed --in-place=".bak" --expression="s|# config.fits_path = \"fits.sh\"|config.fits_path = \"$fitsdir/$fitsver/fits.sh\"|" \
"$hydradir/config/initializers/sufia.rb"
# Remove turbolinks.
sed --in-place=".bak" --expression="/\/\/= require turbolinks/ d" "$hydradir/app/assets/javascripts/application.js"

# Pull from git
cd "$hydradir"
git init
git remote add origin https://github.com/VTUL/data-repo.git
git fetch --all
git reset --hard origin/master
