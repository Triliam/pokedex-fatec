<?php
require_once 'config.php';

try {
    // Verificar se é uma requisição POST
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        errorResponse("Método não permitido. Use POST.", 405);
        exit();
    }

    // Verificar se todos os campos obrigatórios foram enviados
    $required_fields = ['email', 'senha'];
    foreach ($required_fields as $field) {
        if (!isset($_POST[$field]) || empty($_POST[$field])) {
            errorResponse("Campo obrigatório ausente: $field");
            exit();
        }
    }

    $conn = getConnection();

    $id = isset($_POST['id']) ? intval($_POST['id']) : null;
    $email = trim($_POST['email']);
    $senha = trim($_POST['senha']);

    if ($id) {
        // Atualizar usuário existente
        $stmt = $conn->prepare("REPLACE INTO usuarios (id, email, senha) VALUES (?, ?, ?)");
        $stmt->bind_param("iss", $id, $email, $senha);
    } else {
        // Inserir novo usuário
        $stmt = $conn->prepare("INSERT INTO usuarios (email, senha) VALUES (?, ?) ON DUPLICATE KEY UPDATE senha = VALUES(senha)");
        $stmt->bind_param("ss", $email, $senha);
    }
    
    if (!$stmt) {
        errorResponse("Erro na preparação da query: " . $conn->error, 500);
        exit();
    }
    
    if ($stmt->execute()) {
        $user_id = $id ? $id : $conn->insert_id;
        successResponse([
            "id" => $user_id,
            "email" => $email
        ], "Usuário sincronizado com sucesso");
    } else {
        errorResponse("Erro ao sincronizar usuário: " . $stmt->error, 500);
    }

    $stmt->close();
    $conn->close();

} catch (Exception $e) {
    errorResponse("Erro interno do servidor: " . $e->getMessage(), 500);
}
?>
