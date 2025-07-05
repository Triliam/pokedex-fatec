<?php
// Configurações do banco de dados
define('DB_HOST', 'localhost');
define('DB_PORT', '3306');
define('DB_NAME', 'pokedex_fatec');
define('DB_USER', 'developer');
define('DB_PASS', '123456');

// Configurações da API
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Tratar requisições OPTIONS (CORS preflight)
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Função para conectar ao banco de dados
function getConnection() {
    try {
        $conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME, DB_PORT);
        
        if ($conn->connect_error) {
            throw new Exception("Erro de conexão: " . $conn->connect_error);
        }
        
        $conn->set_charset("utf8");
        return $conn;
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            "status" => "error",
            "message" => "Erro de conexão com o banco de dados: " . $e->getMessage()
        ]);
        exit();
    }
}

// Função para resposta de sucesso
function successResponse($data = null, $message = "Operação realizada com sucesso") {
    echo json_encode([
        "status" => "success",
        "message" => $message,
        "data" => $data
    ]);
}

// Função para resposta de erro
function errorResponse($message, $code = 400) {
    http_response_code($code);
    echo json_encode([
        "status" => "error",
        "message" => $message
    ]);
}
?>