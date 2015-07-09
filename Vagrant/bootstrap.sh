#!/usr/bin/env bash
set -x -o errexit

# For Ubuntu Server 14_04
# Installs the default Sufia application and all of it's dependencies.
echo "Version 1.0"

# Vars
installuser="ubuntu" # Name of user to install under (must already exist)
hydrahead="data-repo" # Name of the Hydra head.
gitrepo="VTUL/data-repo" # The git repository to pull changes from during setup.
# Override installuser, hydrahead, and gitrepo via shell script arguments
if [ $# -ge 1 ]; then
  installuser="$1"
fi
if [ $# -ge 2 ]; then
  hydrahead="$2"
fi
if [ $# -ge 3 ]; then
  gitrepo="$3"
fi
basedir="/home/$installuser"
fitsdir="$basedir/fits" # Where FITS will be installed.
hydradir="$basedir/$hydrahead" # Where the Hydra head will be located.

fitsver="fits-0.6.2" # The version of FITS to install.
rubyver="ruby2.2" # The version of Ruby to install.
railsver=">=4.2" # The version of Rails to install.
sufiaver="6.0.0" # The version of Sufia to install.

RUN_AS_INSTALLUSER="sudo -H -u $installuser"

# Update packages
cd "$basedir/"
apt-get update
apt-get upgrade -y

# Install Ruby
# Brightbox also packages Passenger, which will be useful for production.
add-apt-repository -y ppa:brightbox/ruby-ng
apt-get update
apt-get install -y "$rubyver"

# Install FITS
apt-get install -y openjdk-7-jdk unzip
$RUN_AS_INSTALLUSER mkdir -p "$fitsdir/"
cd "$fitsdir/"
$RUN_AS_INSTALLUSER wget --quiet "http://projects.iq.harvard.edu/files/fits/files/$fitsver.zip"
$RUN_AS_INSTALLUSER unzip -q "$fitsdir/$fitsver.zip"
chmod a+x "$fitsdir/$fitsver/fits.sh"
cd "$basedir/"

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

# Create Hydra head
apt-get install -y "$rubyver-dev" git sqlite3 libsqlite3-dev zlib1g-dev build-essential
gem install --no-document rails -v "$railsver"
$RUN_AS_INSTALLUSER rails new "$hydrahead" "$hydradir"

# Add and set up Sufia
cd "$hydradir/"
$RUN_AS_INSTALLUSER echo "gem 'sufia', '$sufiaver'" >> "$hydradir/Gemfile"
$RUN_AS_INSTALLUSER echo "gem 'kaminari', github: 'jcoyne/kaminari', branch: 'sufia'" >> "$hydradir/Gemfile"
$RUN_AS_INSTALLUSER bundle install
$RUN_AS_INSTALLUSER rails generate sufia:install -f
$RUN_AS_INSTALLUSER bundle exec rake db:migrate

# Download and configure Jetty
$RUN_AS_INSTALLUSER bundle exec rake jetty:clean sufia:jetty:config

# Pull from git. This fixes application configuration
$RUN_AS_INSTALLUSER git init
$RUN_AS_INSTALLUSER git remote add origin "https://github.com/$gitrepo.git"
$RUN_AS_INSTALLUSER git fetch --all
$RUN_AS_INSTALLUSER git reset --hard origin/master
$RUN_AS_INSTALLUSER bundle install
