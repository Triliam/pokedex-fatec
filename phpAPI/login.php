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

    $email = trim($_POST['email']);
    $senha = trim($_POST['senha']);

    // Buscar usuário
    $stmt = $conn->prepare("SELECT id, email FROM usuarios WHERE email = ? AND senha = ?");
    
    if (!$stmt) {
        errorResponse("Erro na preparação da query: " . $conn->error, 500);
        exit();
    }

    $stmt->bind_param("ss", $email, $senha);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        $user = $result->fetch_assoc();
        successResponse([
            "id" => intval($user['id']),
            "email" => $user['email']
        ], "Login realizado com sucesso");
    } else {
        errorResponse("Email ou senha incorretos", 401);
    }

    $stmt->close();
    $conn->close();

} catch (Exception $e) {
    errorResponse("Erro interno do servidor: " . $e->getMessage(), 500);
}
?>
