#!/bin/sh
# Bring up a server and install the Data Repository application either under
# Vagrant or AWS.  For AWS install, the awscli software is expected to be
# installed already on the local machine doing the bootstrapping, and the
# appropriate AWS credentials set in the AWS_ACCESS_KEY and AWS_SECRET_KEY
# environment variables.

bootstrap_vagrant()
{
  # Run "varant up"
  if [ -f Vagrantfile ]; then
    echo "Running: vagrant up"
    exec vagrant up
  else
    echo "No Vagrantfile in current directory to bootstrap via vagrant"
    exit 1
  fi
}

bootstrap_aws()
{
  # Create packed userdata bootstrap script
  TMPDIR=`mktemp -d -t aws_bootstrap.XXXXX`
  tar cJf ${TMPDIR}/files.tar.xz bootstrap_server.sh config.sh config_aws.sh install*.sh files
  base64 ${TMPDIR}/files.tar.xz > ${TMPDIR}/files.b64
  cat aws_bootstrapper_header.sh ${TMPDIR}/files.b64 > ${TMPDIR}/aws_bootstrapper.sh
  # Bring up AWS instance
  ID=$(aws ec2 run-instances --image-id $AWS_AMI \
    --key-name $AWS_KEY_PAIR \
    --security-group-ids $AWS_SECURITY_GROUP_IDS \
    --subnet-id $AWS_SUBNET_ID \
    --instance-type $AWS_INSTANCE_TYPE \
    --associate-public-ip-address \
    --user-data file://${TMPDIR}/aws_bootstrapper.sh \
    --output text \
    --query 'Instances[*].InstanceId')
  # Wait for AWS server $ID to go out of "pending" state
  /bin/echo -n "Waiting for server instance $ID to start: "
  while state=$(aws ec2 describe-instances --instance-ids $ID --output text \
      --query 'Reservations[*].Instances[*].State.Name'); test "$state" = "pending"; do
    sleep 30
    /bin/echo -n '.'
  done; echo " $state"
  # Associate elastic IP
  aws ec2 associate-address --instance-id $ID --allocation-id $AWS_ELASTIC_IP
  # Set descriptive name tag
  aws ec2 create-tags --resources $ID --tags Key=Name,Value=$SERVER_HOSTNAME
  # Clean up after ourselves
  rm -rf $TMPDIR
}

# Process script arguments. Argument is server type: vagrant or aws; default: vagrant
SCRIPTS_DIR="`pwd`"
SERVER_ENV="vagrant"

if [ $# -ge 1 ]; then
  SERVER_ENV="$1"
fi
if [ $# -ge 2 ]; then
  shift;
  echo -n "Ignoring extra arguments: $@"
fi
if [ $SERVER_ENV != "aws" -a $SERVER_ENV != "vagrant" ]; then
  echo "Invalid server environment: $SERVER_ENV"
  exit 1
fi

# Read settings and platform overrides
[ -f "${SCRIPTS_DIR}/config.sh" ] && . "${SCRIPTS_DIR}/config.sh"
[ -f "${SCRIPTS_DIR}/config_${SERVER_ENV}.sh" ] && . "${SCRIPTS_DIR}/config_${SERVER_ENV}.sh"

# Create an SSL certificate if none is already present
SUBJECT="/C=US/ST=Virginia/O=Virginia Tech/localityName=Blacksburg/commonName=$SERVER_HOSTNAME/organizationalUnitName=University Libraries"
if [ ! -f files/key -o ! -f files/cert ]; then
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout files/key \
    -out files/cert -subj "$SUBJECT"
fi
# Bootstrap the system on the $SERVER_ENV environment
if [ $SERVER_ENV = "vagrant" ]; then
  bootstrap_vagrant
else
  bootstrap_aws
fi
exit 0
