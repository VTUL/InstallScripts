VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.provider :virtualbox do |vb|
    vb.memory = 4096
    vb.cpus = 2
  end

  # Hydra server
  config.vm.define "hydravm" do |hydravm|
    hydravm.vm.box = "ubuntu/trusty64"

    # Forward Solr port in VM to local machine
    config.vm.network :forwarded_port, host: 8983, guest: 8983
    # Forward Tomcat/Fedora port in VM to port 8888 on local machine
    config.vm.network :forwarded_port, host: 8888, guest: 8080
    # Forward HTTP port in VM to port 8080 on local machine
    config.vm.network :forwarded_port, host: 8080, guest: 80
    # Forward HTTPS port in VM to port 4443 on local machine
    config.vm.network :forwarded_port, host: 4443, guest: 443
  end

  # Ansible provisioning
  config.vm.provision "ansible_local" do |ansible|
    ansible.playbook = "ansible/site.yml"
  end
end
