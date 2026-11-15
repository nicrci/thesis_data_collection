import sqlite3
import pandas as pd
import json
import os

DB_NAME = "investments.db"

# Define region mappings for regrouping
REGION_MAPPING = {
    "Southeast Asia": [
        "Brunei", "Cambodia", "Indonesia", "Laos", "Malaysia", "Myanmar",
        "Philippines", "Singapore", "Thailand", "Timor-Leste", "Vietnam"
    ],
    "East Asia": [
        "Japan", "Mongolia", "North Korea", "South Korea", "Taiwan"
    ],
    "South Asia": [
        "Afghanistan", "Bangladesh", "India", "Maldives", "Nepal", "Pakistan", "Sri Lanka"
    ],
    "Central Asia": [
        "Kazakhstan", "Kyrgyzstan", "Tajikistan", "Turkmenistan", "Uzbekistan"
    ],
    "Oceania": [
        "Australia", "Fiji", "New Zealand", "Papua New Guinea", "Samoa", "Solomon Islands"
    ],
    "MENA": [
        "Algeria", "Bahrain", "Egypt", "Iraq", "Jordan", "Kuwait", "Libya", 
        "Mauritania", "Morocco", "Oman", "Qatar", "Saudi Arabia", "Sudan", 
        "Syria", "Tunisia", "UAE", "Yemen", "Israel", "Iran"
    ],
    "Western Asia/Caucasus": [
        "Armenia", "Azerbaijan", "Georgia", "Turkey", "Russian Federation"
    ],
    "North America": [
        "USA", "Canada", "Mexico", "Antigua and Barbuda", "Bahamas", "Barbados", 
        "Costa Rica", "Cuba", "Dominica", "Dominican Republic", "Guatemala", 
        "Honduras", "Jamaica", "Nicaragua", "Panama", "Trinidad-Tobago"
    ],
    "South America": [
        "Argentina", "Bolivia", "Brazil", "Chile", "Colombia", "Ecuador", 
        "Guyana", "Peru", "Suriname", "Uruguay", "Venezuela"
    ],
    "Europe": [
        "Austria", "Belarus", "Belgium", "Bosnia", "Britain", "Bulgaria", 
        "Croatia", "Cyprus", "Czech Republic", "Denmark", "Finland", "France", 
        "Germany", "Greece", "Hungary", "Ireland", "Italy", "Latvia", 
        "Luxembourg", "Macedonia", "Malta", "Moldova", "Montenegro", 
        "Netherlands", "Norway", "Poland", "Portugal", "Romania", "Serbia", 
        "Slovakia", "Slovenia", "Spain", "Sweden", "Switzerland", "Ukraine"
    ],
    "Sub-Saharan Africa": [
        "Angola", "Benin", "Botswana", "Burkina Faso", "Burundi", "Cameroon", 
        "Cape Verde", "Chad", "Congo", "Democratic Republic of the Congo", 
        "Djibouti", "Equatorial Guinea", "Eritrea", "Eswatini", "Ethiopia", 
        "Gabon", "Ghana", "Guinea", "Guinea-Bissau", "Ivory Coast", "Kenya", 
        "Lesotho", "Liberia", "Madagascar", "Malawi", "Mali", "Mauritius", 
        "Mozambique", "Namibia", "Niger", "Nigeria", "Rwanda", "Sao Tome", 
        "Senegal", "Sierra Leone", "South Africa", "South Sudan", "Tanzania", 
        "Togo", "Uganda", "Zambia", "Zimbabwe"
    ]
}

# Reverse mapping for quick lookup: {country: region}
COUNTRY_TO_REGION = {country: region for region, countries in REGION_MAPPING.items() for country in countries}

def regroup_region(country, current_region):
    """Regroups the region based on the country name."""
    if not country:
        return current_region
        
    country_clean = country.strip()
    
    if country_clean in COUNTRY_TO_REGION:
        return COUNTRY_TO_REGION[country_clean]
    
    # Handle common variants or substrings if necessary
    if "USA" in country_clean:
        return "North America"
    
    # Handle specific renaming for existing regions that weren't caught by country mapping
    if current_region == "Arab Middle East and North Africa":
        return "MENA"
    if current_region == "West Asia":
        # Any remaining West Asia should probably be Western Asia/Caucasus
        return "Western Asia/Caucasus"
    
    return current_region

def init_db():
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS investments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            year INTEGER,
            month TEXT,
            investor TEXT,
            target TEXT,
            sector TEXT,
            subsector TEXT,
            country TEXT,
            region TEXT,
            amount REAL,
            share REAL,
            type TEXT
        )
    ''')
    conn.commit()
    return conn

def load_data_from_dataframe(df):
    conn = init_db()
    # Replace NaN or NaT with None so SQLite can insert NULLs
    df = df.where(pd.notnull(df), None)
    
    # Ensure expected columns exist, fill with None if missing
    expected_cols = [
        'year', 'month', 'investor', 'target', 'sector', 
        'subsector', 'country', 'region', 'amount', 'share', 'type'
    ]
    
    for col in expected_cols:
        if col not in df.columns:
            df[col] = None
            
    # Clean types specifically for the DB
    if 'year' in df.columns: 
        df['year'] = pd.to_numeric(df['year'], errors='coerce').astype('Int64')
    # Month is kept as TEXT now
    if 'amount' in df.columns: 
        df['amount'] = pd.to_numeric(df['amount'], errors='coerce')
    if 'share' in df.columns: 
        df['share'] = pd.to_numeric(df['share'], errors='coerce')

    # Convert remaining to strings where appropriate
    str_cols = ['month', 'investor', 'target', 'sector', 'subsector', 'country', 'region', 'type']
    for col in str_cols:
        if col in df.columns:
            df[col] = df[col].astype(str).replace('nan', None).replace('None', None)

    # Apply region regrouping
    if 'country' in df.columns and 'region' in df.columns:
        df['region'] = df.apply(lambda row: regroup_region(row['country'], row['region']), axis=1)

    # Insert data using high-performance bulk insertion
    cursor = conn.cursor()
    cursor.execute("DELETE FROM investments") # Clear old data
    
    # Use to_sql for fast insertion
    df[expected_cols].to_sql('investments', conn, if_exists='append', index=False)
    
    conn.commit()
    conn.close()

def search_data(filters=None):
    if filters is None:
        filters = {}
        
    conn = sqlite3.connect(DB_NAME)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    query = "SELECT * FROM investments WHERE 1=1"
    params = []
    
    if filters.get("country"):
        query += " AND country LIKE ?"
        params.append(f"%{filters['country']}%")
        
    if filters.get("region"):
        query += " AND region LIKE ?"
        params.append(f"%{filters['region']}%")
        
    if filters.get("sector"):
        query += " AND sector LIKE ?"
        params.append(f"%{filters['sector']}%")
        
    if filters.get("year"):
        query += " AND year = ?"
        params.append(filters['year'])
        
    cursor.execute(query, params)
    rows = cursor.fetchall()
    conn.close()
    
    return [dict(row) for row in rows]

def get_unique_values(column):
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    cursor.execute(f"SELECT DISTINCT {column} FROM investments WHERE {column} IS NOT NULL ORDER BY {column}")
    rows = cursor.fetchall()
    conn.close()
    return [row[0] for row in rows]
