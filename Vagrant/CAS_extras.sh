# Run after first provisioning.
basedir="/home/vagrant"
hydrahead="$1"
hydradir="$basedir/$hydrahead"
servername="$2"

# Install Nginx and Passenger.
cd "$basedir/"
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7
#sudo apt-get install apt-transport-https ca-certificates # Not necessary for 14_04, but part of the Phusion Docs.
echo "deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main" >> "$basedir/passenger.list"
sudo mv -f "$basedir/passenger.list" "/etc/apt/sources.list.d/passenger.list"
sudo chown root: "/etc/apt/sources.list.d/passenger.list"
sudo chmod 600 "/etc/apt/sources.list.d/passenger.list"
sudo apt-get update
sudo apt-get install -y nginx-extras passenger
cp "/etc/nginx/nginx.conf" "$basedir/nginx.conf.bak"
sed "s/# passenger_root/passenger_root/" <"$basedir/nginx.conf.bak" >"$basedir/nginx.conf.bak2"
sed "s/# passenger_ruby/passenger_ruby/" <"$basedir/nginx.conf.bak2" >"$basedir/nginx.conf.bak3"
sed "1ienv PATH;" <"$basedir/nginx.conf.bak3" >"$basedir/nginx.conf"
sudo mv -f "$basedir/nginx.conf" "/etc/nginx/nginx.conf"
rm "$basedir/nginx.conf.bak2"
rm "$basedir/nginx.conf.bak3"
sudo chown root: "/etc/nginx/nginx.conf"
sudo chmod 644 "/etc/nginx/nginx.conf"
sudo unlink "/etc/nginx/sites-enabled/default"
sudo service nginx restart

# Configure Passenger to serve our site.
sudo mkdir -p /etc/ssl/local/certs
sudo mkdir -p /etc/ssl/local/private

cat >> "$basedir/$hydrahead.site" <<HereDoc
server {
    listen 8080;
    listen 4433 ssl;
    root $hydradir/public;
    passenger_enabled on;
    server_name $servername;
    ssl_certificate /etc/ssl/local/certs/$hydrahead.crt;
    ssl_certificate_key /etc/ssl/local/private/$hydrahead.key;
}
HereDoc

sudo mv -f "$basedir/$hydrahead.site" "/etc/nginx/sites-available/$hydrahead.site"
sudo chown root: "/etc/nginx/sites-available/$hydrahead.site"
sudo chmod 644 "/etc/nginx/sites-available/$hydrahead.site"
sudo link "/etc/nginx/sites-available/$hydrahead.site" "/etc/nginx/sites-enabled/$hydrahead.site"
sudo service nginx restart
echo "That was expected to fail!"

# Application Deployment steps.
cd "$hydradir"
bundle install
rails g migration AddOmniauthToUsers provider uid
rake db:migrate
bundle install --deployment --without development test
sed --in-place=".bak" --expression="s|<%= ENV\[\"SECRET_KEY_BASE\"\] %>|$(bundle exec rake secret)|" "$hydradir/config/secrets.yml"
RAILS_ENV=production bundle exec rake db:setup
RAILS_ENV=production bundle exec rake assets:precompile
RAILS_ENV=production bundle exec rake datarepo:setup_defaults
bash "$hydradir/scripts/restart_resque.sh production"
touch "$hydradir/tmp/restart.txt"

echo "run the following command to generate a self-signed cert:"
echo "sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/local/private/$hydrahead.key -out /etc/ssl/local/certs/$hydrahead.crt"
echo "You'll need to restart Nginx, too:"
echo "sudo service nginx restart"
