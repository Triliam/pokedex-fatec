<?php
require_once 'config.php';

try {
    // Verificar se é uma requisição POST
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        errorResponse("Método não permitido. Use POST.", 405);
        exit();
    }

    // Verificar se todos os campos obrigatórios foram enviados
    $required_fields = ['id', 'nome', 'tipo', 'imagem'];
    foreach ($required_fields as $field) {
        if (!isset($_POST[$field]) || empty($_POST[$field])) {
            errorResponse("Campo obrigatório ausente: $field");
            exit();
        }
    }

    $conn = getConnection();

    $id = intval($_POST['id']);
    $nome = trim($_POST['nome']);
    $tipo = trim($_POST['tipo']);
    $imagem = trim($_POST['imagem']);

    // Usar REPLACE INTO para inserir ou atualizar
    $stmt = $conn->prepare("REPLACE INTO pokemons (id, nome, tipo, imagem) VALUES (?, ?, ?, ?)");
    
    if (!$stmt) {
        errorResponse("Erro na preparação da query: " . $conn->error, 500);
        exit();
    }

    $stmt->bind_param("isss", $id, $nome, $tipo, $imagem);
    
    if ($stmt->execute()) {
        successResponse([
            "id" => $id,
            "nome" => $nome,
            "tipo" => $tipo,
            "imagem" => $imagem
        ], "Pokémon sincronizado com sucesso");
    } else {
        errorResponse("Erro ao sincronizar pokémon: " . $stmt->error, 500);
    }

    $stmt->close();
    $conn->close();

} catch (Exception $e) {
    errorResponse("Erro interno do servidor: " . $e->getMessage(), 500);
}
?>