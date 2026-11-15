
import sqlite3
import pandas as pd

def query_indonesia_spikes():
    conn = sqlite3.connect('investments.db')
    query = """
    SELECT year, sector, investor, target, amount, type, subsector
    FROM investments
    WHERE country = 'Indonesia' AND sector IN ('Energy', 'Metals', 'Transport')
    ORDER BY sector, year DESC, amount DESC
    """
    df = pd.read_sql_query(query, conn)
    conn.close()
    
    print("Indonesia Sector Projects (Energy, Metals, Transport):")
    # Group by sector and year to see trends
    summary = df.groupby(['sector', 'year'])['amount'].sum().reset_index()
    
    # Pivot for better readability of trends
    pivot_summary = summary.pivot(index='year', columns='sector', values='amount').fillna(0)
    print("\nYearly Summary by Sector (Amount in USD M):")
    print(pivot_summary.tail(10)) # Show last 10 years
    
    print("\nTop Projects in Metals (Recent):")
    print(df[df['sector'] == 'Metals'].head(15).to_string())
    
    print("\nTop Projects in Energy (Recent):")
    print(df[df['sector'] == 'Energy'].head(15).to_string())
    
    print("\nTop Projects in Transport (Recent):")
    print(df[df['sector'] == 'Transport'].head(15).to_string())

if __name__ == "__main__":
    query_indonesia_spikes()
