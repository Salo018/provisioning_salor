Vagrant.configure("2") do |config|
  
  # Máquina Web (Nginx + Node Exporter)
  config.vm.define "web" do |web|
    web.vm.box = "ubuntu/bionic64"
    web.vm.hostname = "web-server"
    web.vm.network "private_network", ip: "192.168.33.10"
    
    web.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = 1
      vb.name = "Web"
    end
    
    # Provisionar con Ansible
    web.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "provision-web.yml"
      ansible.install = true
      ansible.install_mode = "default"
      ansible.verbose = false
      ansible.extra_vars = {
        ansible_python_interpreter: "/usr/bin/python3"
      }
    end
  end

  # Maquina DB (PostgreSQL + Prometheus + Grafana)
  config.vm.define "db" do |db|
    db.vm.box = "ubuntu/bionic64"
    db.vm.hostname = "db-server"
    db.vm.network "private_network", ip: "192.168.33.11"
    
    # Port forwarding para acceder desde Windows
    db.vm.network "forwarded_port", guest: 9090, host: 9090  # Prometheus
    db.vm.network "forwarded_port", guest: 3000, host: 3000  # Grafana
    
    db.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
      vb.name = "Db"
    end
    
    # Provisionar con Ansible
    db.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "provision-db.yml"
      ansible.install = true
      ansible.install_mode = "default"
      ansible.verbose = false
      ansible.extra_vars = {
        ansible_python_interpreter: "/usr/bin/python3"
      }
    end
  end

end
