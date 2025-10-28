<?php
$conn = pg_connect("host=192.168.33.11 dbname=tallerdb user=salome password=123");
if (!$conn) {
  echo "Error de conexión.";
  exit;
}
$result = pg_query($conn, "SELECT * FROM productos");
echo "<h2>Productos</h2><ul>";
while ($row = pg_fetch_assoc($result)) {
  echo "<li>{$row['nombre']} - \$ {$row['precio']}</li>";
}
echo "</ul>";
?>