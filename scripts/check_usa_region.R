library(DBI)
library(RSQLite)

con <- dbConnect(SQLite(), "investments.db")
res <- dbGetQuery(con, "SELECT DISTINCT country, region FROM investments WHERE region = 'USA'")
print("Rows where region is 'USA':")
print(res)

res_na <- dbGetQuery(con, "SELECT DISTINCT country, region FROM investments WHERE region = 'North America'")
print("Rows where region is 'North America':")
print(res_na)
dbDisconnect(con)
