#!/bin/sh
# Bootstrap application on server.
#
# This script takes two arguments: the install environment ("vagrant" or "aws")
# and the path to where these install scripts live on the server being
# provisioned.
set -x -o errexit

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

# Update packages
cd "$INSTALL_DIR"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade

# Install Fedora 4
${SCRIPTS_DIR}/install_fedora4.sh $PLATFORM $SCRIPTS_DIR

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
# Required-Start:    $remote_fs $syslog redis-server
# Required-Stop:     $remote_fs $syslog redis-server
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
  sudo -H -u $INSTALL_USER bundle exec resque-pool --daemon --environment $APP_ENV --pidfile \$RESQUE_POOL_PIDFILE
}

stop() {
  [ -f \$RESQUE_POOL_PIDFILE ] && kill -QUIT \$(cat \$RESQUE_POOL_PIDFILE)
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
