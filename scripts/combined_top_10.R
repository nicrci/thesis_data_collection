library(tidyverse)
library(DBI)
library(RSQLite)

con <- dbConnect(SQLite(), "investments.db")
df <- dbReadTable(con, "investments")
dbDisconnect(con)

combined_top_10 <- df |>
  count(country, sort = TRUE) |>
  head(10)

print("--- Top 10 Countries: Investment & Construction Combined ---")
print(combined_top_10)
