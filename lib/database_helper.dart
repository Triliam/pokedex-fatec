import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'models/usuario.dart';
import 'models/pokemon.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _db;
  
  // URL base da API - ALTERE ESTE IP PARA O IP DA SUA MÁQUINA SE NECESSÁRIO
  static const String baseUrl = 'http://192.168.0.79/phpAPI';

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app.db');

    return await openDatabase(
      path,
      version: 2, // Incrementei a versão para forçar atualização
      onCreate: (db, version) async {
        await _createTables(db);
        await _insertInitialData(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Adicionar campos de sincronização se necessário
          await db.execute('ALTER TABLE usuarios ADD COLUMN synced_to_server INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE usuarios ADD COLUMN last_sync TIMESTAMP DEFAULT CURRENT_TIMESTAMP');
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    // Tabela de usuários (offline-first)
    await db.execute('''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE,
        senha TEXT,
        synced_to_server INTEGER DEFAULT 0,
        last_sync TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Tabela de pokémons (cache local para dados do servidor)
    await db.execute('''
      CREATE TABLE pokemons (
        id INTEGER PRIMARY KEY,
        nome TEXT,
        tipo TEXT,
        imagem TEXT,
        last_sync TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<void> _insertInitialData(Database db) async {
    // OFFLINE-FIRST: Usuário padrão criado APENAS no SQLite local
    await db.insert('usuarios', {
      'email': 'fatec@pokemon.com', 
      'senha': 'pikachu',
      'synced_to_server': 0 // Não sincronizado ainda
    });

    // Cache inicial de pokémons (será atualizado do servidor)
    List<Map<String, dynamic>> pokemonsCache = [
      {'id': 1, 'nome': 'Bulbasaur', 'tipo': 'Grass/Poison', 'imagem': 'assets/images/bulbasaur.png'},
      {'id': 2, 'nome': 'Ivysaur', 'tipo': 'Grass/Poison', 'imagem': 'assets/images/ivysaur.png'},
      {'id': 3, 'nome': 'Venusaur', 'tipo': 'Grass/Poison', 'imagem': 'assets/images/venusaur.png'},
      {'id': 4, 'nome': 'Charmander', 'tipo': 'Fire', 'imagem': 'assets/images/charmander.png'},
      {'id': 5, 'nome': 'Charmeleon', 'tipo': 'Fire', 'imagem': 'assets/images/charmeleon.png'},
      {'id': 6, 'nome': 'Charizard', 'tipo': 'Fire/Flying', 'imagem': 'assets/images/charizard.png'},
      {'id': 7, 'nome': 'Squirtle', 'tipo': 'Water', 'imagem': 'assets/images/squirtle.png'},
      {'id': 8, 'nome': 'Wartortle', 'tipo': 'Water', 'imagem': 'assets/images/wartortle.png'},
      {'id': 9, 'nome': 'Blastoise', 'tipo': 'Water', 'imagem': 'assets/images/blastoise.png'},
      {'id': 10, 'nome': 'Caterpie', 'tipo': 'Bug', 'imagem': 'assets/images/caterpie.png'},
    ];

    for (var p in pokemonsCache) {
      await db.insert('pokemons', p);
    }
  }

  // OFFLINE-FIRST: Login busca primeiro no SQLite local
  // Future<Usuario?> getUser(String email, String senha) async {
  //   final db = await database;
    
  //   // 1. PRIORIDADE: Buscar no SQLite local (offline-first)
  //   final result = await db.query(
  //     'usuarios',
  //     where: 'email = ? AND senha = ?',
  //     whereArgs: [email, senha],
  //   );
    
  //   if (result.isNotEmpty) {
  //     final usuario = Usuario(
  //       id: result.first['id'] as int,
  //       email: email,
  //       senha: senha,
  //     );
      
  //     // Tentar sincronizar usuário para o servidor em background
  //     _syncUserToServer(usuario);
      
  //     return usuario;
  //   }
    
  //   // 2. FALLBACK: Se não encontrou localmente, verificar no servidor
  //   // (caso o usuário tenha sido criado em outro dispositivo)
  //   try {
  //     final response = await http.post(
  //       Uri.parse('$baseUrl/login.php'),
  //       body: {
  //         'email': email,
  //         'senha': senha,
  //       },
  //     ).timeout(Duration(seconds: 5));

  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       if (data['status'] == 'success') {
  //         // Usuário existe no servidor, salvar localmente
  //         final usuario = Usuario(
  //           id: data['data']['id'],
  //           email: data['data']['email'],
  //           senha: senha,
  //         );
          
  //         // Salvar no SQLite local para próximas consultas
  //         await db.insert('usuarios', {
  //           'email': usuario.email,
  //           'senha': usuario.senha,
  //           'synced_to_server': 1,
  //         }, conflictAlgorithm: ConflictAlgorithm.replace);
          
  //         return usuario;
  //       }
  //     }
  //   } catch (e) {
  //     print('Erro ao verificar usuário no servidor: $e');
  //   }
    
  //   return null;
  // }
  Future<Usuario?> getUser(String email, String senha) async {
  final db = await database;
  print("Tentando login para: $email");

  // 1. PRIORIDADE: Buscar no SQLite local (offline-first)
  final result = await db.query(
    'usuarios',
    where: 'email = ? AND senha = ?',
    whereArgs: [email, senha],
  );
  
  if (result.isNotEmpty) {
    print("Usuário encontrado no SQLite.");
    final usuario = Usuario(
      id: result.first['id'] as int,
      email: email,
      senha: senha,
    );
    _syncUserToServer(usuario); // Tentar sincronizar em background
    return usuario;
  }
  print("Usuário NÃO encontrado no SQLite. Tentando API...");

  // 2. FALLBACK: Se não encontrou localmente, verificar no servidor
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/login.php' ),
      body: {
        'email': email,
        'senha': senha,
      },
    ).timeout(Duration(seconds: 5));

    print("Resposta da API de login: ${response.statusCode}");
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print("Dados da API: $data");
      if (data['status'] == 'success') {
        print("Login via API bem-sucedido.");
        final usuario = Usuario(
          id: data['data']['id'],
          email: data['data']['email'],
          senha: senha,
        );
        await db.insert('usuarios', {
          'email': usuario.email,
          'senha': usuario.senha,
          'synced_to_server': 1,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        return usuario;
      }
    } else {
      print("Erro na API: ${response.body}");
    }
  } catch (e) {
    print('Erro ao verificar usuário no servidor: $e');
  }
  
  print("Login falhou.");
  return null;
}

  // SERVER-FIRST: Pokémons carregados do servidor, cache local
  Future<List<Pokemon>> getPokemons() async {
    try {
      // 1. PRIORIDADE: Carregar do MySQL (dados atualizados)
      final response = await http.get(
        Uri.parse('$baseUrl/get_pokemons.php'),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          List<Pokemon> pokemons = [];
          final db = await database;
          
          // Atualizar cache local com dados do servidor
          await db.delete('pokemons'); // Limpar cache antigo
          
          for (var pokemonData in data['data']) {
            final pokemon = Pokemon(
              id: pokemonData['id'],
              nome: pokemonData['nome'],
              tipo: pokemonData['tipo'],
              imagem: 'assets/images/${pokemonData['imagem']}',
            );
            
            pokemons.add(pokemon);
            
            // Salvar no cache local
            await db.insert('pokemons', {
              'id': pokemon.id,
              'nome': pokemon.nome,
              'tipo': pokemon.tipo,
              'imagem': pokemon.imagem,
            });
          }
          
          return pokemons;
        }
      }
    } catch (e) {
      print('Erro ao carregar pokémons da API: $e');
    }

    // 2. FALLBACK: Carregar do cache local (SQLite)
    final db = await database;
    final result = await db.query('pokemons', orderBy: 'id');
    return result.map((e) => Pokemon(
      id: e['id'] as int,
      nome: e['nome'] as String,
      tipo: e['tipo'] as String,
      imagem: e['imagem'] as String,
    )).toList();
  }

  // Sincronizar usuários não sincronizados para o servidor
  Future<bool> syncUsersToServer() async {
    try {
      final db = await database;
      
      // Buscar usuários não sincronizados
      final usuarios = await db.query(
        'usuarios',
        where: 'synced_to_server = ?',
        whereArgs: [0],
      );
      
      bool allSynced = true;
      
      for (var usuario in usuarios) {
        try {
          final response = await http.post(
            Uri.parse('$baseUrl/sync_user.php'),
            body: {
              'email': usuario['email'].toString(),
              'senha': usuario['senha'].toString(),
            },
          ).timeout(Duration(seconds: 10));

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['status'] == 'success') {
              // Marcar como sincronizado
              await db.update(
                'usuarios',
                {'synced_to_server': 1, 'last_sync': DateTime.now().toIso8601String()},
                where: 'id = ?',
                whereArgs: [usuario['id']],
              );
              print('Usuário ${usuario['email']} sincronizado com sucesso');
            } else {
              allSynced = false;
            }
          } else {
            allSynced = false;
          }
        } catch (e) {
          print('Erro ao sincronizar usuário ${usuario['email']}: $e');
          allSynced = false;
        }
      }
      
      return allSynced;
    } catch (e) {
      print('Erro geral na sincronização de usuários: $e');
      return false;
    }
  }

  // Sincronizar usuário específico em background
  Future<void> _syncUserToServer(Usuario usuario) async {
    final db = await database;
    
    // Verificar se já está sincronizado
    final result = await db.query(
      'usuarios',
      where: 'id = ? AND synced_to_server = ?',
      whereArgs: [usuario.id, 0],
    );
    
    if (result.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/sync_user.php'),
          body: {
            'email': usuario.email,
            'senha': usuario.senha,
          },
        ).timeout(Duration(seconds: 5));

        if (response.statusCode == 200) {
          await db.update(
            'usuarios',
            {'synced_to_server': 1, 'last_sync': DateTime.now().toIso8601String()},
            where: 'id = ?',
            whereArgs: [usuario.id],
          );
        }
      } catch (e) {
        print('Erro ao sincronizar usuário em background: $e');
      }
    }
  }

  // Sincronização completa (usuários + pokémons)
  Future<bool> syncToMySQL() async {
    bool usersSync = await syncUsersToServer();
    
    // Para pokémons, apenas recarregar do servidor (server-first)
    await getPokemons();
    
    return usersSync;
  }

  // Registrar novo usuário (offline-first)
  Future<bool> registerUser(String email, String senha) async {
    try {
      final db = await database;
      
      // Verificar se já existe localmente
      final existing = await db.query(
        'usuarios',
        where: 'email = ?',
        whereArgs: [email],
      );
      
      if (existing.isNotEmpty) {
        return false; // Usuário já existe
      }
      
      // Inserir no SQLite local primeiro
      await db.insert('usuarios', {
        'email': email,
        'senha': senha,
        'synced_to_server': 0,
      });
      
      // Tentar sincronizar com servidor em background
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/sync_user.php'),
          body: {
            'email': email,
            'senha': senha,
          },
        ).timeout(Duration(seconds: 5));

        if (response.statusCode == 200) {
          // Marcar como sincronizado
          await db.update(
            'usuarios',
            {'synced_to_server': 1, 'last_sync': DateTime.now().toIso8601String()},
            where: 'email = ?',
            whereArgs: [email],
          );
        }
      } catch (e) {
        print('Usuário criado localmente, será sincronizado quando online: $e');
      }
      
      return true;
    } catch (e) {
      print('Erro ao registrar usuário: $e');
      return false;
    }
  }

  // Verificar conectividade com a API
  Future<bool> checkApiConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_pokemons.php'),
      ).timeout(Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Obter estatísticas de sincronização
  Future<Map<String, int>> getSyncStats() async {
    final db = await database;
    
    final totalUsers = await db.rawQuery('SELECT COUNT(*) as count FROM usuarios');
    final syncedUsers = await db.rawQuery('SELECT COUNT(*) as count FROM usuarios WHERE synced_to_server = 1');
    final totalPokemons = await db.rawQuery('SELECT COUNT(*) as count FROM pokemons');
    
    return {
      'total_users': totalUsers.first['count'] as int,
      'synced_users': syncedUsers.first['count'] as int,
      'total_pokemons': totalPokemons.first['count'] as int,
    };
  }
}

