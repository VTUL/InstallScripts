VAGRANTFILE_API_VERSION = "2"

def site_file
  # If the APP_TYPE environment variable is defined and contains an acceptable
  # known value then we use that setting for the site file type.  Otherwise,
  # we try to guess it from the "project_name" setting in the ansible/site_secrets.yml
  # file (defaulting to "sufia").
  app = "#{ENV['APP_TYPE']}"
  if app == "sufia" or app == "geoblacklight"
    return app
  else
    # Try to guess the application type from the site_secrets.yml project_name
    require 'yaml'
    items = YAML::load(File.open('ansible/site_secrets.yml'))
    app = items["project_name"]
    case app
      when "data-repo", "iawa" then "sufia"
      when "geoblacklight"     then "geoblacklight"
      else                          "sufia"
    end
  end
end

def vagrant_ansible_provisioner
  prov = "#{ENV['ANSIBLE_PROVISIONER']}"
  if prov == "ansible" or prov == "ansible_local"
    return prov
  else
    return :ansible_local
  end
end

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
  config.vm.provision vagrant_ansible_provisioner() do |ansible|
    ansible.playbook = "ansible/#{site_file()}_site.yml"
    ansible.verbose = ""
  end
end
