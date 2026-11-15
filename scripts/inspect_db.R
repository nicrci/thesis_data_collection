library(DBI)
library(RSQLite)

con <- dbConnect(SQLite(), "investments.db")
tables <- dbListTables(con)
print("Tables in database:")
print(tables)

if ("investments" %in% tables) {
  cols <- dbListFields(con, "investments")
  print("Columns in 'investments' table:")
  print(cols)
  
  df <- dbReadTable(con, "investments")
  print("First few rows:")
  print(head(df))
}

dbDisconnect(con)
