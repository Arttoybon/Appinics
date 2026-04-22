<?php
// save_incidencia.php

// 1. Configuración de Cabeceras (CORS) para permitir peticiones desde Flutter Web y Móvil
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

// Manejo de peticiones OPTIONS (Preflight)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// 2. Configuración de la Base de Datos
$host = "localhost";
$db_name = "alumno24_db_cantillana_report";
$username = "admin_rosa"; // He quitado el @localhost que suele sobrar aquí
$password = "o24.fpcantillana";

try {
    $conn = new PDO("mysql:host=$host;dbname=$db_name;charset=utf8", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    echo json_encode(["status" => "error", "message" => "Error de conexión: " . $e->getMessage()]);
    exit();
}

// 3. Recepción de Datos
if ($_SERVER['REQUEST_METHOD'] === 'POST') {

    // Obtener campos de texto
    $uid = $_POST['uid_usuario'] ?? 'anonimo';
    $categoria = $_POST['categoria'] ?? 'Sin categoria';
    $descripcion = $_POST['descripcion'] ?? '';

    $foto_url = null;

    // 4. Procesamiento de la Imagen
    if (isset($_FILES['foto']) && $_FILES['foto']['error'] === UPLOAD_ERR_OK) {
        $upload_dir = 'uploads/';

        // Crear directorio si no existe
        if (!is_dir($upload_dir)) {
            mkdir($upload_dir, 0777, true);
        }

        $file_extension = pathinfo($_FILES['foto']['name'], PATHINFO_EXTENSION);
        $file_name = uniqid('incidencia_') . '.' . $file_extension;
        $target_path = $upload_dir . $file_name;

        if (move_uploaded_file($_FILES['foto']['tmp_name'], $target_path)) {
            $foto_url = "https://alumno24.fpcantillana.org/" . $target_path;
        } else {
            echo json_encode(["status" => "error", "message" => "No se pudo mover el archivo subido"]);
            exit();
        }
    }

    // 5. Guardar en Base de Datos
    try {
        $sql = "INSERT INTO incidencias (uid_usuario, categoria, descripcion, foto_url, fecha)
                VALUES (:uid, :categoria, :descripcion, :foto, NOW())";

        $stmt = $conn->prepare($sql);
        $stmt->bindParam(':uid', $uid);
        $stmt->bindParam(':categoria', $categoria);
        $stmt->bindParam(':descripcion', $descripcion);
        $stmt->bindParam(':foto', $foto_url);

        if ($stmt->execute()) {
            echo json_encode([
                "status" => "success",
                "message" => "Incidencia guardada correctamente",
                "id" => $conn->lastInsertId()
            ]);
        } else {
            echo json_encode(["status" => "error", "message" => "Fallo al insertar en la base de datos"]);
        }
    } catch(PDOException $e) {
        echo json_encode(["status" => "error", "message" => "Error de SQL: " . $e->getMessage()]);
    }

} else {
    echo json_encode(["status" => "error", "message" => "Método no permitido"]);
}
?>
