# ProductHub

[![Delphi](https://img.shields.io/badge/Delphi-12%20Athens-blue?style=flat&logo=delphi)](https://www.embarcadero.com/products/delphi)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-green?style=flat&logo=postgresql)](https://www.postgresql.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Descrição

O **ProductHub** é uma aplicação desktop desenvolvida em Delphi usando o framework VCL (Visual Component Library). O projeto implementa operações básicas de CRUD (Create, Read, Update, Delete) para gerenciamento de produtos, com foco em usabilidade e integração com banco de dados.

A aplicação permite o cadastro, edição, exclusão e listagem de produtos, exibindo informações como ID, Código, Nome, Descrição, Categoria, Unidade de Medida, Preço, Estoque, status de Ativo/Inativo, data de criação e atualização. Além da interface gráfica principal, o projeto inclui um módulo opcional de API REST para acesso externo aos dados.

Este projeto foi desenvolvido como um desafio técnico (descrito no arquivo desafio_delphi.pdf), demonstrando boas práticas de desenvolvimento em Delphi, incluindo validações, formatação de dados e integração com ORM.

## Requisitos

### Hardware e Software
- **Sistema Operacional**: Windows 10 ou superior (64-bit).
- **Delphi**: Versão 12 Athens (ou compatível) com pacotes instalados para FireDAC e DelphiMVCFramework.
- **Banco de Dados**: PostgreSQL 16
- **Dependências Delphi**:
  - DelphiMVCFramework (instalado via GetIt ou manualmente do repositório oficial).
  - Horse (para o módulo de API, instalado via GetIt).
- **Ferramentas Opcionais**: Git para clonagem do repositório; pgAdmin ou DBeaver para gerenciamento do banco.

### Bibliotecas Externas
- Certifique-se de que o projeto tenha as units necessárias: `MVCFramework`, `MVCActiveRecord`, `Horse`, e componentes FireDAC ativados.
## Configuração e Execução

### 1. Clonagem do Repositório
```bash
git clone https://github.com/pedrogoncaloDev/ProductHub.git
cd ProductHub
```

### 2. Configuração do back-end

1. No PostgreSQL 16, crie um banco de dados com o nome de sua preferência.

2. Na pasta `back_end`, crie o arquivo `dbconfig.ini` baseado no `dbconfig.ini.example`, preenchendo com as credenciais de conexão do banco.

3. Instalação das dependências
    
    - **a.** Instale o Boss. Caso não tenha familiaridade, siga este vídeo: https://www.youtube.com/watch?v=UUuJm1Lh4ZA

    - **b.** No diretório do projeto na pasta `back_end`, execute os comandos abaixo para inicializar e instalar as dependências:

```bash
        boss init
        boss install horse
        boss install horse-cors
        boss install horse-jhonson
```

4. Adicione o caminho no PATH do sistema para evitar o erro de "[FireDAC][Phys][PG]-314. Cannot load vendor library [libpq.dll]".
    1. Pesquise **"Variáveis de Ambiente"** no Windows
    2. Em **Variáveis do Sistema**, edite o `Path`
    3. Adicione: `C:\Program Files\PostgreSQL\16\bin`
    4. **Reinicie o Delphi** após alterar o PATH

5. Com tudo configurado, basta iniciar o servidor da pasta back_end e, após sua inicialização, executar o projeto da pasta front_end.

## Tecnologias Utilizadas

- **Delphi 12 Athens (Win64)**: Linguagem principal e ambiente de desenvolvimento para a aplicação VCL.
- **VCL (Visual Component Library)**: Framework para construção da interface gráfica.
- **DelphiMVCFramework (DMVCFramework)**: Framework MVC para Delphi, utilizado com ActiveRecord como ORM para mapeamento objeto-relacional.
- **FireDAC**: Componente de acesso a dados do Delphi para conexão e manipulação com o banco de dados PostgreSQL.
- **PostgreSQL**: Banco de dados relacional para armazenamento persistente dos dados de produtos.
- **Horse**: Framework leve para criação de APIs REST em Delphi (módulo opcional).
- **TFDMemTable**: Tabela em memória para exibição rápida de dados no grid.
- **TDBGrid**: Componente para visualização tabular dos produtos.

## Arquitetura Geral

A arquitetura segue o padrão MVC (Model-View-Controller) facilitado pelo DelphiMVCFramework, com separação clara entre:

- **Model**: Entidades representadas por classes ActiveRecord (ex.: `TProduto`), que mapeiam diretamente as tabelas do banco de dados. Inclui campos como `ID`, `Codigo`, `Nome`, `Descricao`, `Categoria`, `UnidadeMedida`, `Preco`, `Estoque`, `Ativo` (booleano), `CriadoEm` e `AtualizadoEm`.
  
- **View**: 
  - **MainForm** (uMainForm.pas): Tela principal com um `TDBGrid` conectado a um `TFDMemTable` para listagem de produtos. Inclui botões para Atualizar, Criar, Editar e Excluir. O campo `Ativo` é formatado para exibir "Sim" ou "Não" via `DisplayValues`. Datas usam `DisplayFormat` como `dd/mm/yyyy hh:nn:ss`, e preços como `R$ 0,00`.
  - **uProdutoForm.pas**: Formulário modal para cadastro e edição, com validações para campos obrigatórios (ex.: Nome, Código).

- **Controller**: Lógica de negócios no `MainForm` e em handlers do ActiveRecord. Operações de CRUD são realizadas via métodos do ORM, com confirmação para exclusão.

O fluxo geral é:
1. Conexão ao banco via FireDAC.
2. Carregamento de dados para o `TFDMemTable` e exibição no grid.
3. Para CRUD: Abertura de formulário modal, validação, persistência via ActiveRecord e recarregamento do grid.

Adicionalmente, o módulo de API REST (opcional) expõe endpoints para integração externa, reutilizando o mesmo modelo de dados.
