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

# Install Java 8 and make it the default Java
add-apt-repository -y ppa:webupd8team/java
apt-get update -y
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections
apt-get install -y oracle-java8-installer
update-java-alternatives -s java-8-oracle

# Install FITS
apt-get install -y unzip
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

# Setup the application

# 1. Create a migration: rails generate migration CreateDoiRequests
$RUN_AS_INSTALLUSER bundle exec rails generate migration CreateDoiRequests
DOI_MIGRATION_FILE=`find db/migrate -type f -name '*_create_doi_requests.rb'|sort|tail -1`
# 2. Replace the contents of the new migration with this gist: https://gist.github.com/tingtingjh/ab35348f493d565cdcc8
$RUN_AS_INSTALLUSER cat > $DOI_MIGRATION_FILE <<GIST
class CreateDoiRequests < ActiveRecord::Migration
  def change
    create_table :doi_requests do |t|
      t.string "collection_id"
      t.string "ezid_doi", default: "doi:pending", null: false
      t.string "asset_type", default: "Collection", null: false
      t.boolean "completed", default: false
      t.timestamps null: false
    end
    add_index :doi_requests, :ezid_doi
    add_index :doi_requests, :collection_id
  end
end
GIST
# 3. Generate Role model: rails generate roles
$RUN_AS_INSTALLUSER bundle exec rails generate roles
# 4. Remove the before filter added to app/controllers/application_controller.rb
$RUN_AS_INSTALLUSER sed -i '/^  before_filter do$/,/^  end$/d' app/controllers/application_controller.rb
# 5. Migrate
$RUN_AS_INSTALLUSER bundle exec rake db:migrate
# 6. Create default roles and an admin user
$RUN_AS_INSTALLUSER bundle exec rake datarepo:setup_defaults
# 7. Install Orcid
$RUN_AS_INSTALLUSER bundle exec rails generate orcid:install --skip-application-yml
# 8. Revert changes already incorporated
$RUN_AS_INSTALLUSER git checkout ./app/models/user.rb ./config/routes.rb
