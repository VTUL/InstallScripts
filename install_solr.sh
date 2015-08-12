#!/bin/sh

# Install Solr and set up Solr core
# Note that this must be done after installing the Sufia application because it
# uses configuration files from the "solr_conf" directory in setting up the core.

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

# Install Solr
# Fetch the Solr distribution and unpack the install script
wget "$SOLR_MIRROR/$SOLR_DIST.tgz"
tar xzf $SOLR_DIST.tgz $SOLR_DIST/bin/install_solr_service.sh --strip-components=2
# Install and start the service using the install script
bash ./install_solr_service.sh $SOLR_DIST.tgz -u $SOLR_USER -d $SOLR_MUTABLE -i $SOLR_INSTALL
# Remove Solr distribution
rm $SOLR_DIST.tgz
rm ./install_solr_service.sh
# Stop Solr until we have created the core
service solr stop
# Create Sufia Solr core
cd $SOLR_DATA
$RUN_AS_SOLR_USER mkdir -p ${SOLR_CORE}/conf
$RUN_AS_SOLR_USER echo "name=$SOLR_CORE" > ${SOLR_CORE}/core.properties
install -o $SOLR_USER -m 444 $HYDRA_HEAD_DIR/solr_conf/conf/solrconfig.xml ${SOLR_CORE}/conf/solrconfig.xml
install -o $SOLR_USER -m 444 $HYDRA_HEAD_DIR/solr_conf/conf/schema.xml ${SOLR_CORE}/conf/schema.xml
# Make links to keep the Hydra Solr solrconfig.xml paths happy
$RUN_AS_SOLR_USER ln -s $SOLR_INSTALL/solr/contrib
$RUN_AS_SOLR_USER ln -s $SOLR_INSTALL/solr/dist
$RUN_AS_SOLR_USER mkdir lib
$RUN_AS_SOLR_USER ln -s $SOLR_INSTALL/solr/contrib lib/contrib
