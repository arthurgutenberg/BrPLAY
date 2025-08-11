
# Projeto Prático de BD II — Agente de IA (Python + PostgreSQL)

**Alunos:** Albert Pereira, Arthur Gutenberg, Rodrigo Paiva
**Disciplina:** Banco de Dados II — Prof. José Antonio de Paiva Júnior 
**Nome:** BrPLAY - O streaming de todos os brasileiros.

Este projeto implementa um **Agente Simples de Consulta** para um sistema fictício de **estoque, vendas e clientes**.

## Entregáveis
- `schema.sql` — Criação das tabelas, *seed* de dados e **functions** exigidas:
  - `produto_mais_vendido()`
  - `situacao_estoque()`
  - `melhor_cliente()`
- `agent.py` — Agente em Python (terminal) usando `psycopg2`.
- `README.md` — Documentação do projeto, arquitetura e instruções.

## Como Executar

### 1) Preparar o Banco de Dados
1. Crie o banco:
   ```sql
   CREATE DATABASE loja_ai;
   ```
2. Conecte-se ao banco e rode o script:
   ```bash
   psql -d loja_ai -f schema.sql
   ```

### 2) Configurar o Python
```bash
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\\Scripts\\activate
pip install psycopg2-binary
```

### 3) Definir variáveis de conexão
Valores padrão usados por `agent.py`:
- `DB_HOST=localhost`
- `DB_PORT=5432`
- `DB_NAME=BrPLAY`
- `DB_USER=postgres`
- `DB_PASS=admin`

Você pode sobrescrever via ambiente:
```bash
export DB_HOST=localhost
export DB_USER=seu_usuario
export DB_PASS=sua_senha
```

### 4) Rodar o Agente
```bash
python agent.py
```
Exemplos de perguntas:
- `Qual produto mais vendido?`
- `Como está o estoque?`
- `Quem é o melhor cliente?`

Digite `sair` para encerrar.

## Estrutura do Banco (Tabelas e Relacionamentos)

- **categorias** (1) ——< **produtos**
- **clientes** (1) ——< **vendas** (1) ——< **itensvenda** >—— (1) **produtos**
- **produtos** (1) ——1 **estoque**

### Campos principais
- `produtos(preco NUMERIC(12,2))`
- `itensvenda(subtotal GENERATED AS ...)`
- `vendas(total)` com atualização pós-carga (poderia ser trigger em produção)
- `estoque(quantidade, minimo)` com status calculado na function

## Functions Criadas

### `produto_mais_vendido()`
Retorna **ID, nome, quantidade total vendida e faturamento** do produto mais vendido (por quantidade).

### `situacao_estoque()`
Lista todos os produtos com **quantidade atual, mínimo e status** (`OK`, `BAIXO`, `ESGOTADO`).

### `melhor_cliente()`
Retorna **ID, nome e total gasto** do cliente com maior soma de compras.

## Tratamento de Erros e Organização do Código
- Tratamento de erro de **conexão** com mensagem clara e `sys.exit(1)`.
- Agente estruturado com funções (`connect`, `normalize`, `dispatch_query`, `main`).
- *Matching* simples de intenções por palavras‑chave.
- Saída amigável no console.

---

**Powerd By:** F.O.F.
