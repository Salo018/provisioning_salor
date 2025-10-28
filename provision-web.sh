#!/usr/bin/env bash

# Actualizar paquetes
sudo apt-get update -y

# Instalar Apache y PHP
sudo apt-get install -y apache2 php libapache2-mod-php

# Configurar Apache
echo "ServerName localhost" | sudo tee -a /etc/apache2/apache2.conf
sudo systemctl enable apache2
sudo systemctl restart apache2

# Copiar archivos del proyecto
sudo cp /vagrant/www/index.html /var/www/html/index.html
sudo cp /vagrant/www/info.php /var/www/html/info.php

# Dar permisos
sudo chown -R www-data:www-data /var/www/html