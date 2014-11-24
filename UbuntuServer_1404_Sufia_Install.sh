#!/usr/bin/env bash
set -o errexit

# This script requires git. I assume you used it to get the script.

# 0. Vars
fitsdir="$HOME/fits" # Where FITS will be installed.
fitsver="fits-0.8.3" # Which version of FITS to install.
demodir="$HOME/sebdemo" # Where the Sufia head will live.

# 1. Update packages
cd ~
sudo apt-get update
sudo apt-get upgrade -y

# 2. Install Ruby 2.1.4
# Brightbox also packages Passenger, which will be useful for production.
sudo add-apt-repository -y ppa:brightbox/ruby-ng
sudo apt-get update
sudo apt-get install -y ruby2.1

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

# 6. Test Sufia
sudo apt-get install -y ruby2.1-dev libsqlite3-dev build-essential
git clone https://github.com/projecthydra/sufia ~/sufia/
cd ~/sufia/
git checkout fedora-4/master
sed "s/# config.fits_path = \"fits.sh\"/config.fits_path = \"$fitsdir\/$fitsver\/fits.sh\"/" \
<"$demodir/config/initializers/sufia.rb" >"$demodir/temp"
mv "$demodir/temp" "$demodir/config/initializers/sufia.rb"
sudo gem install bundler
bundle install
bundle exec rake jetty:clean
bundle exec rake sufia:jetty:config
bundle exec rake jetty:start
bundle exec rake engine_cart:generate
bundle exec rspec
