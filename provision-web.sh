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
echo "Instalando Apache, PHP y extensiones..."
sudo apt-get install -y apache2 php libapache2-mod-php php-pgsql

# Configurar Apache
echo "ServerName localhost" | sudo tee -a /etc/apache2/apache2.conf
sudo systemctl enable apache2
sudo systemctl restart apache2

# ============================
# COPIAR ARCHIVOS DEL PROYECTO
# ============================
echo ""
echo "Copiando archivos del sitio web..."

# Copiar index.html
if [ -f /vagrant/www/index.html ]; then
    sudo cp /vagrant/www/index.html /var/www/html/index.html
    echo "✓ index.html copiado"
fi

# Copiar info.php
if [ -f /vagrant/www/info.php ]; then
    sudo cp /vagrant/www/info.php /var/www/html/info.php
    echo "✓ info.php copiado"
fi

# Copiar dataexplorer.html
if [ -f /vagrant/www/dataexplorer.html ]; then
    sudo cp /vagrant/www/dataexplorer.html /var/www/html/dataexplorer.html
    echo "✓ dataexplorer.html copiado"
fi

# Dar permisos
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 644 /var/www/html/*

# ============================
# CONFIGURAR APACHE MOD_STATUS
# ============================
echo ""
echo "Configurando Apache mod_status..."

# Habilitar mod_status
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

# Reiniciar Apache
sudo systemctl restart apache2

# ============================
# INSTALAR NODE EXPORTER
# ============================
echo ""
echo "Instalando Node Exporter..."
cd /tmp
wget -q https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
tar xzf node_exporter-1.6.1.linux-amd64.tar.gz
sudo cp node_exporter-1.6.1.linux-amd64/node_exporter /usr/local/bin/
sudo chmod +x /usr/local/bin/node_exporter
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
# ============================
echo ""
echo "Instalando Apache Exporter..."
cd /tmp
wget -q https://github.com/Lusitaniae/apache_exporter/releases/download/v1.0.0/apache_exporter-1.0.0.linux-amd64.tar.gz
tar xzf apache_exporter-1.0.0.linux-amd64.tar.gz
sudo cp apache_exporter-1.0.0.linux-amd64/apache_exporter /usr/local/bin/
sudo chmod +x /usr/local/bin/apache_exporter
rm -rf apache_exporter-1.0.0.linux-amd64*

# Crear servicio para Apache Exporter (puerto 9117 por defecto)
cat <<'EOF' | sudo tee /etc/systemd/system/apache_exporter.service
[Unit]
Description=Apache Exporter
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/apache_exporter --scrape_uri=http://localhost/server-status?auto

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
    echo "✓ Node Exporter está corriendo (puerto 9100)"
else
    echo "✗ Node Exporter NO está corriendo"
fi

# Verificar Apache Exporter
if systemctl is-active --quiet apache_exporter; then
    echo "✓ Apache Exporter está corriendo (puerto 9117)"
else
    echo "✗ Apache Exporter NO está corriendo"
fi

# Verificar PHP PostgreSQL
if php -m | grep -q pgsql; then
    echo "✓ PHP PostgreSQL extension instalada"
else
    echo "✗ PHP PostgreSQL extension NO instalada"
fi

echo ""
echo "================================================"
echo "Provisionamiento de VM Web completado"
echo "================================================"
echo ""
echo "Acceso al servidor web:"
echo "   http://192.168.33.10"
echo "   http://192.168.33.10/info.php"
echo "   http://192.168.33.10/dataexplorer.html"
echo ""
echo "Metricas disponibles:"
echo "   Node Exporter:   http://192.168.33.10:9100/metrics"
echo "   Apache Exporter: http://192.168.33.10:9117/metrics"
echo ""
echo "Monitoreo disponible en:"
echo "   Prometheus: http://192.168.33.11:9090 o http://localhost:9090"
echo "   Grafana:    http://192.168.33.11:3000 o http://localhost:3000"
echo "================================================"