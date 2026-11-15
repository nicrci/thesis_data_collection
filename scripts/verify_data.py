import sqlite3
conn = sqlite3.connect('investments.db')
cursor = conn.cursor()

print("--- USA Analysis ---")
cursor.execute("SELECT type, SUM(amount) FROM investments WHERE country='USA' GROUP BY type")
print(cursor.fetchall())

print("\n--- Top 5 Countries (Investment Type) ---")
cursor.execute("SELECT country, SUM(amount) FROM investments WHERE type='Investment' GROUP BY country ORDER BY SUM(amount) DESC LIMIT 5")
print(cursor.fetchall())

print("\n--- Top 5 Countries (Construction Type) ---")
cursor.execute("SELECT country, SUM(amount) FROM investments WHERE type='Construction' GROUP BY country ORDER BY SUM(amount) DESC LIMIT 5")
print(cursor.fetchall())

print("\n--- Sector Data Quality ---")
cursor.execute("SELECT sector, COUNT(*) FROM investments WHERE sector IS NULL OR sector='None' GROUP BY sector")
print(cursor.fetchall())

conn.close()
