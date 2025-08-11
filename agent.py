# Projeto Prático de BD II - Agente de IA (Python)

# pip install psycopg2-binary
import os
import sys
import re
import psycopg2
import psycopg2.extras

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = int(os.getenv("DB_PORT", "5432"))
DB_NAME = os.getenv("DB_NAME", "BRPLAY")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASS = os.getenv("DB_PASS", "admin")

def connect():
    try:
        return psycopg2.connect(
            host=DB_HOST, port=DB_PORT, dbname=DB_NAME,
            user=DB_USER, password=DB_PASS
        )
    except Exception as e:
        print("Erro de conexão ao PostgreSQL:", e)
        sys.exit(1)

def normalize(text: str) -> str:
    text = text.lower().strip()
    text = re.sub(r"[?!.]", "", text)
    text = re.sub(r"\s+", " ", text)
    return text

def dispatch_query(cur, question: str):
    q = normalize(question)

    if any(k in q for k in ["produto mais vendido", "mais vendido", "top produto"]):
        cur.execute("SELECT * FROM produto_mais_vendido();")
        row = cur.fetchone()
        if row:
            print("\n Produto mais vendido")
            print(f"ID: {row['produto_id']} | Nome: {row['nome']}")
            print(f"Quantidade total: {row['quantidade_total']} | Faturamento: R$ {row['faturamento']:.2f}\n")
        else:
            print("Não há vendas registradas ainda.\n")
        return

    if any(k in q for k in ["estoque", "como está o estoque", "situação do estoque", "status do estoque"]):
        cur.execute("SELECT * FROM situacao_estoque();")
        rows = cur.fetchall()
        print("\n Situação do Estoque")
        print(f"{'ID':<4} {'Produto':<22} {'Qtd':>5} {'Min':>5} {'Status':>10}")
        for r in rows:
            print(f"{r['produto_id']:<4} {r['nome']:<22} {r['quantidade']:>5} {r['minimo']:>5} {r['status']:>10}")
        print()
        return

    if any(k in q for k in ["melhor cliente", "quem é o melhor cliente", "top cliente"]):
        cur.execute("SELECT * FROM melhor_cliente();")
        row = cur.fetchone()
        if row:
            print("\n Melhor cliente")
            print(f"ID: {row['cliente_id']} | Nome: {row['nome']} | Total gasto: R$ {row['total_gasto']:.2f}\n")
        else:
            print("Não há vendas registradas ainda.\n")
        return

    print("Desculpe, não entendi. Tente por exemplo:")
    print("- Qual produto mais vendido?")
    print("- Como está o estoque?")
    print("- Quem é o melhor cliente?\n")

def main():
    conn = connect()
    conn.autocommit = True
    with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
        print("Agente de Consulta (PostgreSQL)")
        print("Digite sua pergunta ou 'sair' para encerrar.\n")
        while True:
            try:
                q = input("> ")
            except (EOFError, KeyboardInterrupt):
                print("\nEncerrando...")
                break
            if normalize(q) in ("sair", "exit", "quit"):
                print("Até mais!")
                break
            dispatch_query(cur, q)
    conn.close()

if __name__ == "__main__":
    main()
