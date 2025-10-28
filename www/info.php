<?php
$conn = pg_connect("host=192.168.33.11 dbname=tallerdb user=salome password=123");
if (!$conn) {
  echo "<div class='error'>Error de conexión a la base de datos.</div>";
  exit;
}

$result = pg_query($conn, "SELECT * FROM productos");

echo <<<HTML
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Listado de Productos</title>
  <style>
    body {
      font-family: 'Segoe UI', sans-serif;
      background: linear-gradient(to right, #fdfbfb, #ebedee);
      color: #333;
      padding: 40px;
      text-align: center;
    }
    h2 {
      font-size: 2em;
      color: #2c3e50;
      margin-bottom: 20px;
    }
    ul {
      list-style: none;
      padding: 0;
      max-width: 400px;
      margin: 0 auto;
    }
    li {
      background-color: #ecf0f1;
      margin: 10px 0;
      padding: 12px;
      border-radius: 6px;
      font-size: 1.1em;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    .error {
      color: red;
      font-weight: bold;
      margin-top: 50px;
    }
    footer {
      margin-top: 40px;
      font-size: 0.9em;
      color: #777;
    }
  </style>
</head>
<body>
  <h2>Productos disponibles</h2>
  <ul>
HTML;

while ($row = pg_fetch_assoc($result)) {
  echo "<li>{$row['nombre']} – \$ {$row['precio']}</li>";
}

echo <<<HTML
  </ul>
  <footer>
    Datos obtenidos desde PostgreSQL · Taller Vagrant
  </footer>
</body>
</html>
HTML;
?>