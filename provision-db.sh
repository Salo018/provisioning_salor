#!/bin/bash

# Actualizar paquetes
apt-get update

# Instalar PostgreSQL
apt-get install -y postgresql postgresql-contrib

# Habilitar y arrancar el servicio
systemctl enable postgresql
systemctl start postgresql

# Crear usuario y base de datos
sudo -u postgres psql <<EOF
DO \$\$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles WHERE rolname = 'salome'
   ) THEN
      CREATE USER salome WITH PASSWORD 'clave123';
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
  ('Mouse', 25)
ON CONFLICT DO NOTHING;
EOF