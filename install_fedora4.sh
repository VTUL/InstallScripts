#!/bin/sh

# Install Fedora 4 from source

# Read settings and environmental overrides
# $1 = platform (aws or vagrant); $2 = path to install scripts
[ -f "${2}/config.sh" ] && . "${2}/config.sh"
[ -f "${2}/config_${1}.sh" ] && . "${2}/config_${1}.sh"

cd "$INSTALL_DIR"

# Install Java 8 and make it the default Java
add-apt-repository -y ppa:webupd8team/java
apt-get update -y
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections
apt-get install -y oracle-java8-installer
update-java-alternatives -s java-8-oracle

# Install Tomcat and Fedora 4
apt-get -y install tomcat7 tomcat7-admin
usermod -a -G tomcat7 $INSTALL_USER
# Stop Tomcat until everything is installed
service tomcat7 stop
# Create Fedora roles (taken from fcrepo4-labs/fcrepo4-vagrant project)
if ! grep -q "role rolename=\"fedoraAdmin\"" $TOMCAT_CONF/tomcat-users.xml ; then
  sed -i '$i<role rolename="fedoraUser"/>
  $i<role rolename="fedoraAdmin"/>
  $i<role rolename="manager-gui"/>
  $i<user username="testuser" password="password1" roles="fedoraUser"/>
  $i<user username="adminuser" password="password2" roles="fedoraUser"/>
  $i<user username="fedoraAdmin" password="fedoraAdmin" roles="fedoraAdmin"/>
  $i<user username="fedora4" password="fedora4password" roles="manager-gui"/>' $TOMCAT_CONF/tomcat-users.xml
fi
if ! grep -q "$JDK_HOME" /etc/default/tomcat7 ; then
  echo "JAVA_HOME=$JDK_HOME" >> /etc/default/tomcat7
fi
if ! grep -q 'fcrepo.home=' /etc/default/tomcat7 ; then
  echo "JAVA_OPTS=\"${JAVA_OPTS} -Dfcrepo.home=$FEDORA4_DATA\"" >> /etc/default/tomcat7
fi
# Create Fedora data directory and make sure Tomcat 7 can write to it
mkdir -p $FEDORA4_DATA
chown ${FEDORA4_USER}:${FEDORA4_GROUP} $FEDORA4_DATA
chmod 770 $FEDORA4_DATA
# Fetch Fedora 4 WAR file
TMPFILE=$(/bin/mktemp)
wget -O $TMPFILE "$FEDORA4_WAR_URL"
# Copy Fedora 4 application to webapps directory
install -o $FEDORA4_USER -g $FEDORA4_GROUP -m 444 $TMPFILE $FEDORA4_APP_DIR/fedora.war
# Clean up after ourselves
rm $TMPFILE
