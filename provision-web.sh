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

# Crear página de bienvenida del proyecto
cat <<'EOF' | sudo tee /var/www/html/dataexplorer.html
<!DOCTYPE html>
<html>
<head>
    <title>DataExplorer Project</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            max-width: 900px;
            margin: 50px auto;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
        .container {
            background: white;
            padding: 40px;
            border-radius: 15px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
        }
        h1 { 
            color: #667eea; 
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        .status { 
            color: #28a745; 
            font-weight: bold; 
            font-size: 1.2em;
        }
        .info-box {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            margin: 20px 0;
            border-left: 4px solid #667eea;
        }
        ul {
            list-style-type: none;
            padding: 0;
        }
        li {
            padding: 8px 0;
            border-bottom: 1px solid #eee;
        }
        li:last-child {
            border-bottom: none;
        }
        a {
            color: #667eea;
            text-decoration: none;
            font-weight: bold;
        }
        a:hover {
            color: #764ba2;
            text-decoration: underline;
        }
        .metric-link {
            background: #e3f2fd;
            padding: 10px;
            border-radius: 5px;
            display: inline-block;
            margin: 5px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>DataExplorer Project</h1>
        <p class="status">✓ Servidor Web Funcionando</p>
        
        <div class="info-box">
            <h3> Información del Servidor Web:</h3>
            <ul>
                <li><strong>Servidor:</strong> Apache 2.4</li>
                <li><strong>PHP:</strong> Instalado</li>
                <li><strong>Sistema Operativo:</strong> Ubuntu 18.04 LTS</li>
                <li><strong>IP:</strong> 192.168.33.10</li>
                <li><strong>Hostname:</strong> web-server</li>
                <li><strong>Recursos:</strong> 1GB RAM, 1 CPU</li>
            </ul>
        </div>

        <div class="info-box">
            <h3> Páginas Disponibles:</h3>
            <ul>
                <li><a href="index.html">index.html</a> - Página principal</li>
                <li><a href="info.php">info.php</a> - Información de PHP</li>
                <li><a href="dataexplorer.html">dataexplorer.html</a> - Esta página</li>
            </ul>
        </div>

        <div class="info-box">
            <h3>Herramientas de Monitoreo:</h3>
            <ul>
                <li><a href="http://192.168.33.11:9090" target="_blank">Prometheus</a> - Recolección de métricas</li>
                <li><a href="http://192.168.33.11:3000" target="_blank">Grafana</a> - Visualización (admin/admin)</li>
                <li>También disponibles en: <a href="http://localhost:9090">localhost:9090</a> y <a href="http://localhost:3000">localhost:3000</a></li>
            </ul>
        </div>

        <div class="info-box">
            <h3> Métricas Exportadas:</h3>
            <p>Este servidor exporta métricas que Prometheus recolecta:</p>
            <div class="metric-link">
                <a href="http://192.168.33.10:9100/metrics" target="_blank">Node Exporter (9100)</a> - Métricas del sistema (CPU, RAM, Disco, Red)
            </div>
            <div class="metric-link">
                <a href="http://192.168.33.10:9113/metrics" target="_blank">Apache Exporter (9113)</a> - Métricas del servidor web
            </div>
        </div>

        <div class="info-box">
            <h3>Sobre el Proyecto:</h3>
            <p>Este es el proyecto final DataExplorer que implementa:</p>
            <ul>
                <li>✓ Virtualización con Vagrant + VirtualBox</li>
                <li>✓ Aprovisionamiento automatizado con Shell Scripts</li>
                <li>✓ Servidor web Apache con PHP</li>
                <li>✓ Sistema de monitoreo con Prometheus</li>
                <li>✓ Visualización con Grafana</li>
                <li>✓ Base de datos PostgreSQL</li>
            </ul>
        </div>
    </div>
</body>
</html>
EOF

# Dar permisos
sudo chown -R www-data:www-data /var/www/html

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