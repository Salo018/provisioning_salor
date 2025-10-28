
# Taller Vagrant con Provisionamiento Shell

##  Objetivo
Desplegar una aplicación web básica con Apache, PHP y PostgreSQL usando Vagrant y Shell scripts.

---

## Estructura del proyecto

- `Vagrantfile`: define dos máquinas virtuales (`web` y `db`) con IPs privadas.
- `provision-web.sh`: instala Apache y PHP, copia los archivos web desde la carpeta `www/` al servidor.
- `provision-db.sh`: instala PostgreSQL, crea la base de datos `tallerdb`, el usuario `salome`, y la tabla `productos`.
- `www/index.html`: página de bienvenida con estilo personalizado.
- `www/info.php`: script PHP que se conecta a PostgreSQL y muestra los productos.
- `capturas/`: carpeta con imágenes de evidencia del funcionamiento.

---

## Paso a paso

### 1. Clonar el repositorio

```bash
git clone https://github.com/jmaquin0/vagrant-web-provisioning.git
cd vagrant-web-provisioning
```
### 2. Levantar las máquinas virtuales
Esto crea las dos VMs:
- web en 192.168.33.10
- db en 192.168.33.11
```bash
vagrant up 
```
### 3. Provisionar la máquina WEB
El script provision-web.sh:
- Instala Apache y PHP
- Copia index.html e info.php al directorio /var/www/html/

### 4. Provisionar la máquina DB
El script provision-db.sh:
- Instala PostgreSQL.
- Crea la base de datos tallerdb.
- Crea la tabla productos con datos de ejemplo.
- Crea el usuario salome con contraseña 123.
#### Agregar datos
En esta parte también le agregué dos productos a la tabla para probar su funcionamiento.

### 5. Verificar funcionamiento
- Acceder a http://192.168.33.10/index.html para ver la página principal.
- Acceder a http://192.168.33.10/info.php para ver los productos desde PostgreSQL.

### 6. Actualizar archivos web 
```bash
vagrant ssh web
sudo cp /vagrant/www/index.html /var/www/html/index.html
sudo cp /vagrant/www/info.php /var/www/html/info.php
```
### 7. Evidencia del funcionamiento
Página index.html servida por Apache
index
info.php mostrando productos desde PostgreSQL
info_php

### Resultado esperado
Al visitar info.php, se muestra:
- Encabezado: “Productos disponibles”
- Lista:
- Laptop – $1200
- Mouse – $25



