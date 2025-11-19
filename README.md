
# Proyecto final 
Sistema de monitoreo web automatizado con Vagrant, Ansible, Nginx, PostgreSQL, Prometheus y Grafana.

##  Objetivo
Explorar herramientas modernas de
administración y supervisión de servicios en un entorno virtualizado

---

## Estructura del proyecto

- `Vagrantfile`: define dos máquinas virtuales (`web` y `db`) con IPs privadas.
- `provision-web.yml`: instala Nginx, Node exporter y PHP, copia los archivos web desde la carpeta `www/` al servidor.
- `provision-db.yml`: instala PostgreSQL, Prometehus y Grafana, crea la base de datos `tallerdb`, el usuario `salome`, y la tabla `productos`.
- `www/index.html`: página de bienvenida.
- `www/info.php`: script PHP que se conecta a PostgreSQL y muestra los productos.
- `www/dataexplorer.html`: esta página documenta la arquitectura y servicios del proyecto, contiene los enlaces a Prometheus, Grafana y las métricas exportadas.
- `capturas/`: carpeta con imágenes de evidencia del funcionamiento.

---

### Debes tener instalado previamente VirtualBox y Vagrant

## Paso a paso

### 1. Clonar el repositorio

```bash
git clone https://github.com/Salo018/provisioning_salor.git
cd provisioning_salor
```
### 2. Levantar las máquinas virtuales (debes esperar al menos unos 20 minutos)
Esto crea las dos VMs:
- web en 192.168.33.10
- db en 192.168.33.11
```bash
vagrant up 
```


### 3. Verificar funcionamiento
- Acceder a http://192.168.33.10 para ver la página principal.
- Acceder a http://192.168.33.10/info.php para ver los productos desde PostgreSQL.
- Acceder a http://192.168.33.10/dataexplorer.html para entrar a los enlaces de monitoreo.

### 4. Explorar Prometheus
- Acceder a http://192.168.33.11:9090 o directamente a los targets con http://192.168.33.11:9090/targets?search=  
#### Algunas consultas que puedes hacer desde la pagina principal de Prometheus:
**Uso de CPU:**
```promql
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

**Memoria RAM Disponible (MB):**
```promql
node_memory_MemAvailable_bytes / 1024 / 1024
```

**Tráfico de Red (bytes/segundo):**
```promql
rate(node_network_receive_bytes_total[1m])
```

**Requests de Nginx:**
```promql
rate(nginx_http_requests_total[1m])
```

Click en **Execute** → **Graph** para ver gráficas.

---
### 5. Configurar Grafana (solo si es la primera vez que accedes)
- Acceder a http://192.168.33.11:3000 
- Usuario: `admin`
- Contraseña: `admin`
- (Te pedirá cambiarla, puedes darle skip)

#### Verificar Datasource
1. Click en ☰ → **Connections** → **Data sources**
2. Verás **Prometheus** ya configurado 
3. Click en él → **Test** → Debe decir "Successfully queried"

#### Importar Dashboards

**Dashboard 1: Node Exporter Full (Métricas del Sistema)**

1. ☰ → **Dashboards** → **New** → **Import**
2. Pega este ID: `1860`
3. Click **Load**
4. Selecciona datasource: **Prometheus**
5. Click **Import**

Verás métricas de:
- CPU, RAM, Disco, Red
- System Load, Uptime
- Procesos, File Descriptors

**Dashboard 2: Nginx**

1. ☰ → **Dashboards** → **New** → **Import**
2. ID: `12708`
3. **Load** → **Prometheus** → **Import**

Verás:
- Requests por segundo
- Conexiones activas
- Bytes transferidos

---

### 6. Ver Métricas Crudas (Opcional)
#### Node Exporter - Métricas del Sistema
```
http://192.168.33.10:9100/metrics
```
Verás texto plano con métricas como:
- `node_cpu_seconds_total`
- `node_memory_MemAvailable_bytes`
- `node_network_receive_bytes_total`
- `node_filesystem_size_bytes`

#### Nginx Exporter - Métricas del Servidor Web
```
http://192.168.33.10:9113/metrics
```
Verás:
- `nginx_connections_active`
- `nginx_http_requests_total`
- `nginx_connections_writing`

---

## Comandos Útiles
### Gestión de VMs

```bash
# Ver estado de las VMs
vagrant status

# Detener las VMs 
vagrant halt

# Reiniciar las VMs
vagrant reload

# Destruir las VMs (elimina todo)
vagrant destroy -f

# Volver a levantar
vagrant up

# Re-ejecutar el aprovisionamiento
vagrant provision
```
### Conectarse por SSH
```bash
# Entrar a la VM web
vagrant ssh web

# Entrar a la VM db
vagrant ssh db
```
### Verificar Servicios

```bash
# Ver servicios en VM web
sudo systemctl status nginx php7.2-fpm node_exporter nginx_exporter

# Ver servicios en VM db
sudo systemctl status postgresql prometheus grafana-server
```

### Base de Datos

```bash
# Ver productos 
vagrant ssh db  
sudo -u postgres psql -d tallerdb -c 'SELECT * FROM productos;'

# Agregar un producto
vagrant ssh db 
sudo -u postgres psql -d tallerdb -c "INSERT INTO productos (nombre, precio) VALUES ('USB Drive', 20);"
```

---


