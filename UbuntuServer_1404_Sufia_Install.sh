#!/usr/bin/env bash
set -o errexit

# This script requires git. I assume you used it to get the script.

# 0. Vars
fitsdir="~/fits" # Where FITS will be installed.
demodir="~/sebdemo" # Where the Sufia head will live.

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
wget http://projects.iq.harvard.edu/files/fits/files/fits-0.8.3.zip
unzip ./fits-0.8.3.zip
sudo chmod a+x "$fitsdir/fits-0.8.3/fits.sh"
cd ~/
# TODO: Replace below with something more appropriate.
export PATH="$fitsdir/fits-0.8.3:$PATH"

# 4. Install ffmpeg
# Instructions from the static builds link on this page: https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu
sudo add-apt-repository -y ppa:mc3man/trusty-media
sudo apt-get update
sudo apt-get install -y ffmpeg

# 5. Install Redis, ImageMagick, Node.js, PhantomJS, and Libre Office
sudo apt-get install -y redis-server imagemagick nodejs phantomjs libreoffice

# 6. Install Rails
sudo apt-get install -y ruby2.1-dev libsqlite3-dev make
git clone https://github.com/projecthydra/sufia ~/sufia/
cd ~/sufia/
git checkout fedora-4/master
sudo gem install bundler
bundle install

# N. TODO
sudo gem install --no-document rails --version 4.1.7
rails new sebdemo "$demodir/"
cd "$demodir/"

# 7. Set up Sufia
echo "gem 'kaminari', github: 'harai/kaminari', branch: 'route_prefix_prototype'" >> ~/sebdemo/Gemfile
echo "gem 'sufia', github: 'projecthydra/sufia', branch: 'fedora-4/master'" >> ~/sebdemo/Gemfile
echo "gem 'hydra-head', github: 'projecthydra/hydra-head', branch:'fedora-4'" >> ~/sebdemo/Gemfile
echo "gem 'active-fedora', github: 'projecthydra/active_fedora', branch: 'fedora-4'" >> ~/sebdemo/Gemfile
echo "gem 'hydra-collections', github: 'projecthydra/hydra-collections', branch: 'fedora-4'" >> ~/sebdemo/Gemfile
echo "gem 'hydra-derivatives', github: 'projecthydra-labs/hydra-derivatives', branch: 'fedora-4'" >> ~/sebdemo/Gemfile
#echo "gem 'font-awesome-sass-rails'" >> ~/sebdemo/Gemfile

bundle install
rails g sufia -f
rake db:migrate
sed 's/require_tree ./require sufia/' <~/vtw2/app/assets/stylesheets/application.css >~/vtw2/temp
mv ~/vtw2/temp ~/vtw2/app/assets/stylesheets/application.css
sed '/\/\/= require turbolinks/ d' <~/vtw2/app/assets/javascripts/application.js > ~/vtw2/temp
echo '//= require sufia' >> ~/vtw2/temp
mv ~/vtw2/temp ~/vtw2/app/assets/javascripts/application.js

# 8. Fix stylesheets.
#gemdir=`gem environment gemdir`
#gemdir="$gemdir/gems/sufia-3.7.2/app/assets/stylesheets"
#sed -r "s/url\(<%= asset_path ('fonts.*') %>\)/asset_url(\1)/" \
#<"$gemdir/applcation-bootstrap.css.erb" >~/vtw2/app/assets/stylesheets/application-bootstrap.css.erb
#sed -r "s/url\(<%= asset_path ('vjs.*') %>\)/asset_url(\1)/" \
#<"$gemdir/video-js.css.erb" >~/vtw2/app/assets/stylesheets/video-js.css.erb

# 9. Start Sufia server.
QUEUE=* rake resque:work &
rake jetty:clean
rake jetty:config
rake jetty:start
rails s
