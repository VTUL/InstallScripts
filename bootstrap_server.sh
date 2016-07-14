#!/bin/bash
set -o errexit -o nounset -o xtrace -o pipefail
# Bootstrap application on server.
#
# This script takes two arguments: the install environment ("vagrant" or "aws")
# and the path to where these install scripts live on the server being
# provisioned.

# Validate command line arguments
if [ $# -ne 2 ]; then
  echo "Error: wrong number of arguments to $0 (expected 2, got $#)"
  echo "Usage: $0 vagrant|aws /path/to/install/scripts"
  exit 1
fi
PLATFORM=$1
SCRIPTS_DIR=$2
if [ $PLATFORM != "vagrant" -a $PLATFORM != "aws" ]; then
  echo "Invalid server environment: $PLATFORM"
  exit 1
fi

# Read settings and environmental overrides
[ -f "${SCRIPTS_DIR}/config.sh" ] && . "${SCRIPTS_DIR}/config.sh"
[ -f "${SCRIPTS_DIR}/config_${PLATFORM}.sh" ] && . "${SCRIPTS_DIR}/config_${PLATFORM}.sh"

# Make sure files in scripts are accessible
chmod 511 "$SCRIPTS_DIR"

# Update packages
cd "$INSTALL_DIR"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade

# Install Fedora 4
${SCRIPTS_DIR}/install_fedora4.sh $PLATFORM $SCRIPTS_DIR

# Install and configure Postfix to send e-mail
echo "postfix postfix/mailname string $SERVER_HOSTNAME" | debconf-set-selections
echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections
apt-get install -y postfix
cat > /etc/postfix/main.cf <<POSTFIX_CONF
myorigin = $SERVER_HOSTNAME
smtpd_banner = \$myhostname ESMTP \$mail_name
biff = no
append_dot_mydomain = no
readme_directory = no
smtp_tls_security_level = may
smtp_tls_ciphers = export
smtp_tls_protocols = !SSLv2, !SSLv3
smtp_tls_session_cache_database = btree:\${data_directory}/smtp_scache
smtpd_tls_session_cache_database = btree:\${data_directory}/smtpd_scache
smtpd_relay_restrictions = permit_mynetworks permit_sasl_authenticated defer_unauth_destination
myhostname = \$myorigin
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
mydestination = $SERVER_HOSTNAME, localhost.localdomain, localhost
relayhost =
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
mailbox_size_limit = 0
recipient_delimiter = +
inet_interfaces = localhost
inet_protocols = ipv4
POSTFIX_CONF
service postfix restart

# Install ClamAV
${SCRIPTS_DIR}/install_clamav.sh $PLATFORM $SCRIPTS_DIR

# Install Sufia Data-Repo application
${SCRIPTS_DIR}/install_sufia_application.sh $PLATFORM $SCRIPTS_DIR

# Install Solr
${SCRIPTS_DIR}/install_solr.sh $PLATFORM $SCRIPTS_DIR

# Install Resque-pool service
cat > /etc/init.d/resque-pool <<END_OF_INIT_SCRIPT
#!/bin/sh
# Init script to start up resque-pool
# Warning: This script is auto-generated.

### BEGIN INIT INFO
# Provides: resque-pool
# Required-Start:    \$remote_fs \$syslog redis-server
# Required-Stop:     \$remote_fs \$syslog redis-server
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Description:       Controls Resque-Pool Service
### END INIT INFO

RESQUE_POOL_PIDFILE="${HYDRA_HEAD_DIR}/tmp/pids/resque-pool.pid"
DAEMON="/usr/local/bin/resque-pool"
# verify the specified run as user exists
runas_uid=\$(id -u $INSTALL_USER)
if [ \$? -ne 0 ]; then
  echo "User $INSTALL_USER not found! Please create the $INSTALL_USER user before running this script."
  exit 1
fi
. /lib/lsb/init-functions

start() {
  cd "${HYDRA_HEAD_DIR}"
  sudo -H -u $INSTALL_USER RAILS_ENV=${APP_ENV} RUN_AT_EXIT_HOOKS=true TERM_CHILD=1 bundle exec resque-pool --daemon --environment $APP_ENV --pidfile \$RESQUE_POOL_PIDFILE
}

stop() {
  if [ -f \$RESQUE_POOL_PIDFILE ]; then
    kill -QUIT \$(cat \$RESQUE_POOL_PIDFILE)
    while ps agx | grep resque | egrep -qv 'rc[0-9]\.d|init\.d|service|grep'; do sleep 1; done
  fi
}

case "\$1" in
  start)   start ;;
  stop)    stop ;;
  restart) stop
           sleep 1
           start
           ;;
  status)  status_of_proc -p "\$RESQUE_POOL_PIDFILE" "\$DAEMON" "resque-pool" && exit 0 || exit \$?
           ;;
  *)
    echo "Usage: \$0 {start|stop|restart|status}"
    exit
esac
END_OF_INIT_SCRIPT
chmod 755 /etc/init.d/resque-pool
chown root:root /etc/init.d/resque-pool
update-rc.d resque-pool defaults

# Start up services
echo "Starting services in $APP_ENV environment mode."
service resque-pool start
service tomcat7 start
service solr start
service nginx start

# Add developer files to the machine.
if [ "$APP_ENV" = "development" ]; then
    ${SCRIPTS_DIR}/developer_setup.sh $PLATFORM $SCRIPTS_DIR
fi
