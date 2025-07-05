<?php
require_once 'config.php';

try {
    // Verificar se é uma requisição GET
    if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
        errorResponse("Método não permitido. Use GET.", 405);
        exit();
    }

    $conn = getConnection();

    // Buscar todos os pokémons
    $query = "SELECT id, nome, tipo, imagem FROM pokemons ORDER BY id";
    $result = $conn->query($query);

    if (!$result) {
        errorResponse("Erro ao buscar pokémons: " . $conn->error, 500);
        exit();
    }

    $pokemons = [];
    while ($row = $result->fetch_assoc()) {
        $pokemons[] = [
            'id' => intval($row['id']),
            'nome' => $row['nome'],
            'tipo' => $row['tipo'],
            'imagem' => $row['imagem']
        ];
    }

    successResponse($pokemons, "Pokémons carregados com sucesso");

    $conn->close();

} catch (Exception $e) {
    errorResponse("Erro interno do servidor: " . $e->getMessage(), 500);
}
?>
