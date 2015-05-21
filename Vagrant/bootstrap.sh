#!/usr/bin/env bash
set -o errexit

# For Ubuntu Server 14_04
# Installs the default Sufia application and all of it's dependencies.

# Vars
basedir="/home/vagrant"
fitsdir="$basedir/fits" # Where FITS will be installed.
hydrahead="$1" # Name of the Hydra head. Supplied by the Vagrantfile
hydradir="$basedir/$hydrahead" # Where the Hydra head will be located.
gitrepo="$2" # The git repository to pull changes from during setup. Supplied by the Vagrantfile.

fitsver="fits-0.6.2" # The version of FITS to install.
rubyver="ruby2.2" # The version of Ruby to install.
railsver=">=4.2" # The version of Rails to install.
sufiaver="6.0.0" # The version of Sufia to install.

# Update packages
cd "$basedir/"
sudo apt-get update
sudo apt-get upgrade -y

# Install Ruby
# Brightbox also packages Passenger, which will be useful for production.
sudo add-apt-repository -y ppa:brightbox/ruby-ng
sudo apt-get update
sudo apt-get install -y "$rubyver"

# Install FITS
sudo apt-get install -y openjdk-7-jdk unzip
mkdir -p "$fitsdir/"
cd "$fitsdir/"
wget --quiet "http://projects.iq.harvard.edu/files/fits/files/$fitsver.zip"
unzip -q "$fitsdir/$fitsver.zip"
sudo chmod a+x "$fitsdir/$fitsver/fits.sh"
cd "$basedir/"

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

# Create Hydra head
sudo apt-get install -y "$rubyver-dev" git sqlite3 libsqlite3-dev zlib1g-dev build-essential
sudo gem install --no-document rails -v "$railsver"
rails new "$hydrahead" "$hydradir"

# Add and set up Sufia
cd "$hydradir/"
echo "gem 'sufia', '$sufiaver'" >> "$hydradir/Gemfile"
echo "gem 'kaminari', github: 'jcoyne/kaminari', branch: 'sufia'" >> "$hydradir/Gemfile"
bundle install
rails generate sufia:install -f
bundle exec rake db:migrate

# Download and configure Jetty
bundle exec rake jetty:clean sufia:jetty:config

# Pull from git. This fixes application configuration 
git init
git remote add origin "https://github.com/$gitrepo.git"
git fetch --all
git reset --hard origin/master
bundle install
