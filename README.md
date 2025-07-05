# 🎮 Pokédex App - Sincronização Híbrida (Flutter + PHP/MySQL)

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white ) 
![PHP](https://img.shields.io/badge/PHP-777BB4?style=for-the-badge&logo=php&logoColor=white ) 
![MySQL](https://img.shields.io/badge/MySQL-005C84?style=for-the-badge&logo=mysql&logoColor=white )

Um aplicativo Pokédex moderno construído com Flutter, apresentando uma arquitetura de sincronização híbrida entre SQLite local e MySQL remoto para uma experiência robusta online e offline.

## ✨ Funcionalidades

- **Login e Registro Híbrido**: Funciona offline com sincronização para o servidor.
- **Listagem de Pokémons**: Carrega dados do servidor com cache local.
- **Sincronização Inteligente**: Gerencia dados de usuários e pokémons de forma otimizada.
- **Indicadores de Conectividade**: Feedback visual do status online/offline.
- **Estatísticas de Sincronização**: Acompanhe o status dos seus dados.
- **Interface Moderna**: Design limpo e intuitivo.

## 🛠️ Tecnologias Utilizadas

### Backend
- **PHP**: Linguagem de programação para a API.
- **MySQL**: Banco de dados relacional.
- **Laragon**: Ambiente de desenvolvimento local (Apache, MySQL, PHP).

### Frontend
- **Flutter**: Framework para desenvolvimento mobile.
- **Dart**: Linguagem de programação do Flutter.
- **SQLite**: Banco de dados local para persistência offline.

## ⚙️ Configuração do Ambiente

### Backend (API PHP/MySQL)

1.  **Instale o Laragon**: Baixe e instale o [Laragon](https://laragon.org/download/ ) (se ainda não tiver).
2.  **Configure o Banco de Dados**: 
    - Abra o MySQL Workbench ou phpMyAdmin.
    - Execute o script SQL localizado em `phpAPI/database.sql` para criar o banco de dados `pokedex_fatec` e suas tabelas.
    - **Importante**: O script não insere usuário padrão no MySQL. O usuário `fatec@pokemon.com` é criado no SQLite localmente.
3.  **Configure a API no Laragon**:
    - Copie a pasta `phpAPI` (que contém `config.php`, `sync_pokemon.php`, etc.) para o diretório `www` do seu Laragon (ex: `C:\laragon\www\`).
    - Inicie o Apache e MySQL no Laragon.
    - **Teste a API** acessando `http://localhost/phpAPI/get_pokemons.php` no seu navegador. Você deve ver um JSON com a lista de pokémons.

### Frontend (Aplicativo Flutter )

1.  **Clone o Repositório**:
    ```bash
    git clone <URL_DO_SEU_REPOSITORIO>
    cd pokedexfatecdsm
    ```
2.  **Instale as Dependências**:
    ```bash
    flutter pub get
    ```
3.  **Configure a URL da API**:
    - Abra o arquivo `lib/database_helper.dart`.
    - Altere a linha `static const String baseUrl = ...;` para o endereço IP da sua máquina onde o Laragon está rodando. 
    - **Exemplo**: Se o IP da sua máquina for `192.168.0.79`:
        ```dart
        static const String baseUrl = 'http://192.168.0.79/phpAPI';
        ```
    - **Certifique-se de que seu dispositivo móvel e seu computador estejam na mesma rede Wi-Fi.**

## ▶️ Como Rodar o Projeto

1.  **Execute o aplicativo em modo de depuração** (para desenvolvimento ):
    ```bash
    flutter run
    ```
2.  **Para gerar o APK de release** (para distribuição):
    ```bash
    flutter clean
    flutter pub get
    flutter build apk --release
    ```
    O APK estará em `build/app/outputs/flutter-apk/app-release.apk`.

## 📐 Arquitetura e Fluxo de Dados

Este projeto adota uma arquitetura híbrida para otimizar a experiência do usuário:

### 📱 **Usuários (Offline-First)**

- **Fluxo**: Registro/Login → SQLite Local → Sincronização → MySQL
- **Benefício**: Usuários podem interagir com o aplicativo mesmo sem conexão, e seus dados são sincronizados automaticamente quando a conexão é restabelecida.

### 🎮 **Pokémons (Server-First)**

- **Fluxo**: Requisição → MySQL → Cache SQLite → Exibição
- **Benefício**: Garante que a lista de Pokémons esteja sempre atualizada com os dados do servidor, mas mantém um cache local para acesso offline.

## 🧪 Testes

### Cenários de Teste Recomendados:

1.  **Teste de Login Offline-First (Usuários)**:
    - Desconecte seu dispositivo da internet.
    - Faça login com `fatec@pokemon.com` e senha `pikachu`.
    - ✅ O login deve ser bem-sucedido (dados do SQLite).
    - Reconecte à internet e clique no botão de sincronização.
    - ✅ O usuário deve ser sincronizado para o MySQL.

2.  **Teste de Carregamento de Pokémons (Server-First)**:
    - Com internet: ✅ A lista de Pokémons deve carregar do MySQL.
    - Sem internet: ✅ A lista de Pokémons deve carregar do cache SQLite.
    - Reconecte: ✅ O cache deve ser atualizado com os dados mais recentes do MySQL.

## 📁 Estrutura de Pastas

pokedexfatecdsm/

├── lib/                          # Código-fonte do aplicativo Flutter

│   ├── database_helper.dart      # Lógica de banco de dados (SQLite e API)

│   ├── main.dart                 # Ponto de entrada da aplicação

│   ├── tela_home.dart            # Tela principal (lista de Pokémons)

│   ├── tela_login.dart           # Tela de autenticação

│   └── models/                   # Modelos de dados (Pokemon, Usuario)

├── phpAPI/                       # Código-fonte da API PHP

│   ├── config.php                # Configurações de conexão com o MySQL

│   ├── database.sql              # Script SQL para criação do banco de dados

│   ├── get_pokemons.php          # Endpoint para obter Pokémons

│   ├── login.php                 # Endpoint para autenticação

│   ├── sync_pokemon.php          # Endpoint para sincronizar Pokémons

│   ├── sync_user.php             # Endpoint para sincronizar Usuários

│   └── README.md                 # Documentação específica da API

└── assets/                       # Recursos estáticos (imagens)

└── images/                   # Imagens dos Pokémons
