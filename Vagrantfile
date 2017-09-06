# Vagrantfile for installing VTUL Hydra/Rails applications
#
# To install under OpenStack the Vagrant openstack provider needs to be installed.
# You can install this plugin by running the following command:
#
#   vagrant plugin install vagrant-openstack-provider
#
# To install under AWS you need to have the vagrant-aws provider plugin installed.
# You can install this using the following command:
#
#   vagrant plugin install vagrant-aws
#
# If no "--provider" is specified during "vagrant up" then the default
# (VirtualBox) provider will be used.

VAGRANTFILE_API_VERSION = "2"

$secrets_items = {}
begin
  require 'yaml'
  $secrets_items = YAML::load(File.open('ansible/site_secrets.yml'))
rescue Errno::ENOENT
  $stderr.puts "Don't forget to create 'ansible/site_secrets.yml'..."
rescue => e
  abort "An error occurred processing 'ansible/site_secrets.yml'?: #{e}"
end

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
    app = $secrets_items["project_name"]
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
    if system( 'which ansible > /dev/null' )
      return :ansible
    end

    return :ansible_local
  end
end

def security_groups( env_var )
  s = ENV[ env_var ]
  if s.nil?
    # Return some default
    case env_var
      when "OS_SECURITY_GROUPS"  then ["web", "vt-ssh"]
      when "AWS_SECURITY_GROUPS" then ["default_vpc_web_vt_ssh"]
      else                            []
    end
  else
    s.split
  end
end

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # Ansible provisioner default settings
  config.vm.provision vagrant_ansible_provisioner() do |ansible|
    ansible.playbook = "ansible/#{site_file()}_site.yml"
    ansible.verbose = ""
  end

  # Application server
  config.vm.define :hydravm do |hydravm|
    hydravm.vm.hostname = "hydravm"

    hydravm.vm.provider :virtualbox do |vb, override|
      vb.name = $secrets_items["vm_name"] if !$secrets_items["vm_name"].nil? && !$secrets_items["vm_name"].empty?
      vb.customize ["modifyvm", :id, "--description", "Created from Vagrantfile in #{Dir.pwd}"]
      override.vm.box = "ubuntu/trusty64"
      vb.memory = 4096
      vb.cpus = 2
      # Forward Solr port in VM to local machine
      override.vm.network :forwarded_port, host: 8983, guest: 8983
      # Forward Tomcat/Fedora port in VM to port 8888 on local machine
      override.vm.network :forwarded_port, host: 8888, guest: 8080
      # Forward HTTP port in VM to port 8080 on local machine
      override.vm.network :forwarded_port, host: 8081, guest: 80
      # Forward HTTPS port in VM to port 4443 on local machine
      override.vm.network :forwarded_port, host: 4443, guest: 443
    end

    hydravm.vm.provider :openstack do |os, override|
      keypair = "#{ENV['KEYPAIR_NAME']}"
      keypair_filename = "#{ENV['KEYPAIR_FILE']}"
      # OpenStack authentication information
      os.openstack_auth_url = "#{ENV['OS_AUTH_URL']}/tokens"
      os.username     = "#{ENV['OS_USERNAME']}"
      os.password     = "#{ENV['OS_PASSWORD']}"
      os.tenant_name  = "#{ENV['OS_TENANT_NAME']}"
      os.region       = "#{ENV['OS_REGION_NAME']}"
      override.ssh.username = "cc"
      os.keypair_name = keypair # as stored in Nova
      override.ssh.private_key_path = "#{keypair_filename}"
      # OpenStack image information
      os.flavor       = "m1.medium"
      os.image        = "Ubuntu-Server-14.04-LTS"
      os.security_groups = security_groups('OS_SECURITY_GROUPS')
      os.floating_ip  = "#{ENV['OS_FLOATING_IP']}"
      os.server_name  = site_file()
    end

    hydravm.vm.provider :aws do |aws, override|
      keypair = "#{ENV['KEYPAIR_NAME']}"
      keypair_filename = "#{ENV['KEYPAIR_FILE']}"
      override.vm.box = "aws_dummy"
      override.vm.box_url = "https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box"
      override.vm.box_check_update = false
      aws.access_key_id = ENV['AWS_ACCESS_KEY']
      aws.secret_access_key = ENV['AWS_SECRET_KEY']
      aws.keypair_name = keypair
      aws.ami = "ami-df0607b5" # Ubuntu Trusty LTS
      aws.region = "us-east-1"
      aws.instance_type = "t2.small"
      aws.security_groups = security_groups('AWS_SECURITY_GROUPS')
      override.ssh.username = "ubuntu"
      override.ssh.private_key_path = "#{keypair_filename}"
      aws.tags = {
        'Name' => site_file()
      }
    end
  end
end
