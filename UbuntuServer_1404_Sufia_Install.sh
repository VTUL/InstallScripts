#!/usr/bin/env bash
set -o errexit

# 1. Update packages
cd ~
sudo apt-get update
sudo apt-get upgrade -y

# 2. Install rbenv and ruby-build
# You should have git to get this script.
git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
cd ~/.rbenv
git checkout v0.4.0
cd ~
git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
cd ~/.rbenv/plugins/ruby-build
git checkout v20141028
cd ~
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

# 3. Install Ruby
sudo apt-get install -y gcc make libssl-dev
rbenv install 2.1.4
rbenv global 2.1.4
rbenv rehash

# 4. Install Redis, ImageMagick, Node.js, PhantomJS, and Libre Office
sudo apt-get install -y redis-server imagemagick nodejs phantomjs libreoffice

# 5. Install FITS
sudo apt-get install -y default-jdk unzip
mkdir ~/fits/
cd ~/fits/
wget http://projects.iq.harvard.edu/files/fits/files/fits-0.8.3.zip
unzip ./fits-0.8.0.zip
sudo chmod a+x ~/fits/fits-0.8.3/fits.sh
cd ~/
echo 'export PATH="$HOME/fits/fits-0.8.3:$PATH"' >> ~/.bashrc
export PATH="$HOME/fits/fits-0.8.3:$PATH"

# 6. Install ffmpeg
# Instructions from the static builds link on this page: https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu
sudo add-apt-repository -y ppa:mc3man/trusty-media
sudo apt-get update
sudo apt-get install -y ffmpeg

# 7. Install Rails
sudo apt-get install -y libsqlite3-dev
gem install --no-document rails --version 4.1.7
rbenv rehash
rails new vtw2
cd ~/vtw2/

# 8. Set up Sufia
sudo apt-get install -y g++
# TODO: Update, expand gems for Fedora 4
echo "gem 'sufia', '3.7.2" >> ~/vtw2/Gemfile
echo "gem 'kaminari', github: 'harai/kaminari', branch: 'route_prefix_prototype'" >> ~/vtw2/Gemfile
echo "gem 'font-awesome-sass-rails'" >> ~/vtw2/Gemfile
bundle install
rbenv rehash
rails g sufia -f
rbenv rehash
rake db:migrate
sed 's/require_tree ./require sufia/' <~/vtw2/app/assets/stylesheets/application.css >~/vtw2/temp
mv ~/vtw2/temp ~/vtw2/app/assets/stylesheets/application.css
sed '/\/\/= require turbolinks/ d' <~/vtw2/app/assets/javascripts/application.js > ~/vtw2/temp
echo '//= require sufia' >> ~/vtw2/temp
mv ~/vtw2/temp ~/vtw2/app/assets/javascripts/application.js

# 9. Fix stylesheets.
gemdir=`gem environment gemdir`
gemdir="$gemdir/gems/sufia-3.7.2/app/assets/stylesheets"
sed -r "s/url\(<%= asset_path ('fonts.*') %>\)/asset_url(\1)/" \
<"$gemdir/applcation-bootstrap.css.erb" >~/vtw2/app/assets/stylesheets/application-bootstrap.css.erb
sed -r "s/url\(<%= asset_path ('vjs.*') %>\)/asset_url(\1)/" \
<"$gemdir/video-js.css.erb" >~/vtw2/app/assets/stylesheets/video-js.css.erb

# 10. Start Sufia server.
sudo apt-get install -y default-jre
QUEUE=* rake resque:work &
rake jetty:clean
rake jetty:config
rake jetty:start
rails s