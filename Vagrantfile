# Vagrantfile to install Data Repository application under VirtualBox
runserver = <<EOF
SCRIPTS_DIR="$1"
# Source settings, if present
if [ -f ${SCRIPTS_DIR}/config.sh ]; then
  . ${SCRIPTS_DIR}/config.sh
fi
if [ -f ${SCRIPTS_DIR}/config_vagrant.sh ]; then
  . ${SCRIPTS_DIR}/config_vagrant.sh
fi
cd "${HYDRA_HEAD_DIR}"
bash ./scripts/restart_resque.sh "${APP_ENV}"
echo "The server should be running at ${SERVER_HOSTNAME}:8080"
echo "(You can also use https://${SERVER_HOSTNAME}:4443)"
echo "The application exists in ${HYDRA_HEAD_DIR}"
EOF

Vagrant.configure(2) do |config|
  config.vm.box = 'ubuntu/trusty64'
  config.vm.provider 'virtualbox' do |vb|
    vb.name = 'data-repo-dev'
    vb.cpus = 2
    vb.memory = 3072
  end
  # Forward Solr port in VM to local machine
  config.vm.network :forwarded_port, host: 8983, guest: 8983
  # Forward Tomcat/Fedora port in VM to port 8888 on local machine
  config.vm.network :forwarded_port, host: 8888, guest: 8080
  # Forward HTTP port in VM to port 8080 on local machine
  config.vm.network :forwarded_port, host: 8080, guest: 80
  # Forward HTTPS port in VM to port 4443 on local machine
  config.vm.network :forwarded_port, host: 4443, guest: 443
  config.vm.provision :shell, args: ["vagrant", "/vagrant"], privileged: true,
    path: 'bootstrap_server.sh'
  config.vm.provision :shell, args: ["/vagrant"], run: 'always',
    privileged: false, inline: runserver
end
