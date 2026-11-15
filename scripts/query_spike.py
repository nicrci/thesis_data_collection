
import sqlite3
import pandas as pd

def query_mena_energy_spike():
    conn = sqlite3.connect('investments.db')
    query = """
    SELECT year, country, investor, target, amount, type, subsector
    FROM investments
    WHERE region = 'MENA' AND sector = 'Energy' AND year >= 2023
    ORDER BY year DESC, amount DESC
    """
    df = pd.read_sql_query(query, conn)
    conn.close()
    
    print("MENA Energy Projects (2023-2025):")
    print(df.to_string())
    
    summary = df.groupby(['year', 'country'])['amount'].sum().reset_index()
    print("\nSummary by Year and Country:")
    print(summary.to_string())

if __name__ == "__main__":
    query_mena_energy_spike()
