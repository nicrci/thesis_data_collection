library(tidyverse)
library(DBI)
library(RSQLite)

# 1. Load data
con <- dbConnect(SQLite(), "investments.db")
df <- dbReadTable(con, "investments") |> as_tibble()
dbDisconnect(con)

# 2. Top 10 Countries (Combined Activity)
print("--- Top 10 Destination Countries (Total Count) ---")
country_top <- df |>
  count(country, sort = TRUE) |>
  head(10)
print(country_top)

# 3. Top Regions (Combined Activity)
print("--- Activity by Region (Total Count) ---")
region_top <- df |>
  count(region, sort = TRUE)
print(region_top)

# 4. Breakdown of Top Regions: Why do they lead?
# We look at how many countries are in each region and their top contributor
print("--- Regional Composition (Countries per Region) ---")
region_composition <- df |>
  group_by(region) |>
  summarise(
    total_projects = n(),
    unique_countries = n_distinct(country),
    top_country = country[which.max(table(country))],
    top_country_count = max(table(country)),
    .groups = "drop"
  ) |>
  arrange(desc(total_projects))

print(region_composition)

# 5. Why USA vs North America?
print("--- North America Composition ---")
df |>
  filter(region == "North America") |>
  count(country, sort = TRUE) |>
  print()
