library(tidyverse)
library(DBI)
library(RSQLite)

# 1. Load the dataset
db_path <- "investments.db"
con <- dbConnect(SQLite(), db_path)
df <- dbReadTable(con, "investments") |> as_tibble()
dbDisconnect(con)

# 2. Filter for Construction and count by country
construction_freq <- df |>
  filter(type == "Construction") |>
  count(country, sort = TRUE) |>
  head(10)

print("--- Top 10 Countries by Number of Construction Projects ---")
print(construction_freq)
