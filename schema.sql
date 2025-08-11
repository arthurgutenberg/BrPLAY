-- Projeto Prático de BD II - Agente de IA
-- Autor: Albert Pereira, Arthur GUtenberg, Rodrigo Paiva
-- Banco: PostgreSQL

-- (Opcional) Criar database
-- CREATE DATABASE BrPLAY;
-- \c BrPLAY;

-- Limpeza (drop)
DROP TABLE IF EXISTS itensvenda CASCADE;
DROP TABLE IF EXISTS vendas CASCADE;
DROP TABLE IF EXISTS estoque CASCADE;
DROP TABLE IF EXISTS produtos CASCADE;
DROP TABLE IF EXISTS categorias CASCADE;
DROP TABLE IF EXISTS clientes CASCADE;

-- Tabelas base
CREATE TABLE categorias (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(80) NOT NULL UNIQUE
);

CREATE TABLE produtos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(120) NOT NULL,
    preco NUMERIC(12,2) NOT NULL CHECK (preco >= 0),
    categoria_id INT REFERENCES categorias(id) ON DELETE SET NULL
);

CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(120) NOT NULL,
    email VARCHAR(160) UNIQUE,
    criado_em TIMESTAMP DEFAULT NOW()
);

CREATE TABLE vendas (
    id SERIAL PRIMARY KEY,
    cliente_id INT NOT NULL REFERENCES clientes(id) ON DELETE RESTRICT,
    data_venda TIMESTAMP NOT NULL DEFAULT NOW(),
    total NUMERIC(12,2) DEFAULT 0
);

CREATE TABLE itensvenda (
    id SERIAL PRIMARY KEY,
    venda_id INT NOT NULL REFERENCES vendas(id) ON DELETE CASCADE,
    produto_id INT NOT NULL REFERENCES produtos(id) ON DELETE RESTRICT,
    quantidade INT NOT NULL CHECK (quantidade > 0),
    preco_unitario NUMERIC(12,2) NOT NULL CHECK (preco_unitario >= 0),
    subtotal NUMERIC(12,2) GENERATED ALWAYS AS (quantidade * preco_unitario) STORED
);

CREATE TABLE estoque (
    produto_id INT PRIMARY KEY REFERENCES produtos(id) ON DELETE CASCADE,
    quantidade INT NOT NULL DEFAULT 0 CHECK (quantidade >= 0),
    minimo INT NOT NULL DEFAULT 5 CHECK (minimo >= 0)
);

-- Dados fictícios
INSERT INTO categorias (nome) VALUES
('Bebidas'), ('Alimentos'), ('Limpeza');

INSERT INTO produtos (nome, preco, categoria_id) VALUES
('Café 500g', 19.90, 2),
('Arroz 5kg', 34.50, 2),
('Detergente 500ml', 3.99, 3),
('Refrigerante 2L', 8.90, 1),
('Biscoito 200g', 5.49, 2),
('Água Mineral 1,5L', 3.50, 1);

INSERT INTO clientes (nome, email) VALUES
('Ana Souza', 'ana@example.com'),
('Bruno Lima', 'bruno@example.com'),
('Carla Dias', 'carla@example.com');

INSERT INTO estoque (produto_id, quantidade, minimo) VALUES
(1, 12, 5),
(2, 7, 5),
(3, 30, 10),
(4, 4, 8),
(5, 16, 6),
(6, 50, 10);

INSERT INTO vendas (cliente_id, data_venda) VALUES
(1, NOW() - INTERVAL '2 days'),
(2, NOW() - INTERVAL '1 day'),
(3, NOW());

INSERT INTO itensvenda (venda_id, produto_id, quantidade, preco_unitario) VALUES
(1, 1, 2, 19.90),
(1, 2, 1, 34.50),
(1, 4, 3, 8.90),
(2, 3, 5, 3.99),
(2, 5, 4, 5.49),
(3, 2, 2, 34.50),
(3, 1, 1, 19.90),
(3, 6, 6, 3.50);

UPDATE vendas v
SET total = sub.soma
FROM (
    SELECT venda_id, SUM(subtotal) AS soma
    FROM itensvenda
    GROUP BY venda_id
) sub
WHERE sub.venda_id = v.id;

UPDATE estoque e
SET quantidade = e.quantidade - sub.qtd
FROM (
    SELECT produto_id, SUM(quantidade) AS qtd
    FROM itensvenda
    GROUP BY produto_id
) sub
WHERE e.produto_id = sub.produto_id;

-- Functions

-- Produto mais vendido (por quantidade)
CREATE OR REPLACE FUNCTION produto_mais_vendido()
RETURNS TABLE(produto_id INT, nome TEXT, quantidade_total BIGINT, faturamento NUMERIC)
LANGUAGE sql
AS $$
    SELECT p.id, p.nome, SUM(iv.quantidade) AS quantidade_total,
           SUM(iv.subtotal) AS faturamento
    FROM itensvenda iv
    JOIN produtos p ON p.id = iv.produto_id
    GROUP BY p.id, p.nome
    ORDER BY quantidade_total DESC, faturamento DESC
    LIMIT 1;
$$;

-- Situação do estoque
CREATE OR REPLACE FUNCTION situacao_estoque()
RETURNS TABLE(produto_id INT, nome TEXT, quantidade INT, minimo INT, status TEXT)
LANGUAGE sql
AS $$
    SELECT e.produto_id, p.nome, e.quantidade, e.minimo,
           CASE 
             WHEN e.quantidade = 0 THEN 'ESGOTADO'
             WHEN e.quantidade < e.minimo THEN 'BAIXO'
             ELSE 'OK'
           END AS status
    FROM estoque e
    JOIN produtos p ON p.id = e.produto_id
    ORDER BY p.nome;
$$;

-- Melhor cliente (maior gasto total)
CREATE OR REPLACE FUNCTION melhor_cliente()
RETURNS TABLE(cliente_id INT, nome TEXT, total_gasto NUMERIC)
LANGUAGE sql
AS $$
    SELECT c.id, c.nome, COALESCE(SUM(v.total), 0) AS total_gasto
    FROM clientes c
    LEFT JOIN vendas v ON v.cliente_id = c.id
    GROUP BY c.id, c.nome
    ORDER BY total_gasto DESC
    LIMIT 1;
$$;
