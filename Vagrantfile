Vagrant.configure("2") do |config|
  
  # Máquina Web (Apache + PHP + Exporters)
  config.vm.define "web" do |web|
    web.vm.box = "bento/ubuntu-18.04"
    web.vm.box_version = "202112.19.0"
    web.vm.hostname = "web-server"
    web.vm.network "private_network", ip: "192.168.33.10"
    
    web.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = 1
      vb.name = "Web"
    end
    
    # Provisionar con script shell
    web.vm.provision "shell", path: "provision-web.sh"
  end

  # Máquina DB (PostgreSQL + Prometheus + Grafana)
  config.vm.define "db" do |db|
    db.vm.box = "bento/ubuntu-18.04"
    db.vm.box_version = "202112.19.0"
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
    
    # Provisionar con script shell
    db.vm.provision "shell", path: "provision-db.sh"
  end

end
