#!/usr/bin/env bash

echo "================================================"
echo "Provisionando VM Web - DataExplorer Project"
echo "================================================"

# Actualizar paquetes
echo "Actualizando sistema..."
sudo apt-get update -y

# ============================
# INSTALAR APACHE Y PHP
# ============================
echo ""
echo "Instalando Apache y PHP..."
sudo apt-get install -y apache2 php libapache2-mod-php

# Configurar Apache
echo "ServerName localhost" | sudo tee -a /etc/apache2/apache2.conf
sudo systemctl enable apache2
sudo systemctl restart apache2

# Copiar archivos del proyecto (si existen)
if [ -f /vagrant/www/index.html ]; then
    sudo cp /vagrant/www/index.html /var/www/html/index.html
fi

if [ -f /vagrant/www/info.php ]; then
    sudo cp /vagrant/www/info.php /var/www/html/info.php
fi



# ============================
# INSTALAR NODE EXPORTER
# (Métricas del sistema para Prometheus)
# ============================
echo ""
echo "Instalando Node Exporter..."
cd /tmp
wget -q https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
tar xzf node_exporter-1.6.1.linux-amd64.tar.gz
sudo cp node_exporter-1.6.1.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter-1.6.1.linux-amd64*

# Crear servicio systemd para Node Exporter
cat <<'EOF' | sudo tee /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter

# ============================
# INSTALAR APACHE EXPORTER
# (Métricas de Apache para Prometheus)
# ============================
echo ""
echo "Instalando Apache Exporter..."

# Habilitar mod_status en Apache
sudo a2enmod status

# Configurar Apache para exponer métricas
cat <<'EOF' | sudo tee /etc/apache2/mods-available/status.conf
<IfModule mod_status.c>
    <Location /server-status>
        SetHandler server-status
        Require local
        Require ip 192.168.33.0/24
    </Location>
</IfModule>
EOF

sudo systemctl restart apache2

# Descargar Apache Exporter
cd /tmp
wget -q https://github.com/Lusitaniae/apache_exporter/releases/download/v1.0.0/apache_exporter-1.0.0.linux-amd64.tar.gz
tar xzf apache_exporter-1.0.0.linux-amd64.tar.gz
sudo cp apache_exporter-1.0.0.linux-amd64/apache_exporter /usr/local/bin/
rm -rf apache_exporter-1.0.0.linux-amd64*

# Crear servicio para Apache Exporter
cat <<'EOF' | sudo tee /etc/systemd/system/apache_exporter.service
[Unit]
Description=Apache Exporter
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/apache_exporter --scrape_uri=http://localhost/server-status?auto --telemetry.address=:9113

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start apache_exporter
sudo systemctl enable apache_exporter

# ============================
# VERIFICACIÓN FINAL
# ============================
echo ""
echo "================================================"
echo "Verificando servicios..."
echo "================================================"

# Verificar Apache
if systemctl is-active --quiet apache2; then
    echo "✓ Apache está corriendo"
else
    echo "✗ Apache NO está corriendo"
fi

# Verificar Node Exporter
if systemctl is-active --quiet node_exporter; then
    echo "✓ Node Exporter está corriendo"
else
    echo "✗ Node Exporter NO está corriendo"
fi

# Verificar Apache Exporter
if systemctl is-active --quiet apache_exporter; then
    echo "✓ Apache Exporter está corriendo"
else
    echo "✗ Apache Exporter NO está corriendo"
fi

echo ""
echo "================================================"
echo " Provisionamiento de VM Web completado!"
echo "================================================"
echo ""
echo "Acceso al servidor web:"
echo "   http://192.168.33.10"
echo "   http://192.168.33.10/dataexplorer.html"
echo "   http://192.168.33.10/info.php"
echo ""
echo "Métricas disponibles:"
echo "   Node Exporter:   http://192.168.33.10:9100/metrics"
echo "   Apache Exporter: http://192.168.33.10:9113/metrics"
echo ""
echo "Monitoreo:"
echo "   Prometheus: http://192.168.33.11:9090 o http://localhost:9090"
echo "   Grafana:    http://192.168.33.11:3000 o http://localhost:3000"
echo "================================================"