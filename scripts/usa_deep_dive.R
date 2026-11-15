library(tidyverse)
library(DBI)
library(RSQLite)

con <- dbConnect(SQLite(), "investments.db")
df <- dbReadTable(con, "investments") |> as_tibble()
dbDisconnect(con)

usa_df <- df |> filter(country == "USA")

print("--- USA Activity by Type ---")
usa_df |> count(type) |> print()

print("--- USA Activity by Year (Top 10 Years) ---")
usa_df |> count(year, sort = TRUE) |> head(10) |> print()

print("--- USA Activity by Sector ---")
usa_df |> count(sector, sort = TRUE) |> print()

print("--- Sample of Large USA Investments ---")
usa_df |> 
  filter(type == "Investment") |> 
  arrange(desc(amount)) |> 
  select(year, investor, target, amount, sector) |> 
  head(10) |> 
  print()
