# Taller Vagrant con Provisionamiento Shell

## Objetivo
Desplegar una aplicación web básica con Apache, PHP y PostgreSQL usando Vagrant y Shell scripts.

## Estructura del proyecto

- `Vagrantfile`: define dos máquinas virtuales (`web` y `db`) con IPs privadas.
- `provision-web.sh`: instala Apache y PHP, copia archivos web.
- `provision-db.sh`: instala PostgreSQL, crea base de datos y tabla.
- `www/index.html`: página de bienvenida.
- `www/info.php`: script PHP que muestra info del servidor y datos desde PostgreSQL.

## Pasos de instalación

```bash
git clone https://github.com/tuusuario/vagrant-web-provisioning.git
cd vagrant-web-provisioning
vagrant up