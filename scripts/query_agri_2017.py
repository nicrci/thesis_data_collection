
import sqlite3
import pandas as pd

def query_agriculture_2017():
    conn = sqlite3.connect('investments.db')
    # First, let's see the yearly trend for Agriculture to confirm the spike
    trend_query = """
    SELECT year, SUM(amount) as total_amount
    FROM investments
    WHERE sector = 'Agriculture'
    GROUP BY year
    ORDER BY year
    """
    trend_df = pd.read_sql_query(trend_query, conn)
    print("Yearly Agriculture Totals (Global):")
    print(trend_df.to_string())
    
    # Now, find the biggest deals in 2017 for Agriculture
    deals_query = """
    SELECT year, country, region, investor, target, amount, type, subsector
    FROM investments
    WHERE sector = 'Agriculture' AND year = 2017
    ORDER BY amount DESC
    """
    deals_df = pd.read_sql_query(deals_query, conn)
    conn.close()
    
    print("\nTop Agriculture Projects in 2017:")
    print(deals_df.head(20).to_string())

if __name__ == "__main__":
    query_agriculture_2017()
