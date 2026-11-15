library(DBI)
library(RSQLite)

con <- dbConnect(SQLite(), "investments.db")
regions <- dbGetQuery(con, "SELECT DISTINCT region FROM investments")
print(regions)
dbDisconnect(con)
