import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'models/pokemon.dart';

class TelaHome extends StatefulWidget {
  const TelaHome({super.key});

  @override
  State<TelaHome> createState() => _TelaHomeState();
}

class _TelaHomeState extends State<TelaHome> {
  final dbHelper = DatabaseHelper();
  bool isLoading = false;
  bool isConnected = false;
  List<Pokemon> pokemons = [];
  Map<String, int> syncStats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    // Verificar conectividade
    isConnected = await dbHelper.checkApiConnection();
    
    // Carregar pokémons (server-first com cache local)
    pokemons = await dbHelper.getPokemons();
    
    // Carregar estatísticas de sincronização
    syncStats = await dbHelper.getSyncStats();
    
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _syncData() async {
    setState(() {
      isLoading = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sincronizando dados...')),
    );

    // Sincronizar usuários (offline-first)
    bool success = await dbHelper.syncUsersToServer();
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sincronização realizada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alguns dados não foram sincronizados. Verifique a conexão.'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    // Recarregar dados após sincronização
    await _loadData();
  }

  void _showSyncStats() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estatísticas de Sincronização'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('👥 Usuários: ${syncStats['total_users'] ?? 0}'),
            Text('✅ Sincronizados: ${syncStats['synced_users'] ?? 0}'),
            Text('⏳ Pendentes: ${(syncStats['total_users'] ?? 0) - (syncStats['synced_users'] ?? 0)}'),
            const SizedBox(height: 10),
            Text('🎮 Pokémons: ${syncStats['total_pokemons'] ?? 0}'),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  isConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: isConnected ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  isConnected ? 'Conectado ao servidor' : 'Modo offline',
                  style: TextStyle(
                    color: isConnected ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pokédex"),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          // Indicador de conectividade
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: isConnected ? Colors.lightGreen : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  isConnected ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: isConnected ? Colors.lightGreen : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Botão de estatísticas
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showSyncStats,
            tooltip: 'Estatísticas de sincronização',
          ),
          // Botão de sincronização
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: isLoading ? null : _syncData,
            tooltip: 'Sincronizar dados',
          ),
          // Botão de atualizar
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : _loadData,
            tooltip: 'Atualizar dados',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Banner de status com informações de sincronização
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isConnected 
                          ? [Colors.green.shade100, Colors.green.shade50]
                          : [Colors.orange.shade100, Colors.orange.shade50],
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isConnected ? Icons.cloud_done : Icons.cloud_off,
                            color: isConnected ? Colors.green.shade700 : Colors.orange.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isConnected 
                                ? 'Conectado - Dados atualizados do servidor'
                                : 'Modo offline - Usando cache local',
                            style: TextStyle(
                              color: isConnected ? Colors.green.shade800 : Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (syncStats.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Usuários: ${syncStats['synced_users']}/${syncStats['total_users']} sincronizados | Pokémons: ${syncStats['total_pokemons']}',
                          style: TextStyle(
                            color: isConnected ? Colors.green.shade600 : Colors.orange.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Lista de pokémons
                Expanded(
                  child: pokemons.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.catching_pokemon, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Nenhum pokémon encontrado',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Verifique sua conexão e tente novamente',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: pokemons.length,
                          itemBuilder: (context, index) {
                            final p = pokemons[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 4,
                              ),
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.blue.shade100, Colors.blue.shade50],
                                      ),
                                    ),
                                    child: Image.asset(
                                      p.imagem,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.catching_pokemon,
                                          color: Colors.blue,
                                          size: 30,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                title: Text(
                                  p.nome,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    p.tipo,
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '#${p.id.toString().padLeft(3, '0')}',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: isLoading ? null : _syncData,
        tooltip: 'Sincronizar dados',
        backgroundColor: Colors.blue.shade700,
        child: const Icon(Icons.sync, color: Colors.white),
      ),
    );
  }
}

