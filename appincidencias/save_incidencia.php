<?php
header('Content-Type: application/json');

$servername = "localhost";
$username = "admin_rosa";
$password = "o24.fpcantillana";
$dbname = "db_cantillana_report";

// Conexión
$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    die(json_encode(["error" => "Conexión fallida"]));
}

// Recibir datos de Flutter
$uid = $_POST['uid_usuario'];
$categoria = $_POST['categoria'];
$descripcion = $_POST['descripcion'];

$sql = "INSERT INTO incidencias (uid_usuario, categoria, descripcion, estado) 
        VALUES ('$uid', '$categoria', '$descripcion', 'Pendiente')";

if ($conn->query($sql) === TRUE) {
    echo json_encode(["success" => true, "id" => $conn->insert_id]);
} else {
    echo json_encode(["success" => false, "error" => $conn->error]);
}

$conn->close();
?>