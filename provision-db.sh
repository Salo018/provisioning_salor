#!/bin/bash

echo "================================================"
echo "Provisionando VM DB - DataExplorer Project"
echo "Instalando PostgreSQL + Prometheus + Grafana"
echo "================================================"

# Actualizar paquetes
echo "Actualizando sistema..."
apt-get update -y
apt-get install -y wget curl apt-transport-https software-properties-common

# ============================
# INSTALAR POSTGRESQL
# ============================
echo ""
echo "Instalando PostgreSQL..."
apt-get install -y postgresql postgresql-contrib

# Habilitar y arrancar el servicio
systemctl enable postgresql
systemctl start postgresql

# Crear usuario y base de datos
echo "Configurando base de datos..."
sudo -u postgres psql <<EOF
DO \$\$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles WHERE rolname = 'salome'
   ) THEN
      CREATE USER salome WITH PASSWORD '123';
   END IF;
END
\$\$;

DO \$\$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_database WHERE datname = 'tallerdb'
   ) THEN
      CREATE DATABASE tallerdb OWNER salome;
   END IF;
END
\$\$;
EOF

# Crear tabla y datos
sudo -u postgres psql -d tallerdb <<EOF
CREATE TABLE IF NOT EXISTS productos (
  id SERIAL PRIMARY KEY,
  nombre TEXT,
  precio NUMERIC
);

INSERT INTO productos (nombre, precio) VALUES
  ('Laptop', 1200),
  ('Mouse', 25),
  ('Teclado', 80),
  ('Monitor', 300),
  ('Webcam', 150)
ON CONFLICT DO NOTHING;
EOF

echo "✓ PostgreSQL configurado"

# ============================
# INSTALAR PROMETHEUS
# ============================
echo ""
echo "Instalando Prometheus..."

# Crear usuario
useradd --no-create-home --shell /bin/false prometheus || true

# Crear directorios
mkdir -p /etc/prometheus
mkdir -p /var/lib/prometheus

# Descargar Prometheus
cd /tmp
wget -q https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz
tar xzf prometheus-2.45.0.linux-amd64.tar.gz

# Copiar binarios
cp prometheus-2.45.0.linux-amd64/prometheus /usr/local/bin/
cp prometheus-2.45.0.linux-amd64/promtool /usr/local/bin/

# Copiar archivos de configuración
cp -r prometheus-2.45.0.linux-amd64/consoles /etc/prometheus/
cp -r prometheus-2.45.0.linux-amd64/console_libraries /etc/prometheus/

# Limpiar
rm -rf prometheus-2.45.0.linux-amd64*

# Crear archivo de configuración de Prometheus
cat > /etc/prometheus/prometheus.yml <<'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  # Prometheus se monitorea a sí mismo
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
        labels:
          alias: 'prometheus-server'

  # Métricas del servidor web (Node Exporter)
  - job_name: 'web-server-system'
    static_configs:
      - targets: ['192.168.33.10:9100']
        labels:
          alias: 'web-server'
          instance: 'web-vm'
          type: 'system-metrics'

  # Métricas de Apache
  - job_name: 'web-server-apache'
    static_configs:
      - targets: ['192.168.33.10:9113']
        labels:
          alias: 'apache-web'
          instance: 'web-vm'
          type: 'apache-metrics'

  # Métricas del servidor de monitoreo (opcional)
  - job_name: 'monitoring-server'
    static_configs:
      - targets: ['localhost:9100']
        labels:
          alias: 'monitoring-server'
          instance: 'db-vm'
EOF

# Establecer permisos
chown -R prometheus:prometheus /etc/prometheus
chown -R prometheus:prometheus /var/lib/prometheus

# Crear servicio systemd para Prometheus
cat > /etc/systemd/system/prometheus.service <<'EOF'
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus/ \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start prometheus
systemctl enable prometheus

echo "✓ Prometheus instalado y corriendo"

# ============================
# INSTALAR NODE EXPORTER (en DB server también)
# ============================
echo ""
echo "Instalando Node Exporter en servidor de monitoreo..."
cd /tmp
wget -q https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
tar xzf node_exporter-1.6.1.linux-amd64.tar.gz
cp node_exporter-1.6.1.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter-1.6.1.linux-amd64*

cat > /etc/systemd/system/node_exporter.service <<'EOF'
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

systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter

echo "✓ Node Exporter instalado"

# ============================
# INSTALAR GRAFANA
# ============================
echo ""
echo "Instalando Grafana..."

# Agregar clave GPG de Grafana
wget -q -O - https://packages.grafana.com/gpg.key | apt-key add -

# Agregar repositorio de Grafana
add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"

# Actualizar e instalar
apt-get update -y
apt-get install -y grafana

# Configurar Grafana
cat > /etc/grafana/grafana.ini <<'EOF'
[server]
http_addr = 0.0.0.0
http_port = 3000

[security]
admin_user = admin
admin_password = admin

[users]
allow_sign_up = false

[auth.anonymous]
enabled = false
EOF

# Crear directorio para provisioning de datasources
mkdir -p /etc/grafana/provisioning/datasources

# Configurar Prometheus como datasource en Grafana
cat > /etc/grafana/provisioning/datasources/prometheus.yml <<'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://localhost:9090
    isDefault: true
    editable: true
    jsonData:
      timeInterval: '15s'
EOF

# Establecer permisos
chown -R grafana:grafana /etc/grafana/provisioning

# Iniciar Grafana
systemctl daemon-reload
systemctl start grafana-server
systemctl enable grafana-server

echo "✓ Grafana instalado y corriendo"

# Esperar a que los servicios estén listos
echo ""
echo "Esperando a que los servicios inicien completamente..."
sleep 10

# ============================
# VERIFICACIÓN FINAL
# ============================
echo ""
echo "================================================"
echo "Verificando servicios..."
echo "================================================"

if systemctl is-active --quiet postgresql; then
    echo "✓ PostgreSQL está corriendo"
    sudo -u postgres psql -d tallerdb -c "SELECT COUNT(*) as productos FROM productos;"
else
    echo "✗ PostgreSQL NO está corriendo"
fi

if systemctl is-active --quiet prometheus; then
    echo "✓ Prometheus está corriendo"
else
    echo "✗ Prometheus NO está corriendo"
fi

if systemctl is-active --quiet grafana-server; then
    echo "✓ Grafana está corriendo"
else
    echo "✗ Grafana NO está corriendo"
fi

if systemctl is-active --quiet node_exporter; then
    echo "✓ Node Exporter está corriendo"
else
    echo "✗ Node Exporter NO está corriendo"
fi

echo ""
echo "================================================"
echo "Provisionamiento de VM DB completado!"
echo "================================================"
echo ""
echo "PostgreSQL:"
echo "   Base de datos: tallerdb"
echo "   Usuario: salome / 123"
echo "   Productos registrados: 5"
echo ""
echo "Prometheus:"
echo "   http://192.168.33.11:9090"
echo "   http://localhost:9090"
echo ""
echo " Grafana:"
echo "   http://192.168.33.11:3000"
echo "   http://localhost:3000"
echo "   Usuario: admin"
echo "   Password: admin"
echo ""
echo " Targets monitoreados:"
echo "   - Prometheus (este servidor)"
echo "   - Web Server System (192.168.33.10:9100)"
echo "   - Web Server Apache (192.168.33.10:9113)"
echo "   - Monitoring Server (localhost:9100)"
echo ""
echo " Dashboards recomendados (importar en Grafana):"
echo "   - Node Exporter Full: ID 1860"
echo "   - Apache: ID 3894"
echo "================================================"